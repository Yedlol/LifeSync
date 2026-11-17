# LifeSync

Personal tasks (kanban) and finance app. Flutter + Supabase. See [CLAUDE.md](CLAUDE.md).

## Keys (env.json)

Keys are never hardcoded. Copy `env.example.json` to `env.json` (git-ignored) and
fill in your Supabase URL and anon key:

```json
{
  "SUPABASE_URL": "https://YOUR_REF.supabase.co",
  "SUPABASE_ANON_KEY": "YOUR_ANON_KEY"
}
```

## Run

```
flutter run -d windows --dart-define-from-file=env.json
flutter run -d DEVICE_ID --dart-define-from-file=env.json   # Android (see `flutter devices`)
```

In VS Code just press F5: `.vscode/launch.json` already uses `env.json`.

Windows builds need Developer Mode enabled (`start ms-settings:developers`) for plugin symlinks.

## Release builds

One-time setup:

1. Create `env.json` (above).
2. Android only: create the signing key and `android/key.properties`
   (git-ignored; see the keytool command in the Phase 4D notes):
   ```
   storePassword=YOUR_PASSWORD
   keyPassword=YOUR_PASSWORD
   keyAlias=lifesync
   storeFile=C:/keys/lifesync-release.jks
   ```
   Back up `C:\keys\lifesync-release.jks` and its password. Without the same key
   you can't install an update over an existing install.
3. Windows only: install [Inno Setup 6](https://jrsoftware.org/isdl.php) (default location).

Build (from anywhere):

```
scripts\build_android.bat    ->  dist\LifeSync-<version>.apk
scripts\build_windows.bat    ->  dist\LifeSync-Setup-<version>.exe
```

## How to release an update

1. Bump `version:` in `pubspec.yaml`, e.g. `1.0.1+2`. The part before `+` is the
   name shown to you; the number after `+` is the Android build number and
   **must go up every release** or Android refuses to update.
2. Run the build script(s) again. File names pick up the new version.
3. Reinstall over the old one (data is kept):
   - Phone: copy the new APK over and open it, tap **Update**.
   - PC: run the new `LifeSync-Setup-<version>.exe`. It replaces the old files.
