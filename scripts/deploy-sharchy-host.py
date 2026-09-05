"""Root entrypoint for current main only. Bootstrap: config/sharchy-deploy.nix.

The host fetches with shardul's gh login, then builds root-owned source through
the Nix daemon. Repository writers and existing admins remain trusted with root;
the SSH key cannot supply source, credentials, build outputs or Nix options.
The lock is shared with rebuild and sharchy-rebuild. Do not bypass it manually.
Failure may leave the system profile changed or activation partially applied.
Inspect before retrying; no automatic rollback. /var/lib/dotfiles-deploy holds
the root-only last-successful.json receipt, not a live-system health check.
"""

import fcntl
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
NIX = "@nix@"
NIX_ENV = "@nixEnv@"
PATH = "@path@"
REPOSITORY = "https://github.com/shardulbee/dotfiles.git"
STATE = Path("/var/lib/dotfiles-deploy")
PROFILE = "/nix/var/nix/profiles/system"


def run(arguments, **kwargs):
    return subprocess.run(
        arguments, check=True, stdout=subprocess.PIPE, **kwargs
    ).stdout


def deploy(revision, work):
    repository = work / "repo"
    source = work / "source"
    source.mkdir()
    credential = [
        "@runuser@",
        "-u",
        "shardul",
        "--",
        "@env@",
        "-i",
        "HOME=/home/shardul",
        "USER=shardul",
        "LOGNAME=shardul",
        f"PATH={PATH}",
        "SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt",
        "@gh@",
        "auth",
        "git-credential",
    ]
    git = [
        GIT,
        "-c",
        "credential.helper=",
        "-c",
        "credential.helper=!" + shlex.join(credential),
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
    if run(git + ["rev-parse", "FETCH_HEAD"], text=True).strip() != revision:
        raise ValueError(
            "Requested commit is not the current GitHub main; nothing activated"
        )
    archive = run(git + ["archive", "--format=tar", revision])
    with tarfile.open(fileobj=io.BytesIO(archive)) as tree:
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
    temporary = STATE / "last-successful.json.tmp"
    temporary.write_text(json.dumps({"revision": revision, "system": output}) + "\n")
    os.replace(temporary, STATE / "last-successful.json")
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
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_CONFIG_GLOBAL": "/dev/null",
            "GIT_TERMINAL_PROMPT": "0",
            "SSL_CERT_FILE": "/etc/ssl/certs/ca-certificates.crt",
            "NIX_SSL_CERT_FILE": "/etc/ssl/certs/ca-certificates.crt",
        }
    )
    os.chdir("/")
    STATE.mkdir(mode=0o700, exist_ok=True)
    with Path("/run/lock/sharchy-deploy.lock").open("a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise ValueError(
                "Another Sharchy rebuild or deployment is running"
            ) from None
        with tempfile.TemporaryDirectory(prefix="work-", dir=STATE) as directory:
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
