import importlib.util
import io
import json
import subprocess
import tarfile
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

spec = importlib.util.spec_from_file_location(
    "deploy", Path(__file__).with_name("deploy-turbogadget-host.py")
)
deploy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(deploy)
REVISION = "a" * 40
OUTPUT = "/nix/store/" + "b" * 32 + "-darwin-system-test"


def archive(name="flake.nix"):
    result = io.BytesIO()
    with tarfile.open(fileobj=result, mode="w") as tree:
        item = tarfile.TarInfo(name)
        item.size = 2
        tree.addfile(item, io.BytesIO(b"{}"))
    return result.getvalue()


class DeploymentTests(unittest.TestCase):
    def test_exact_revision_argument(self):
        self.assertEqual(deploy.revision_argument([REVISION]), REVISION)
        for args in [
            [],
            [REVISION, "extra"],
            ["--help"],
            ["A" * 40],
            [REVISION + "\n"],
            [REVISION + ";id"],
            ["../main"],
        ]:
            with self.subTest(args=args), self.assertRaises(ValueError):
                deploy.revision_argument(args)

    def test_nonroot_rejected_before_work(self):
        with (
            patch.object(deploy.sys, "argv", ["deploy", REVISION]),
            patch.object(deploy.os, "geteuid", return_value=501),
            patch.object(deploy, "deploy") as perform,
        ):
            with self.assertRaises(ValueError):
                deploy.main()
            perform.assert_not_called()

    def test_commit_must_match_remote_main(self):
        with (
            tempfile.TemporaryDirectory() as temp,
            patch.object(deploy, "run", side_effect=[b"", b"", "c" * 40]) as run,
            patch.object(deploy.subprocess, "run") as privileged,
        ):
            with self.assertRaisesRegex(ValueError, "current GitHub main"):
                deploy.deploy(REVISION, Path(temp))
            self.assertEqual(run.call_count, 3)
            fetch = run.call_args_list[1].args[0]
            self.assertEqual(fetch[-2:], [deploy.REPOSITORY, "refs/heads/main"])
            privileged.assert_not_called()

    def test_unsafe_archive_rejected_before_build(self):
        with (
            tempfile.TemporaryDirectory() as temp,
            patch.object(
                deploy, "run", side_effect=[b"", b"", REVISION, archive("../escape")]
            ) as run,
            patch.object(deploy.subprocess, "run") as privileged,
        ):
            with self.assertRaises(tarfile.TarError):
                deploy.deploy(REVISION, Path(temp))
            self.assertEqual(run.call_count, 4)
            privileged.assert_not_called()

    def test_invalid_build_output_cannot_activate(self):
        for output in ["/tmp/fake-system", OUTPUT + "\n" + OUTPUT]:
            with (
                self.subTest(output=output),
                tempfile.TemporaryDirectory() as temp,
                patch.object(
                    deploy, "run", side_effect=[b"", b"", REVISION, archive(), output]
                ),
                patch.object(deploy.subprocess, "run") as privileged,
            ):
                with self.assertRaises(ValueError):
                    deploy.deploy(REVISION, Path(temp))
                privileged.assert_not_called()

    def test_switch_order_and_success_record(self):
        with tempfile.TemporaryDirectory() as temp:
            state = Path(temp) / "state"
            state.mkdir()
            with (
                patch.object(deploy, "STATE", state),
                patch.object(
                    deploy, "run", side_effect=[b"", b"", REVISION, archive(), OUTPUT]
                ) as run,
                patch.object(deploy.subprocess, "run") as privileged,
                patch.object(Path, "resolve", return_value=Path(OUTPUT)),
            ):
                deploy.deploy(REVISION, Path(temp))
                self.assertEqual(
                    run.call_args.args[0][: len(deploy.BUILDER)], deploy.BUILDER
                )
                self.assertEqual(
                    privileged.call_args_list[0].args[0],
                    [deploy.NIX_ENV, "--profile", deploy.PROFILE, "--set", OUTPUT],
                )
                self.assertEqual(
                    privileged.call_args_list[1].args[0], [OUTPUT + "/activate"]
                )
                self.assertEqual(
                    json.loads((state / "last-successful.json").read_text()),
                    {"revision": REVISION, "system": OUTPUT},
                )

    def test_activation_failure_is_not_reported_as_success(self):
        with (
            tempfile.TemporaryDirectory() as temp,
            patch.object(deploy, "STATE", Path(temp)),
            patch.object(
                deploy, "run", side_effect=[b"", b"", REVISION, archive(), OUTPUT]
            ),
            patch.object(
                deploy.subprocess,
                "run",
                side_effect=[None, subprocess.CalledProcessError(1, "activate")],
            ),
        ):
            with self.assertRaises(subprocess.CalledProcessError):
                deploy.deploy(REVISION, Path(temp))
            self.assertFalse((Path(temp) / "last-successful.json").exists())


if __name__ == "__main__":
    unittest.main()
