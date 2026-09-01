#!/usr/bin/env python3
import fcntl
import hashlib
import json
import os
import struct
import subprocess
import sys
import tempfile
import time
from pathlib import Path


STATE_DIR = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "sharchy-clipboard"
HISTORY_PATH = STATE_DIR / "history.json"
CONTENT_DIR = STATE_DIR / "content"
LOCK_PATH = STATE_DIR / "history.lock"
MAX_ENTRIES = 500
MAX_BYTES = 5 * 1024 * 1024


def initialize():
    STATE_DIR.mkdir(mode=0o700, parents=True, exist_ok=True)
    CONTENT_DIR.mkdir(mode=0o700, exist_ok=True)
    if not HISTORY_PATH.exists():
        save_history([])


def load_history():
    initialize()
    try:
        value = json.loads(HISTORY_PATH.read_text())
        return value if isinstance(value, list) else []
    except (OSError, json.JSONDecodeError):
        return []


def save_history(history):
    STATE_DIR.mkdir(mode=0o700, parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", dir=STATE_DIR, delete=False) as output:
        json.dump(history, output, ensure_ascii=False, separators=(",", ":"))
        output.write("\n")
        temporary_path = Path(output.name)
    temporary_path.chmod(0o600)
    temporary_path.replace(HISTORY_PATH)


def locked_history():
    initialize()
    lock_file = LOCK_PATH.open("a+")
    LOCK_PATH.chmod(0o600)
    fcntl.flock(lock_file, fcntl.LOCK_EX)
    return lock_file, load_history()


def format_size(size):
    if size < 1024:
        return f"{size} B"
    if size < 1024 * 1024:
        return f"{size / 1024:.0f} KiB"
    return f"{size / (1024 * 1024):.1f} MiB"


def png_dimensions(data):
    if len(data) >= 24 and data.startswith(b"\x89PNG\r\n\x1a\n"):
        return struct.unpack(">II", data[16:24])
    return None


def gif_dimensions(data):
    if len(data) >= 10 and data[:6] in (b"GIF87a", b"GIF89a"):
        return struct.unpack("<HH", data[6:10])
    return None


def jpeg_dimensions(data):
    if not data.startswith(b"\xff\xd8"):
        return None
    offset = 2
    while offset + 9 < len(data):
        if data[offset] != 0xFF:
            offset += 1
            continue
        marker = data[offset + 1]
        offset += 2
        if marker in (0xD8, 0xD9):
            continue
        if offset + 2 > len(data):
            break
        length = int.from_bytes(data[offset:offset + 2], "big")
        if length < 2 or offset + length > len(data):
            break
        if marker in range(0xC0, 0xC4):
            return (
                int.from_bytes(data[offset + 5:offset + 7], "big"),
                int.from_bytes(data[offset + 3:offset + 5], "big"),
            )
        offset += length
    return None


def image_details(data):
    dimensions = png_dimensions(data)
    if dimensions:
        return "image/png", "png", dimensions
    dimensions = jpeg_dimensions(data)
    if dimensions:
        return "image/jpeg", "jpg", dimensions
    dimensions = gif_dimensions(data)
    if dimensions:
        return "image/gif", "gif", dimensions
    if len(data) >= 12 and data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        return "image/webp", "webp", None
    if data.startswith(b"BM"):
        return "image/bmp", "bmp", None
    stripped = data.lstrip()
    if stripped.startswith(b"<svg") or (stripped.startswith(b"<?xml") and b"<svg" in stripped[:1024]):
        return "image/svg+xml", "svg", None
    return None


def text_value(data):
    try:
        value = data.decode("utf-8")
    except UnicodeDecodeError:
        return None
    if "\x00" in value:
        return None
    if value:
        printable = sum(character.isprintable() or character in "\n\r\t" for character in value)
        if printable / len(value) < 0.85:
            return None
    return value


def text_summary(value):
    collapsed = " ".join(value.split())
    if not collapsed:
        return "Empty text"
    return collapsed[:160]


def classify(data, digest, captured_at):
    image = image_details(data)
    if image:
        mime, extension, dimensions = image
        path = CONTENT_DIR / f"{digest}.{extension}"
        path.write_bytes(data)
        path.chmod(0o600)
        dimension_text = f" · {dimensions[0]}×{dimensions[1]}" if dimensions else ""
        return {
            "id": digest,
            "type": "image",
            "mime": mime,
            "summary": f"Image · {format_size(len(data))}{dimension_text}",
            "path": str(path),
            "size": len(data),
            "capturedAt": captured_at,
        }

    text = text_value(data)
    if text is not None:
        return {
            "id": digest,
            "type": "text",
            "mime": "text/plain;charset=utf-8",
            "summary": text_summary(text),
            "text": text,
            "size": len(data),
            "capturedAt": captured_at,
        }

    mime = "application/pdf" if data.startswith(b"%PDF-") else "application/octet-stream"
    extension = "pdf" if mime == "application/pdf" else "bin"
    path = CONTENT_DIR / f"{digest}.{extension}"
    path.write_bytes(data)
    path.chmod(0o600)
    kind = "PDF" if mime == "application/pdf" else "Data"
    return {
        "id": digest,
        "type": "binary",
        "mime": mime,
        "summary": f"{kind} · {format_size(len(data))}",
        "path": str(path),
        "size": len(data),
        "capturedAt": captured_at,
    }


def clean_content(history):
    retained = {entry.get("path") for entry in history if entry.get("path")}
    for path in CONTENT_DIR.iterdir():
        if str(path) not in retained:
            path.unlink(missing_ok=True)


def capture():
    data = sys.stdin.buffer.read(MAX_BYTES + 1)
    if os.environ.get("CLIPBOARD_STATE", "data") != "data" or not data or len(data) > MAX_BYTES:
        return
    digest = hashlib.sha256(data).hexdigest()
    lock_file, history = locked_history()
    try:
        entry = classify(data, digest, int(time.time() * 1000))
        history = [existing for existing in history if existing.get("id") != digest]
        history.insert(0, entry)
        history = history[:MAX_ENTRIES]
        save_history(history)
        clean_content(history)
    finally:
        lock_file.close()


def find_entry(entry_id):
    lock_file, history = locked_history()
    try:
        return next((entry for entry in history if entry.get("id") == entry_id), None)
    finally:
        lock_file.close()


def entry_data(entry):
    if entry.get("type") == "text":
        return entry.get("text", "").encode("utf-8")
    path = entry.get("path")
    return Path(path).read_bytes() if path else b""


def copy_entry(entry_id, paste):
    entry = find_entry(entry_id)
    if not entry:
        raise SystemExit(f"clipboard entry not found: {entry_id}")
    subprocess.run(
        ["wl-copy", "--type", entry.get("mime", "application/octet-stream")],
        input=entry_data(entry),
        check=True,
    )
    if paste:
        time.sleep(0.15)
        subprocess.run(
            ["wtype", "-M", "shift", "-k", "Insert", "-m", "shift"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )


def delete_entry(entry_id):
    lock_file, history = locked_history()
    try:
        history = [entry for entry in history if entry.get("id") != entry_id]
        save_history(history)
        clean_content(history)
    finally:
        lock_file.close()


def main():
    command = sys.argv[1] if len(sys.argv) > 1 else ""
    if command == "init":
        initialize()
    elif command == "capture":
        capture()
    elif command in ("copy", "paste") and len(sys.argv) == 3:
        copy_entry(sys.argv[2], command == "paste")
    elif command == "delete" and len(sys.argv) == 3:
        delete_entry(sys.argv[2])
    else:
        raise SystemExit("usage: sharchy-clipboard-backend {init|capture|copy ID|paste ID|delete ID}")


if __name__ == "__main__":
    main()
