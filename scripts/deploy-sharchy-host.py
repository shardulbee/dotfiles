"""Build and activate the source tar streamed by Actions on stdin.

The deployment key authorizes root code execution through supplied Nix source.
Actions serializes deployments; do not rebuild locally alongside it.
Activation can partially fail; inspect before retrying, no automatic rollback.
"""

import os
import re
import subprocess
import sys
import tarfile
import tempfile
from pathlib import Path

NIX = "@nix@"
NIX_ENV = "@nixEnv@"
PATH = "@path@"
PROFILE = "/nix/var/nix/profiles/system"


def run(arguments, **kwargs):
    return subprocess.run(
        arguments, check=True, stdout=subprocess.PIPE, **kwargs
    ).stdout


def deploy(revision, work):
    source = work / "source"
    source.mkdir()
    with tarfile.open(fileobj=sys.stdin.buffer, mode="r|*") as tree:
        tree.extractall(source, filter="data")
    # Keep a GC root until the system profile takes ownership of the result.
    output = run(
        [
            NIX,
            "--extra-experimental-features",
            "nix-command flakes",
            "build",
            "--out-link",
            str(work / "result"),
            "--print-out-paths",
            "--option",
            "accept-flake-config",
            "false",
            "--no-write-lock-file",
            f"path:{source}#nixosConfigurations.sharchy.config.system.build.toplevel",
        ],
        text=True,
    ).strip()
    if not re.fullmatch(
        r"/nix/store/[0-9a-z]{32}-nixos-system-sharchy-[^/\s]+", output
    ):
        raise ValueError("Build did not return one Sharchy NixOS system store path")
    subprocess.run([NIX_ENV, "--profile", PROFILE, "--set", output], check=True)
    subprocess.run([output + "/bin/switch-to-configuration", "switch"], check=True)
    if Path("/run/current-system").resolve() != Path(output):
        raise ValueError("Activation did not select the built system")
    print(f"Activated {revision}: {output}", flush=True)


def main():
    if len(sys.argv) != 2 or not re.fullmatch(r"[0-9a-f]{40}", sys.argv[1]):
        raise ValueError("Expected exactly one lowercase 40-character commit ID")
    if os.geteuid() != 0:
        raise ValueError("This entrypoint must run through the restricted sudo rule")
    os.umask(0o077)
    os.environ.clear()
    os.environ.update(
        {
            "HOME": "/root",
            "USER": "root",
            "LOGNAME": "root",
            "PATH": PATH,
            "SSL_CERT_FILE": "/etc/ssl/certs/ca-certificates.crt",
            "NIX_SSL_CERT_FILE": "/etc/ssl/certs/ca-certificates.crt",
        }
    )
    os.chdir("/")
    with tempfile.TemporaryDirectory(prefix="dotfiles-deploy-") as directory:
        deploy(sys.argv[1], Path(directory))


if __name__ == "__main__":
    try:
        main()
    except (
        ValueError,
        OSError,
        subprocess.CalledProcessError,
        tarfile.TarError,
    ) as error:
        print(f"Deployment failed: {error}", file=sys.stderr)
        sys.exit(1)
