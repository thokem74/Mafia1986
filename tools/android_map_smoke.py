"""Back up/restore campaign files and capture map QA on the connected debug device."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

ADB = "/home/thokem/Android/Sdk/platform-tools/adb"
PACKAGE = "org.thokem.mafia1986"
BACKUP = Path("/tmp/mafia1986-map-device-backup")


def adb(*args, data=None):
    return subprocess.run([ADB, *args], input=data, capture_output=True, check=True).stdout


def campaign_files():
    return [name for name in adb("shell", "run-as", PACKAGE, "ls", "files").decode().split()
            if name.endswith((".json", ".cfg", ".bak", ".tmp"))]


def digest(data):
    return hashlib.sha256(data).hexdigest()


def backup():
    adb("shell", "am", "force-stop", PACKAGE)
    if (BACKUP / "manifest.json").exists():
        raise RuntimeError("Backup already exists; preserve it rather than overwriting it")
    BACKUP.mkdir(parents=True, exist_ok=True)
    manifest = {}
    for name in campaign_files():
        data = adb("exec-out", "run-as", PACKAGE, "cat", "files/" + name)
        (BACKUP / name).write_bytes(data)
        manifest[name] = digest(data)
    (BACKUP / "manifest.json").write_text(json.dumps(manifest, indent=2))
    print("Backed up", len(manifest), "campaign/settings files to", BACKUP)


def restore():
    adb("shell", "am", "force-stop", PACKAGE)
    manifest = json.loads((BACKUP / "manifest.json").read_text())
    for name in campaign_files():
        if name not in manifest:
            adb("shell", "run-as", PACKAGE, "rm", "files/" + name)
    for name, expected in manifest.items():
        data = (BACKUP / name).read_bytes()
        assert digest(data) == expected, "Backup was changed: " + name
        # Fixed validated names from the original file inventory; no shell interpolation of contents.
        assert name.replace("_", "").replace(".", "").isalnum()
        adb("shell", "run-as " + PACKAGE + " sh -c 'cat > files/" + name + "'", data=data)
    verify()


def verify():
    manifest = json.loads((BACKUP / "manifest.json").read_text())
    assert set(campaign_files()) == set(manifest), "Unexpected campaign files remain"
    for name, expected in manifest.items():
        assert digest(adb("exec-out", "run-as", PACKAGE, "cat", "files/" + name)) == expected, name
    print("Byte-verified", len(manifest), "original campaign/settings files")


def state():
    value = json.loads(adb("shell", "run-as", PACKAGE, "cat", "files/autosave.json"))["campaign"]
    print(json.dumps({key: value[key] for key in ["position", "steps", "month", "location"]}))
    if value["combat"]:
        fight = value["combat"]
        print(json.dumps({"active": fight["active"], "round": fight["round"], "mode": fight["mode"], "reason": fight["reason"], "units": len(fight["units"]), "first_position": [fight["units"][0]["x"], fight["units"][0]["y"]]}))


def capture(path):
    Path(path).write_bytes(adb("exec-out", "screencap", "-p"))
    print(path)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=["backup", "restore", "verify", "capture", "state"])
    parser.add_argument("path", nargs="?")
    parser.add_argument("--backup-directory", default=str(BACKUP))
    args = parser.parse_args()
    BACKUP = Path(args.backup_directory)
    if args.action == "capture":
        capture(args.path)
    else:
        globals()[args.action]()
