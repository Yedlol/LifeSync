# LifeSync
Personal app for daily tasks (kanban board) and personal finance (bills, savings,
salary/overtime). Single user. Syncs between Android phone and Windows PC.

## Stack
- Flutter (android, windows, web)
- Supabase: Postgres, Auth (email), Storage (bucket: task-images), Realtime
- State: flutter_riverpod (Notifier/AsyncNotifier, no code generation)
- Routing: go_router
- Rich text: flutter_quill + flutter_quill_extensions
- Images: image_picker (gallery/camera/file dialog), uuid (client-side ids / file names)
- UI polish: flex_color_scheme (theme, light + dark), google_fonts (Inter),
  phosphor_flutter (icons — no Material Icons), flutter_animate (motion < 300ms,
  `fadeSlideIn()` in core/widgets/motion.dart; never on drag cards),
  flutter_slidable (phone swipe actions via core/widgets/swipe_actions.dart),
  skeletonizer (loading placeholders instead of spinners), fl_chart (charts)
- Shared UI helpers: core/widgets/empty_state.dart (every list needs one),
  core/widgets/skeletons.dart, core/utils/haptics.dart (phone only),
  Sp spacing scale (4/8/12/16/24) + kRadius 12 in core/theme/app_theme.dart
- Reminders: flutter_local_notifications + timezone (Asia/Kuala_Lumpur) on Android and
  Windows (no-op on web); shared_preferences for per-device reminder settings.
  Code in core/notifications/ (planner is pure + tested; NotificationService is the
  only thing that touches the plugin). Android uses inexact scheduling.
- Offline-first: hive_ce + hive_ce_flutter (cache, records stored as JSON maps,
  NO code generation / type adapters), connectivity_plus (online status),
  path_provider (Hive lives in app-support dir, never OneDrive Documents).
  Code in core/offline/. Web shares the same cache (IndexedDB) but can't cold-start offline.
- Currency RM (MYR), timezone Asia/Kuala_Lumpur

## Database (already created in Supabase — do NOT write SQL unless asked)
Tables: user_settings, projects, tasks, task_images, bills, bill_payments,
savings_goals, saving_entries, income_entries.
Views: bills_this_month, savings_progress.
Every table has user_id with RLS (user_id = auth.uid()); user_id defaults to auth.uid().
user_settings also holds salary/OT config: basic_salary, ot_hourly_rate,
ot_rate_normal (1.5), ot_rate_rest_day (2.0), ot_rate_holiday (3.0),
normal_hours_per_day (8), pay_day (nullable, 1–31).
income_entries: type (salary|overtime|allowance|bonus|other), amount, entry_date,
hours, day_type, rate_multiplier, note (overtime amount = hours × OT rate × multiplier).
Enums: task_status (open, in_progress, on_hold, done),
task_priority (low, medium, high, urgent).

## Structure (feature-first)
lib/
  core/       theme, router, supabase client, shared widgets, utils
  features/
    auth/
    dashboard/
    tasks/      data/ models/ providers/ ui/
    projects/   data/ models/ providers/ ui/
    finance/    bills/ savings/ income/
    settings/

## Rules
- Responsive: phone layout < 700px wide, desktop >= 700px.
- Theme: Material 3, clean blue and white, primary #1E6FD9.
- Files under ~300 lines; extract reused widgets.
- All Supabase calls go through repository classes; UI never calls Supabase directly.
- Offline rules (core/offline/):
  - Providers read ONLY from the cache (LocalStore, one Hive box per table).
    LiveListNotifier: Supabase realtime stream -> LocalStore.applySnapshot -> UI.
  - Every write goes through OfflineWriter (cache first, then an outbox op);
    never await the server in a write path. Ids are client UUIDs (clientId()).
  - Upsert payloads are the full writable row (model.toJson()), never a partial
    patch. Partial changes read the cached row, copyWith, then upsert.
  - bill_payments upsert onConflict 'bill_id,period'; user_settings onConflict
    'user_id'; child rows are deleted before parents (match deletes).
  - Storage deletes are queued as storage_remove ops; uploads need internet
    (UI disables image insert offline via isOnlineProvider).
  - SyncService replays the outbox in order (network error = stop + backoff,
    server rejection = failed list), then re-fetches all tables. Last write wins.
  - Logout clears all boxes (AuthRepository.signOut).
- Money formatted as "RM 1,234.50".
- Don't add packages outside the stack without asking.
- After each task, list files touched and how to test.
