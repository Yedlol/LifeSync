# LifeSync

Personal tasks (kanban) and finance app. Flutter + Supabase. See [CLAUDE.md](CLAUDE.md).

## Run

Keys are never hardcoded; pass them with `--dart-define`:

```
flutter run -d windows --dart-define=SUPABASE_URL=https://YOUR_REF.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Android phone (USB debugging on, find the id with `flutter devices`):

```
flutter run -d DEVICE_ID --dart-define=SUPABASE_URL=https://YOUR_REF.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

In VS Code, edit the placeholders in `.vscode/launch.json` and press F5.
Don't commit real values (the file is git-ignored).

Windows builds need Developer Mode enabled (`start ms-settings:developers`) for plugin symlinks.
