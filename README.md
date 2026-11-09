# Tunely

A music streaming app for Android and iOS (Flutter). It streams full tracks from **Audius**, a legal, artist-uploaded catalog, and is built so the catalog source can be swapped for a licensed provider later.

## Features
- Trending tracks with genre filters
- Search (debounced)
- Player: background playback, lock-screen / notification controls, queue, shuffle, repeat, seek
- Mini player + full Now Playing screen
- Likes, playlists, recently played (stored on-device)

## Get an APK without installing anything (GitHub Actions)
1. Create a free GitHub repo and upload this whole folder (including the `.github` folder) to the `main` branch.
2. Open the repo's **Actions** tab, choose **Build APK**, and click **Run workflow**.
3. After a few minutes, open the finished run and download **tunely-apk** under Artifacts. Unzip it and install `app-release.apk` on your phone (allow installs from your browser/files app).

The workflow generates the Android project, applies the background-audio settings (`tool/patch_android.py`), and builds a release APK. It is signed with the debug key, which is fine for testing but not for Play Store upload; add your own signing key before publishing.

## Run it locally
1. Install Flutter: https://docs.flutter.dev/get-started/install
2. In this folder, generate the native projects (keeps `lib/` and `pubspec.yaml`):
   ```
   flutter create . --project-name tunely --org com.example
   flutter pub get
   ```
3. Apply the platform settings below (required for background audio).
4. `flutter run`

### Android (`android/app/src/main/AndroidManifest.xml`)
Add inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>
```
Inside `<application>`, set `android:usesCleartextTraffic="false"` and add:
```xml
<service android:name="com.ryanheise.audioservice.AudioService"
    android:foregroundServiceType="mediaPlayback"
    android:exported="true">
  <intent-filter><action android:name="android.media.browse.MediaBrowserService"/></intent-filter>
</service>
<receiver android:name="com.ryanheise.audioservice.MediaButtonReceiver" android:exported="true">
  <intent-filter><action android:name="android.intent.action.MEDIA_BUTTON"/></intent-filter>
</receiver>
```
Change `MainActivity` to extend `AudioServiceActivity`:
```kotlin
import com.ryanheise.audioservice.AudioServiceActivity
class MainActivity : AudioServiceActivity()
```
In `android/app/build.gradle`, set `minSdkVersion 21` (or higher).

### iOS (`ios/Runner/Info.plist`)
```xml
<key>UIBackgroundModes</key>
<array><string>audio</string></array>
```

## Before you ship
- Confirm the Audius base URL / app name / API-key rules in `lib/config.dart` against https://docs.audius.org, and follow their terms (attribution, rate limits).
- Rename the app and replace the notification channel id in `lib/main.dart`.
- Catalog limits: Audius is independent artists, so it will NOT have major-label hits or all new releases. To get those, implement `CatalogProvider` for a licensed music provider (see `lib/catalog/catalog_provider.dart`) and swap it in `lib/main.dart`.

## Structure
```
lib/
  main.dart                 app + providers + background audio init
  config.dart               app name, API settings
  catalog/                  CatalogProvider interface + Audius implementation
  models/track.dart
  player/player_controller.dart
  library/library_store.dart
  screens/                  shell, home, search, library, mini + full player
  widgets/track_tile.dart
```
