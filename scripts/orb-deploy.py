"""Deploy clean, published main from the dotfiles project's Amp orb.

Requires TAILSCALE_CLIENT_ID, TAILSCALE_AUDIENCE and SHARCHY_DEPLOY_SSH_KEY.
Both hosts use an ephemeral tag:amp-dotfiles-deploy node and standard SSH.
Sharchy accepts a Git bundle as shardul and shares the local rebuild lock.
TurboGadget accepts only a revision as dotfiles-deploy and fetches main itself.
Bootstrap and host-side restrictions live in config/turbogadget-deploy.nix.
"""

import argparse
import os
import re
import shlex
import socket
import subprocess
import sys
import tempfile
from pathlib import Path


def output(*args):
    return subprocess.check_output(args, text=True).strip()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("host", choices=("sharchy", "turbogadget"))
    host = parser.parse_args().host
    os.chdir(output("git", "rev-parse", "--show-toplevel"))
    if output("git", "status", "--porcelain"):
        raise ValueError("Dotfiles working tree must be clean before deployment.")
    revision = output("git", "rev-parse", "HEAD")
    remote = output("git", "ls-remote", "origin", "refs/heads/main").split("\t")[0]
    if revision != remote:
        raise ValueError(
            "Dotfiles HEAD must be pushed to origin/main before deployment."
        )
    for name in ("TAILSCALE_CLIENT_ID", "TAILSCALE_AUDIENCE", "SHARCHY_DEPLOY_SSH_KEY"):
        if not os.environ.get(name):
            raise ValueError(f"Set {name}")

    with tempfile.TemporaryDirectory(prefix="orb-deploy-") as directory:
        key = Path(directory) / "key"
        with open(
            key, "w", opener=lambda path, flags: os.open(path, flags, 0o600)
        ) as stream:
            stream.write(os.environ.pop("SHARCHY_DEPLOY_SSH_KEY") + "\n")
        options = [
            "-i",
            str(key),
            "-o",
            "BatchMode=yes",
            "-o",
            "IdentitiesOnly=yes",
            "-o",
            "StrictHostKeyChecking=accept-new",
        ]
        user = "shardul" if host == "sharchy" else "dotfiles-deploy"
        ssh = ["ssh", *options, f"{user}@{host}"]
        remote_dir = ""
        joined = False
        try:
            bundle = Path(directory) / "dotfiles.bundle"
            if host == "sharchy":
                subprocess.run(
                    ["git", "bundle", "create", str(bundle), "HEAD"], check=True
                )
            token = output(
                "amp",
                "orb",
                "id-token",
                "--audience",
                os.environ["TAILSCALE_AUDIENCE"],
                "--subject-scope",
                "project",
            )
            orb = os.environ.get("AMP_THREAD_ID", socket.gethostname())[:40]
            subprocess.run(
                [
                    "sudo",
                    "tailscale",
                    "up",
                    f"--client-id={os.environ['TAILSCALE_CLIENT_ID']}?ephemeral=true&preauthorized=true",
                    f"--id-token={token}",
                    "--advertise-tags=tag:amp-dotfiles-deploy",
                    f"--hostname=amp-dotfiles-deploy-{orb}",
                ],
                check=True,
            )
            del token
            joined = True
            if host == "turbogadget":
                subprocess.run([*ssh, f"deploy {revision}"], check=True)
                return

            candidate = output(*ssh, "mktemp -d")
            if not re.fullmatch(r"/tmp/[\w.-]+", candidate, flags=re.ASCII):
                raise ValueError(f"Unexpected remote temporary directory: {candidate}")
            remote_dir = candidate
            subprocess.run(
                [
                    "scp",
                    *options,
                    str(bundle),
                    f"shardul@sharchy:{remote_dir}/dotfiles.bundle",
                ],
                check=True,
            )
            path = shlex.quote(remote_dir)
            commit = shlex.quote(revision)
            subprocess.run(
                [
                    *ssh,
                    (
                        f"git clone --quiet {path}/dotfiles.bundle {path}/repo && "
                        f'test "$(git -C {path}/repo rev-parse HEAD)" = {commit} && '
                        f"mkdir {path}/source && "
                        f"git -C {path}/repo archive HEAD | tar -x -C {path}/source && "
                        "sudo /run/current-system/sw/bin/flock /run/lock/sharchy-deploy.lock "
                        "/run/current-system/sw/bin/nixos-rebuild switch "
                        f"--flake path:{path}/source#sharchy"
                    ),
                ],
                check=True,
            )
        finally:
            if remote_dir:
                subprocess.run(
                    [*ssh, f"rm -rf -- {shlex.quote(remote_dir)}"],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    check=False,
                )
            if joined:
                subprocess.run(
                    ["sudo", "tailscale", "logout"],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    check=False,
                )


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError) as error:
        print(error, file=sys.stderr)
        sys.exit(1)
    except subprocess.CalledProcessError as error:
        # Commands can contain the federation token; never print their arguments.
        print(
            f"Deployment command failed with exit code {error.returncode}.",
            file=sys.stderr,
        )
        sys.exit(1)
