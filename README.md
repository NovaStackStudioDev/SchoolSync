# SchoolSync

Flutter school management app with a green/yellow interface based on the supplied showcase. All operational records come from Supabase. Empty tables show empty states; failed reads and writes show errors and retry controls. No sample data is seeded or used as a fallback.

## Fix an existing installation / sign-in error

`PGRST202: Could not find public.provision_teacher` means Auth accepted the credentials but the registration database function is missing. Existing profiles now load without that function. To repair accounts that have no profile or teacher record, run **`supabase/repair_sign_in.sql`** in the SQL Editor of the same Supabase project as `.env`, then retry sign-in. Do not register the email again. The repair preserves existing roles and activation status; newly registered teachers still need principal activation.

For the new upload and replacement features, run the complete **`supabase/schema_and_policies.sql`** instead: it includes the sign-in repair, private timetable file bucket/policies and all new RPCs. The script requests a [PostgREST schema-cache reload](https://supabase.com/kb/troubleshooting/refresh-postgrest-schema) after installing functions. Do not run the files in `supabase/tests/` against your real project.

Editing `.env.example` does not configure the running app; update `.env` and restart/rebuild. Database changes require SQL Editor/admin access; a client publishable key cannot install SQL functions.

## Timetable files, revisions and replacements

1. Open **Timetable → folder icon → Upload Photo / PDF**. Files up to 10 MB are stored in a private bucket and can be viewed/zoomed in the app. Teachers can upload their own files; principals can upload for any active teacher.
2. Confirm the periods from the document with weekday, class, subject and period. Photo/PDF files are source references, not automatic OCR: an attachment alone never creates timetable periods or free-period eligibility. Save the source as a draft or submit the confirmed periods for principal review.
3. The principal opens the submission and **publishes** its periods. Choose **This date only** for a one-day change or switch it off to replace that teacher's weekly timetable from the effective date, including later planned revisions. Previous dates stay intact. Individual timetable entries can also be edited or removed for one date. A source file can be replaced with a revised Photo/PDF.
4. Mark teacher attendance as present/late or absent/leave. Unmarked attendance remains unknown and is not treated as confirmed absence.
5. Open **Automatic Replacement** for the date. **Automatically Assign Available Teachers** covers each absent teacher's scheduled periods using present, active, free teachers, preferring subject matches and lower cover workloads. If no teacher qualifies, the period remains uncovered and the result reports it. Tap a period to choose an eligible teacher manually.
6. **Cancel / Reassign** releases a cover assignment and notifies the teacher. Cancel affected covers before changing their timetable periods. The server rechecks eligibility and conflicts on every assignment; running auto-assign again does not duplicate existing covers.

## Run

1. Copy `.env.example` to `.env`, then set your project's URL and **publishable** key from Supabase Project Settings → API Keys. The legacy `SUPABASE_ANON_KEY` variable is also accepted. Never put a service-role/secret key in the Flutter app.
2. Run `supabase/schema_and_policies.sql` in your project's SQL editor. It creates missing tables, installs transactional actions, and replaces the old application RLS policies with school/role-scoped policies. Existing records are preserved. Old notifications without a recipient remain stored but are not shown to staff.
3. Deploy the teacher creation function using your authenticated Supabase CLI:

   ```sh
   supabase functions deploy manage-teacher --project-ref YOUR_PROJECT_REF
   ```

   The function uses Supabase's server-provided service-role environment variable, verifies the caller's access token, checks their active principal profile, and creates an Auth account plus school records. No admin credentials are bundled in the client.
4. Create the first principal Auth user in Supabase Authentication → Users. Link that real user's UUID to a `profiles` row in the configured school with `role = 'principal'` and `is_active = true`. Principal privileges cannot be selected through registration. For example, replace the email below with your actual principal's email before running:

   ```sql
   insert into public.profiles(id, school_id, full_name, role, is_active)
   select u.id, s.id, 'Your principal’s real name', 'principal', true
   from auth.users u cross join public.schools s
   where u.email = 'YOUR_PRINCIPAL_EMAIL'
     and s.name = 'Kahatagasdigiliya Central College'
   on conflict(id) do update set role = 'principal', is_active = true;
   ```
5. Configure Auth email delivery, Site URL and redirect allowlist for your deployed web origin. For mobile recovery/confirmation, also allow `lk.schoolsync://auth`. The app selects the web origin or mobile callback automatically; Android/iOS URL handlers are included.
6. Run `flutter pub get`, then `flutter run` or `flutter build apk --release`.

The existing `.env` returned **401 Unauthorized** during the read-only connection check. Replace its key with a valid key for the matching project before live use. The remote database migration and Edge Function deployment have not been executed from this workspace.

## Available workflows

- Principal and teacher sign-in, teacher registration, password reset and profile/password editing.
- Teacher search, account creation, subject/contact editing, and activation/deactivation. Self-registered accounts need principal activation.
- Classes and students: add, search and edit; assigned teachers can view their own students and take class attendance. Long-press a class as principal to rename it.
- Teacher check-in, principal attendance overrides, saved student attendance by class/date. Unmarked records remain unmarked. Check-in uses server time and the school's configured attendance cutoff; late arrival is recorded as late.
- Leave requests, history, overlap prevention, approval/rejection and private notifications. Approval updates attendance for working days in one transaction.
- Timetable entries, school periods and subjects. The server rejects overlapping teacher/class periods.
- Replacement suggestions ranked by subject suitability and cover workload. Only active, present, free teachers qualify. The server rechecks availability and records the assignment/notification together.
- School calendar events and working-day overrides. Weekends are the default closed days unless explicitly overridden; holidays are never guessed.
- Recipient-specific notifications, read status and school announcements.
- Monthly attendance/leave/cover reports and a copyable summary. Attendance rate uses saved records only and shows `—` without records. Class performance is not invented because no assessment data exists.
- Existing Sinhala/English authentication and navigation labels are retained; new management forms currently use English.

## Verification

```sh
flutter analyze --no-pub
flutter test --no-pub
flutter build web --release --no-pub
```

For UI preview PNGs in `build/previews/`, run `flutter test --dart-define=CAPTURE_PREVIEWS=true` on Windows with the Nirmala UI font available.

Database regression tests require a **disposable** PostgreSQL database, not the production Supabase project. Run these in order with `psql -v ON_ERROR_STOP=1`: `supabase/tests/bootstrap.sql`, `supabase/schema_and_policies.sql`, `supabase/tests/workflows.sql`. The bootstrap creates local auth roles; workflow fixtures are isolated in a transaction and rolled back. Tests cover tenant isolation, principal permissions, timetable overlap, class attendance, leave review, replacement eligibility and notification privacy.

Update verification passed 12 Flutter tests, static analysis, a web release build and both PostgreSQL workflow suites. `supabase/tests/timetable_workflows.sql` covers auto-assignment, daily/weekly revisions, teacher submission, atomic publishing and private file access. For local storage policy tests, run `storage_stub.sql` before the application schema. The previous Android APK attempt could not finish because the SDK manager stalled downloading Android NDK `28.2.13676358`; no APK is claimed. After installing that dependency, rerun `flutter build apk --release`.

Server function authorization follows the [Supabase Edge Function authentication guidance](https://supabase.com/docs/guides/functions/auth-legacy-jwt); account creation uses the [Auth admin createUser API](https://supabase.com/docs/reference/javascript/auth-admin-createuser).
