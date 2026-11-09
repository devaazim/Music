#!/usr/bin/env python3
"""Patch the generated Android project for background audio. Safe to re-run."""
import pathlib
import re
import sys

ROOT = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else pathlib.Path(".")
MANIFEST = ROOT / "android/app/src/main/AndroidManifest.xml"

PERMISSIONS = [
    "android.permission.INTERNET",
    "android.permission.WAKE_LOCK",
    "android.permission.FOREGROUND_SERVICE",
    "android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK",
]

SERVICE_BLOCK = """
        <service android:name="com.ryanheise.audioservice.AudioService"
            android:foregroundServiceType="mediaPlayback"
            android:exported="true">
            <intent-filter>
                <action android:name="android.media.browse.MediaBrowserService"/>
            </intent-filter>
        </service>
        <receiver android:name="com.ryanheise.audioservice.MediaButtonReceiver"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MEDIA_BUTTON"/>
            </intent-filter>
        </receiver>
"""


def patch_manifest() -> None:
    text = MANIFEST.read_text()

    missing = [p for p in PERMISSIONS if p not in text]
    if missing:
        perms = "".join(f'    <uses-permission android:name="{p}"/>\n' for p in missing)
        text = text.replace("<application", perms + "    <application", 1)

    if "com.ryanheise.audioservice.AudioService" not in text:
        text = text.replace("</application>", SERVICE_BLOCK + "    </application>", 1)

    MANIFEST.write_text(text)


def patch_main_activity() -> None:
    candidates = list((ROOT / "android/app/src/main").rglob("MainActivity.*"))
    if not candidates:
        sys.exit("MainActivity not found")
    path = candidates[0]
    src = path.read_text()
    package = re.search(r"^package\s+([\w.]+)", src, re.M)
    if not package:
        sys.exit("package line not found in MainActivity")
    path.write_text(
        f"package {package.group(1)}\n\n"
        "import com.ryanheise.audioservice.AudioServiceActivity\n\n"
        "class MainActivity : AudioServiceActivity()\n"
    )
    if path.suffix != ".kt":
        sys.exit("MainActivity is not Kotlin; adjust this script")


if __name__ == "__main__":
    patch_manifest()
    patch_main_activity()
    print("Android project patched.")
