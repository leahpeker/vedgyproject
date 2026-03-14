# Phase 2: Flutter Scaffold

## Goal

Initialize the Flutter project with the foundational architecture: Dio HTTP client, Freezed models, JWT auth flow, GoRouter, and the app shell (nav bar + footer). By the end of this phase, a user can open the Flutter web app, sign up, log in, and see a working nav bar — proving the full stack works end to end.

## Step 1: Initialize Flutter Project

```bash
cd vedgyproject
flutter create frontend --platforms web
```

Clean up default boilerplate. Set up `analysis_options.yaml` with recommended lints.

## Step 2: Add Dependencies

**pubspec.yaml:**
```yaml
dependencies:
  flutter_riverpod: ^2.x
  riverpod_annotation: ^2.x
  dio: ^5.x
  go_router: ^14.x
  flutter_secure_storage: ^9.x
  freezed_annotation: ^2.x
  json_annotation: ^4.x

dev_dependencies:
  build_runner: ^2.x
  freezed: ^2.x
  json_serializable: ^6.x
  riverpod_generator: ^2.x
```

## Step 3: Freezed Models

**lib/models/auth_tokens.dart:**
```dart
@freezed
class AuthTokens with _$AuthTokens {
  const factory AuthTokens({
    required String access,
    required String refresh,
  }) = _AuthTokens;

  factory AuthTokens.fromJson(Map<String, dynamic> json) =>
      _$AuthTokensFromJson(json);
}
```

**lib/models/user.dart:**
```dart
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String email,
    required String firstName,
    required String lastName,
    String? phone,
    required DateTime createdAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

@freezed
class LoginRequest with _$LoginRequest { ... }

@freezed
class SignupRequest with _$SignupRequest { ... }
```

**lib/models/listing.dart:**
Listing, ListingPhoto, ListingFilters — matching the Django schemas from Phase 1. These will be fleshed out in Phase 3 but stub them now to verify codegen works.

Run `make frontend-codegen` to generate `.freezed.dart` and `.g.dart` files.

## Step 4: Dio Client with Interceptors

**lib/services/api_client.dart:**

Create a Riverpod provider that exposes a configured Dio instance.

Base URL: read from environment config (`localhost:8000` in dev).

**Auth interceptor:**
- `onRequest`: if access token exists in auth provider state, attach `Authorization: Bearer <token>` header
- `onError`: if 401 response, attempt refresh:
  1. Read refresh token from `flutter_secure_storage`
  2. Call `POST /api/auth/refresh/` with it
  3. If success: update access token in auth provider, retry original request
  4. If failure: clear all tokens, navigate to `/login`

**Error interceptor:**
- Map non-2xx responses to typed exceptions
- Extract validation error details from Django Ninja's error response format

## Step 5: Secure Storage Wrapper

**lib/services/secure_storage.dart:**

Thin wrapper around `flutter_secure_storage`:
- `saveRefreshToken(String token)`
- `getRefreshToken() → String?`
- `clearTokens()`

On web, this uses `localStorage` with the package's built-in encryption. On mobile later, it uses Keychain (iOS) and EncryptedSharedPreferences (Android) — no code changes needed.

## Step 6: Auth Provider

**lib/providers/auth_provider.dart:**

Riverpod `StateNotifier` (or `@riverpod` annotated) managing:

State:
```dart
@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.authenticated(User user, String accessToken) = _Authenticated;
  const factory AuthState.unauthenticated() = _Unauthenticated;
}
```

Methods:
- `init()` — called on app startup, tries to refresh from stored refresh token
- `login(String email, String password)` — calls `/api/auth/login/`, stores tokens
- `signup(SignupRequest request)` — calls `/api/auth/signup/`, stores tokens
- `logout()` — clears tokens, sets unauthenticated
- `refreshToken()` — called by Dio interceptor

Access token lives only in this provider's state (in-memory). Refresh token persisted via secure storage.

## Step 7: GoRouter with Auth Guards

**lib/router/app_router.dart:**

```dart
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    redirect: (context, state) {
      final isAuth = authState is Authenticated;
      final isAuthRoute = state.matchedLocation == '/login'
          || state.matchedLocation == '/signup';

      if (!isAuth && _requiresAuth(state.matchedLocation)) {
        return '/login?redirect=${state.matchedLocation}';
      }
      if (isAuth && isAuthRoute) {
        return '/dashboard';
      }
      return null;
    },
    routes: [ ... ],
  );
});
```

Protected routes: `/create`, `/edit/:id`, `/preview/:id`, `/pay/:id`, `/dashboard`.

## Step 8: App Scaffold

**lib/widgets/app_scaffold.dart:**

Shared layout wrapping all screens:
- **Nav bar**: Vedgy logo, Home, Browse, Post Listing, My Listings links. Conditional auth links (Login/Sign Up vs user greeting + Logout). Matches current `base.html` nav structure.
- **Footer**: Quick links, feedback, legal links. Matches current footer.
- **Content area**: receives child widget from router

Responsive: hamburger menu on narrow viewports, full nav on wide.

## Step 9: Login & Signup Screens

**lib/screens/login_screen.dart:**
- Email + password fields
- "Log In" button calling `authProvider.login()`
- Link to signup and password reset
- Error display for invalid credentials
- On success: redirect to `redirect` query param or `/dashboard`

**lib/screens/signup_screen.dart:**
- Email, first name, last name, password, confirm password fields
- Client-side validation (email format, password match, min length)
- "Sign Up" button calling `authProvider.signup()`
- Error display for duplicate email, weak password
- On success: redirect to `/dashboard`

## Step 10: Makefile Additions

```makefile
frontend-install:
	cd frontend && flutter pub get

frontend-run:
	cd frontend && flutter run -d chrome --web-port 3000

frontend-build:
	cd frontend && flutter build web

frontend-codegen:
	cd frontend && dart run build_runner build --delete-conflicting-outputs

dev:
	make run & make frontend-run
```

## Acceptance Criteria

- Flutter web app loads at `localhost:3000`
- Can sign up → redirected to dashboard (empty, placeholder)
- Can log out → redirected to home
- Can log in → redirected to dashboard
- Page refresh preserves auth (refresh token recovers session)
- Nav bar shows correct links for auth/unauth state
- Auth-required routes redirect to login with return URL
- Dio interceptor transparently refreshes expired access tokens
