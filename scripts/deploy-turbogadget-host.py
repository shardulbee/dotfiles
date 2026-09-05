"""Root entrypoint: deploy only the requested current GitHub main revision.

Fetch uses shardul's gh login (must retain repository access); build runs as
shardul against root-owned source. Publishing main therefore grants root code
execution on activation: this restricts the SSH key, not repository authors.
Orb runs serialize; do not rebuild manually alongside them. Activation failure
can leave the profile changed without switching /run/current-system. No automatic
rollback: inspect the error before retrying. Root-only last-successful.json in
/var/db/dotfiles-deploy records completed activation, not merely a build.
"""

import fcntl
import grp
import io
import json
import os
import re
import shlex
import subprocess
import sys
import tarfile
import tempfile
from pathlib import Path

GIT = "@git@"
GH = "@gh@"
NIX = "@nix@"
NIX_ENV = "@nixEnv@"
PATH = "@path@"
REPOSITORY = "https://github.com/shardulbee/dotfiles.git"
PROFILE = "/nix/var/nix/profiles/system"
STATE = Path("/var/db/dotfiles-deploy")
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
    repository = work / "repo"
    source = work / "source"
    source.mkdir(mode=0o755)
    # Caller-controlled Git configuration and submitted Git bundles are not
    # trusted. Use the owner's GitHub login without exposing it to the deploy user.
    git = [
        GIT,
        "-c",
        "credential.helper=",
        "-c",
        "credential.helper=!" + shlex.join(BUILDER + [GH, "auth", "git-credential"]),
        "-c",
        "core.hooksPath=/dev/null",
        "-c",
        "protocol.file.allow=never",
    ]
    run(git + ["init", "--bare", str(repository)])
    git += ["--git-dir", str(repository)]
    run(
        git
        + ["fetch", "--quiet", "--no-tags", "--depth=1", REPOSITORY, "refs/heads/main"]
    )
    actual = run(git + ["rev-parse", "FETCH_HEAD"], text=True).strip()
    if actual != revision:
        raise ValueError(
            "Requested commit is not the current GitHub main; nothing activated"
        )
    archive = run(git + ["archive", "--format=tar", revision])
    with tarfile.open(fileobj=io.BytesIO(archive)) as tree:
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
    temporary = STATE / "last-successful.json.tmp"
    temporary.write_text(json.dumps({"revision": revision, "system": output}) + "\n")
    os.replace(temporary, STATE / "last-successful.json")
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
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_CONFIG_GLOBAL": "/dev/null",
            "GIT_TERMINAL_PROMPT": "0",
            "SSL_CERT_FILE": "/etc/ssl/cert.pem",
            "NIX_SSL_CERT_FILE": "/etc/ssl/cert.pem",
        }
    )
    STATE.mkdir(mode=0o700, exist_ok=True)
    with (STATE / "lock").open("a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise ValueError("Another orb deployment is running") from None
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
