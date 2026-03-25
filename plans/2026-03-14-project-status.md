# Vedgy Project Status — March 14, 2026

## Overview

Vedgy is an open-source vegan housing platform built with Django 5.2 (backend) and Flutter web app. Currently on **Phase 6: Mobile** development. Phases 1–5 are complete and deployed.

**Current Branch:** `feature/flutter-api-foundation`
**Last Updated:** 2026-03-14
**Model:** Claude Haiku 4.5 (claude-haiku-4-5-20251001)

---

## Completed Phases

### Phase 1: API Foundation ✓
- Django Ninja REST API with JWT auth (access + refresh tokens)
- User signup/login/logout endpoints with rate limiting (5/hr signup, 10/hr login)
- Listing CRUD endpoints with photo upload support
- Server-side validation and field-level error responses

### Phase 2: Flutter Scaffold ✓
- Flutter web app with Riverpod 3 state management
- GoRouter for client-side navigation
- Dio HTTP client with auth token refresh interceptor
- Error handling with centralized `ApiException` unwrapping

### Phase 3: Core Screens ✓
- Signup/Login screens with email validation and password field errors
- Browse screen with listing grid + filter sidebar (HTMX integration for filtering)
- Listing detail screen with photo gallery
- Dashboard screen showing user's listings

### Phase 4: Listing Management ✓
- Create/Edit listing forms with auto-save (debounced 2s after first edit)
- Photo upload with immediate feedback (shows count, thumbnail previews)
- Photo deletion from listing
- Form validation (client + server)

### Phase 5: Polish & Parity ✓
- Photo upload error handling (DioException → ApiException unwrapping)
- Keeper providers to prevent mid-upload disposal (`photoActionsProvider`, `listingActionsProvider`)
- Absolute media URLs via `SITE_URL` setting for cross-origin local dev
- Differentiated error states on browse/dashboard screens
- Server-rendered fallback for dynamic routes (HTMX integration)
- Railway deployment with Flutter web build

### Phase 6: Mobile (IN PROGRESS - 2/7 steps complete)
✓ Step 1: Mobile platforms enabled (iOS/Android directories created)
✓ Step 2: Platform-specific adjustments
  - Camera & photo library permissions added (Info.plist + AndroidManifest)
  - Platform detection utilities created (`PlatformUtils`)
  - Platform-specific image picker: bottom sheet with camera + gallery on mobile
  - SafeArea wrapper for notches/home indicators

⏳ Step 3: API Base URL (ready - uses `--dart-define=API_URL`)
⏳ Step 4: Platform Testing (manual — iOS simulator, Android emulator)
⏳ Step 5: Mobile-specific UI Polish (touch targets, responsive design)
⏳ Step 6: App Store Preparation (icons, metadata, store listings)
⏳ Step 7: CI/CD for Mobile (APK/IPA build pipeline)

---

## Key Technical Decisions

### Backend
- **Database:** PostgreSQL (prod) via `DATABASE_URL`; SQLite local dev
- **Auth:** JWT with refresh token rotation, stored in `flutter_secure_storage`
- **Photo Storage:** Backblaze B2 with local filesystem fallback (fallback on invalid B2 credentials)
- **API Framework:** Django Ninja (lightweight async REST API)
- **Form Validation:** Server-side via Pydantic schemas, field-level errors returned to client

### Frontend
- **State Management:** Riverpod 3 (`@riverpod`, `@Riverpod(keepAlive: true)`)
- **Navigation:** GoRouter with deep linking support
- **HTTP Client:** Dio with custom auth & error interceptors
- **Provider Lifecycle:** Auto-dispose by default; `keepAlive: true` for action providers that hold `Ref` for async operations
- **Error Handling:** Centralized `_ErrorInterceptor` wraps `ApiException` inside `DioException.error`
- **Image Picker:** Uses native `image_picker` package (web: file dialog; mobile: camera + gallery options)

### Deployment
- **Web:** Flask app served from `localhost:3000` (dev) or Railway (prod) at root URL with `/api` relative to same origin
- **Mobile:** Uses absolute URL via `--dart-define=API_URL=https://your-domain.com/api` at build time
- **Local Dev:** Django at `:8000`, Flutter at `:3000`, cross-origin fetch with `SITE_URL` for absolute media URLs

---

## Current Working Directory State

**Branch:** `feature/flutter-api-foundation`

### Recent Commits (newest first)
```
cc5841f docs: update CLAUDE.md to only use make ci for tests
51e5e6b feat: add platform-specific mobile UI and safe area handling
892e1e9 feat: enable iOS and Android platforms with camera/photo permissions
be00fcb refactor: simplify save_picture to return filename only, URL via get_photo_url
4b41065 fix: update browse and dashboard widget tests for new error/empty messages
```

### Key Files Modified
- `CLAUDE.md` — project instructions (read this first on session start)
- `frontend/lib/utils/platform.dart` — new platform detection utilities
- `frontend/lib/widgets/listing_form.dart` — platform-specific image picker with bottom sheet on mobile
- `frontend/lib/main.dart` — SafeArea wrapper for safe area handling
- `frontend/ios/Runner/Info.plist` — camera & photo library permission descriptions
- `frontend/android/app/src/main/AndroidManifest.xml` — camera & storage permissions

### Test Status
- ✓ 100 backend tests passing (Django)
- ✓ 236 Flutter tests passing (unit + widget)
- ✓ All linting and formatting checks pass
- Command: `make ci` runs all checks in sequence

---

## Environment Setup

### Prerequisites
- macOS (required for iOS development)
- Flutter SDK (v3.22+)
- Xcode command-line tools
- Android Studio (for Android emulator, optional for iOS simulator dev)
- Python 3.13 + uv package manager
- PostgreSQL (Docker recommended via `make db-start`)

### Local Dev Setup
```bash
cp .env.example .env          # B2 credentials optional for local dev (uses fallback)
make install                  # Install Python + Flutter dependencies via uv
make db-start                 # Start PostgreSQL Docker container
make migrate                  # Apply Django migrations
make run                       # Start Django at :8000
make frontend-run             # Start Flutter web at :3000 (in another terminal)
```

### Development Commands
```bash
make ci                       # Run all pre-commit checks (lint, check, test, frontend-test)
make lint                     # Format code (autoflake, isort, black)
make test                     # Run backend tests
make frontend-test            # Run Flutter tests (never run flutter test directly!)
make frontend-codegen         # Regenerate .freezed.dart and .g.dart after @freezed/@riverpod changes
make frontend-run             # Flutter web dev server with hot reload
make dev                       # Run Django + Flutter concurrently
```

---

## Next Steps (Phase 6 Continuation)

### Batch 3 (Tasks 5–7)
1. **Step 5a: Mobile-specific UI Polish**
   - Implement 48x48dp minimum touch target sizing for tappable elements
   - Add platform-specific keyboard types (email keyboard for email fields, number for price)
   - Test on various screen sizes via simulators

2. **Step 5b: Bundle Identifiers & Display Names**
   - Update iOS bundle identifier in `ios/Runner/xcodeproj`
   - Update Android application ID in `android/app/build.gradle.kts`
   - Set version numbers and build numbers

3. **Step 6: App Store Preparation**
   - Add app icons (1024x1024 for iOS, adaptive for Android)
   - Add splash screens
   - Configure `Info.plist` entries (app name, version, privacy policy URL)
   - Create store listings (screenshots, descriptions, pricing)

4. **Step 7: CI/CD for Mobile**
   - Add Flutter APK build command (`flutter build apk --release --dart-define=API_URL=...`)
   - Add Flutter IPA build command (`flutter build ipa --release --dart-define=API_URL=...`)
   - Consider Codemagic or GitHub Actions for automated mobile builds

### Post-Mobile (Future Phases)
- **Push Notifications** — notify listers when listings are approved/rejected
- **Offline Support** — cache browse results for offline viewing
- **Biometric Auth** — fingerprint/face login using stored refresh token
- **App-Specific Features** — location-based suggestions, map view

---

## Known Gotchas

### Photo Upload Error Handling
- **Common Mistake:** Catching `ApiException` directly after Dio call. This never works because `_ErrorInterceptor` wraps it inside `DioException.error`.
- **Correct Pattern:** Catch `DioException`, then check `e.error is ApiException`.

### Riverpod Provider Disposal
- **Auto-dispose:** Providers are torn down when no longer watched. If an async operation holds a `Ref` (like `photoActionsProvider`), it must use `@Riverpod(keepAlive: true)`.
- **Data-fetching providers** (`dashboardProvider`, `browseListingsProvider`) are safe with auto-dispose because they don't hold `Ref` for async operations.

### Photo URL Construction
- **Web (prod):** Uses relative `/api/media/filename.jpg` (same origin).
- **Local dev:** Must use absolute `http://localhost:8000/media/filename.jpg` because Flutter at `:3000` resolves relative URLs against its own origin.
- **Mobile:** Uses absolute URL passed at build time via `--dart-define=API_URL=https://your-domain.com/api`.

### Flutter Tests
- **Never run** `flutter test` directly — always use `make ci` or `make frontend-test`.
- Large test output exceeds tool buffer; `make ci` wraps this properly.

### Git Workflow
- Always branch off `main` for features. Current branch: `feature/flutter-api-foundation` (for all phases).
- Run `make ci` before committing. All checks must pass.
- Use conventional commit messages with co-author line.

---

## For New Sessions / Different Computers

1. **Clone the repo** (if starting fresh):
   ```bash
   git clone https://github.com/leahpeker/vedgyproject.git
   cd vedgyproject
   ```

2. **Switch to the feature branch:**
   ```bash
   git checkout feature/flutter-api-foundation
   ```

3. **Read `CLAUDE.md`** for project-specific guidance (environment vars, commands, architecture).

4. **Run local dev setup:**
   ```bash
   cp .env.example .env
   make install && make db-start && make migrate
   make run &    # Django at :8000
   make frontend-run  # Flutter at :3000
   ```

5. **Continue Phase 6** by reading the phase plan at `plans/2026-02-11-flutter-phase6-mobile.md` and executing the next batch.

---

## Quick Reference

| Task | Command |
|------|---------|
| Run all checks | `make ci` |
| Format code | `make lint` |
| Backend tests | `make test` |
| Flutter tests | `make frontend-test` (NOT `flutter test`) |
| Regenerate code | `make frontend-codegen` |
| Start dev server | `make run` |
| Start Flutter web | `make frontend-run` |
| Both concurrently | `make dev` |
| Start database | `make db-start` |
| Stop database | `make db-stop` |

---

**Last worked on by:** Claude Haiku 4.5
**Session:** Executing Phase 6 Batch 2 of `/executing-plans` skill
**Status:** Batch 2 complete (platform detection, image picker, SafeArea)
