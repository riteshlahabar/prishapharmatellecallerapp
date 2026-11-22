# Prisha Pharma — Telecaller app

The telecaller's working day: a region-scoped queue of people to ring, the
outcome of each call, the call-backs they promised, and a line to the medical
rep who should follow up in person.

Flutter · Riverpod · go_router · Dio. Backend contract lives in the CRM repo
under `docs/api/` — **`v1-common.md` first**, then `v1-telecaller.md`.

## Run it

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

`10.0.2.2` is the host machine from the Android emulator, and is the default,
so a local CRM on `php artisan serve` works with no flag.

```bash
flutter analyze                                   # must be clean
flutter test                                      # 34 checks
flutter test test/screenshot_test.dart --update-goldens   # re-render the PNGs
```

Package id: `com.prishapharma.telecaller`.

## Layout

```
lib/
  core/        api client, envelope, failures, token store, dialler, theme
  features/    auth · persons (the queue) · calls · messages · profile · shell
```

Each feature is `domain/` (models), `data/` (repository), `state/` (Riverpod),
`ui/` (screens). A screen never sees Dio, an HTTP status, or an exception type.

## What matters here

- **The queue costs one request.** `/persons` is region-scoped server-side and
  each row carries `last_call` — the last call *you* made on that person,
  already shaped like a call log. No N+1 from the client.
- **One rule is mirrored, not duplicated.** The server requires `follow_up_at`
  on `callback` and refuses it on anything else. `CallStatus.needsFollowUp`
  decides whether the field shows and whether it is sent, so the app cannot
  produce a body the server will reject. Everything else is left to the API
  and shown from `errors.reason`.
- **Nothing about timing comes from the device.** `telecaller_id` and
  `called_at` are never sent; the server stamps them, so a phone with a wrong
  clock cannot back-date work.
- **Writes refresh together.** Logging a call closes any open call-back on
  that person server-side, so `CallActions` invalidates the queue, the
  call-backs and the history as one — no view can be left stale.
- **A token dies with its account.** `account_inactive` and `role_changed`
  clear it and drop to login; a plain `forbidden` does not.

## Design

Same ProKit palette (`#1157FA`) and components as the MR app — the two are one
product. `test/golden/*.png` are rendered screens for review; they substitute
Roboto for Poppins because google_fonts cannot fetch a typeface offline in a
test.

## Before release

- The bearer token sits in `SharedPreferences`; move it to the
  Keychain/Keystore (`flutter_secure_storage`).
- Fonts are fetched at runtime by google_fonts. Bundle Poppins so a telecaller
  on a poor connection does not get a fallback face on first launch.
