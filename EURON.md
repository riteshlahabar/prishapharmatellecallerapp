# telecaller_app — Prisha Pharma Telecaller

Stack: Dart/Flutter · Riverpod · go_router · Dio · `com.prishapharma.telecaller`

## Commands
- `flutter pub get`
- `flutter analyze` — must report no issues
- `flutter test`
- `flutter run --dart-define=API_BASE_URL=<base>/api/v1`

## Layout
```
lib/core/      api (client, envelope, failures, tokens), dialler, theme, router
lib/features/  auth · persons (queue) · calls · messages · profile · shell
test/          unit, widget and golden screenshots; fixtures/ are real API captures
```

## Conventions
- Material comes from `package:material_ui/material_ui.dart`. The SDK's
  `package:flutter/material.dart` is deprecated after Flutter 3.47 and its
  types are *not* interchangeable with material_ui's.
- One feature = `domain/` + `data/` + `state/` + `ui/`. UI never touches Dio.
- Every API failure is an `ApiFailure` with a stable `reason`; never branch
  on an HTTP status or a message string.
- `follow_up_at` goes on the wire only for `CallStatus.callback` — the server
  rejects it on any other status.
- Backend contract: `docs/api/v1-common.md` and `v1-telecaller.md` in the CRM.
