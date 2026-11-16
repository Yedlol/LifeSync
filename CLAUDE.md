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
- Notifications: flutter_local_notifications (later phase)
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
- Money formatted as "RM 1,234.50".
- Don't add packages outside the stack without asking.
- After each task, list files touched and how to test.
