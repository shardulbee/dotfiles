"""Deploy clean, published main from the dotfiles project's Amp orb.

Requires TAILSCALE_CLIENT_ID, TAILSCALE_AUDIENCE and SHARCHY_DEPLOY_SSH_KEY.
Both hosts use an ephemeral tag:amp-dotfiles-deploy node and standard SSH.
Both accept only a revision as dotfiles-deploy and fetch main themselves.
Bootstrap and restrictions: config/{sharchy,turbogadget}-deploy.nix.
"""

import argparse
import os
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
        ssh = ["ssh", *options, f"dotfiles-deploy@{host}"]
        joined = False
        try:
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
            subprocess.run([*ssh, f"deploy {revision}"], check=True)
        finally:
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
