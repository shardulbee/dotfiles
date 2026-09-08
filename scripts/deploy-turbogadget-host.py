"""Build and activate the source tar streamed by Actions on stdin.

The deployment key authorizes root code execution through supplied Nix source.
Actions serializes deployments; do not rebuild locally alongside it.
Activation can partially fail; inspect before retrying, no automatic rollback.
"""

import grp
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
BUILDER = [
    "/usr/bin/sudo",
    "-n",
    "-H",
    "-u",
    "shardul",
    "/usr/bin/env",
    "-i",
    "HOME=/Users/shardul",
    "USER=shardul",
    "LOGNAME=shardul",
    f"PATH={PATH}",
    "SSL_CERT_FILE=/etc/ssl/cert.pem",
    "NIX_SSL_CERT_FILE=/etc/ssl/cert.pem",
]


def revision_argument(arguments):
    if len(arguments) != 1 or not re.fullmatch(r"[0-9a-f]{40}", arguments[0]):
        raise ValueError("Expected exactly one lowercase 40-character commit ID")
    return arguments[0]


def run(arguments, **kwargs):
    return subprocess.run(
        arguments, check=True, stdout=subprocess.PIPE, **kwargs
    ).stdout


def deploy(revision, work):
    source = work / "source"
    source.mkdir(mode=0o755)
    with tarfile.open(fileobj=sys.stdin.buffer, mode="r|*") as tree:
        tree.extractall(source, filter="data")
    # Parent is root:staff 0750; source stays root-owned and not writable by
    # shardul. The deployment account is not a member of staff.
    output = run(
        BUILDER
        + [
            NIX,
            "--extra-experimental-features",
            "nix-command flakes",
            "build",
            "--no-link",
            "--print-out-paths",
            "--option",
            "accept-flake-config",
            "false",
            "--no-write-lock-file",
            f"path:{source}#darwinConfigurations.macbook.system",
        ],
        text=True,
    ).strip()
    if not re.fullmatch(r"/nix/store/[0-9a-z]{32}-darwin-system-[^/\s]+", output):
        raise ValueError("Build did not return one Darwin system store path")
    legacy = Path(output) / "activate-user"
    if legacy.exists() and "# nix-darwin: deprecated" not in legacy.read_text():
        raise ValueError("Legacy user activation is not supported; nothing activated")
    # Match darwin-rebuild switch: update the profile, then activate as root.
    # Activation can partially fail; do not silently roll back or claim success.
    subprocess.run([NIX_ENV, "--profile", PROFILE, "--set", output], check=True)
    subprocess.run([output + "/activate"], check=True)
    if Path("/run/current-system").resolve() != Path(output):
        raise ValueError("Activation did not select the built system")
    print(f"Activated {revision}: {output}", flush=True)


def main():
    revision = revision_argument(sys.argv[1:])
    if os.geteuid() != 0:
        raise ValueError("This entrypoint must run through the restricted sudo rule")
    os.umask(0o022)
    os.environ.clear()
    os.environ.update(
        {
            "HOME": "/var/root",
            "USER": "root",
            "LOGNAME": "root",
            "PATH": PATH,
            "SSL_CERT_FILE": "/etc/ssl/cert.pem",
            "NIX_SSL_CERT_FILE": "/etc/ssl/cert.pem",
        }
    )
    with tempfile.TemporaryDirectory(
        prefix="dotfiles-deploy-", dir="/var/tmp"
    ) as directory:
        # macOS /var is a symlink; Nix path flakes require the physical path.
        work = Path(directory).resolve()
        os.chown(work, 0, grp.getgrnam("staff").gr_gid)
        work.chmod(0o750)
        deploy(revision, work)


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
