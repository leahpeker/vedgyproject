---
paths:
  - "frontend/**/*.dart"
  - "**/lib/**/*.dart"
  - "**/test/**/*.dart"
  - "**/pubspec.yaml"
  - "**/analysis_options.yaml"
  - "**/build.yaml"
---

# Flutter App Standards (Riverpod + GoRouter + Dio + Freezed)

Standards for Flutter web/mobile apps using Riverpod for state, GoRouter for routing, Dio for HTTP, and Freezed for models.

## Project Layout

```
frontend/
├── lib/
│   ├── main.dart              # App entry (ProviderScope wrapping MaterialApp.router)
│   ├── config/
│   │   └── api_config.dart    # Compile-time API_URL via String.fromEnvironment
│   ├── models/                # Freezed data classes (immutable, JSON-serializable)
│   ├── providers/             # Riverpod providers (state + business logic)
│   ├── services/              # API client (Dio + interceptors), secure storage
│   ├── router/                # GoRouter config, route definitions, guards
│   ├── screens/               # Full-page widgets (one per route)
│   ├── widgets/               # Reusable UI components
│   └── utils/                 # Validators, helpers
├── test/
│   ├── helpers/               # Test fixtures, FakeSecureStorage, AppHarness
│   ├── unit/                  # Provider/model/utility tests
│   ├── widget/                # Widget tests with pumpWidget
│   └── integration/           # Multi-screen navigation tests
├── pubspec.yaml
├── build.yaml                 # json_serializable config (field_rename: snake)
└── analysis_options.yaml      # flutter_lints + riverpod_lint
```

## Models (Freezed)

### Every API Model Uses Freezed

```dart
@freezed
class Listing with _$Listing {
  const factory Listing({
    required String id,
    required String title,
    required String status,
    required ListingUser user,
    @Default([]) List<ListingPhoto> photos,
    DateTime? startDate,        // Nullable for optional fields
  }) = _Listing;

  factory Listing.fromJson(Map<String, dynamic> json) => _$ListingFromJson(json);
}
```

### build.yaml: Snake Case Mapping

```yaml
targets:
  $default:
    builders:
      json_serializable:
        options:
          field_rename: snake        # camelCase Dart <-> snake_case JSON
          explicit_to_json: true     # Required for nested model serialization
```

This maps `startDate` in Dart to `start_date` in JSON automatically. Only use `@JsonKey(name: ...)` when the JSON key doesn't follow snake_case convention (e.g., `access` -> `accessToken`).

### After Editing @freezed or @riverpod Files

Always run codegen:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### YAGNI for Freezed Classes

Never create `@freezed` classes speculatively. Unused Freezed classes are actively harmful because they require generated `.freezed.dart` and `.g.dart` files to compile. If a Freezed class has zero references, delete it immediately.

## State Management (Riverpod)

### Three Provider Styles

| Style | Use When | Example |
|-------|----------|---------|
| Functional `@riverpod` | Read-only data fetching | `Future<Listing> listingDetail(Ref ref, String id)` |
| Class `@Riverpod(keepAlive: true)` | Mutable state + methods (auth, forms) | `class Auth extends _$Auth` |
| Class `@riverpod` (auto-dispose) | Short-lived mutable state | Widget-scoped state |

### keepAlive: true (Critical)

Any provider that performs multi-step async operations MUST use `@Riverpod(keepAlive: true)`. Without it, Riverpod's auto-dispose tears down the provider between async steps (e.g., while `await`ing file I/O before a network call), causing silent failures.

**When to use keepAlive:**
- Auth provider (session outlives any single screen)
- Providers that do file I/O then network requests (photo upload)
- Any provider where the async operation must complete even if no widget is watching

**When NOT to use keepAlive:**
- Pure data-fetching providers (invalidation + re-fetch is fine)
- Screen-scoped state that should reset on navigation

### Union Types for State Machines

```dart
@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.authenticated({required User user, required String accessToken}) = _Authenticated;
  const factory AuthState.unauthenticated() = _Unauthenticated;
}
```

Use `.when()` / `.map()` to force exhaustive handling. Makes impossible states unrepresentable.

### Cache Invalidation After Mutations

```dart
Future<void> createListing(ListingIn data) async {
  await _api.post('/api/listings/', data: data.toJson());
  ref.invalidate(dashboardProvider);    // Explicit invalidation
  ref.invalidate(browseListingsProvider);
}
```

Every mutation must declare which providers to invalidate. Never rely on polling or manual refresh.

### ref.read vs ref.watch

- `ref.watch(provider)` — in `build()` methods and provider bodies (reactive)
- `ref.read(provider)` — in callbacks, event handlers, one-time reads
- `ref.read` for `apiClientProvider` to prevent redundant HTTP client creation

## HTTP Client (Dio)

### Separate Auth Dio Instance

```dart
class Auth extends _$Auth {
  late final Dio _authDio;  // Plain Dio, NO interceptors

  @override
  AuthState build() {
    _authDio = Dio(BaseOptions(baseUrl: apiBaseUrl));
    return const AuthState.initial();
  }
}
```

Auth endpoints (login, signup, refresh) use a plain Dio instance to avoid circular dependency with the auth interceptor.

### Interceptor Architecture

```dart
final dio = Dio(BaseOptions(baseUrl: apiBaseUrl));
dio.interceptors.addAll([
  QueuedInterceptorsWrapper(  // Serializes requests during token refresh
    onRequest: _attachAuthHeader,
    onError: _handleAuthError,
  ),
  InterceptorsWrapper(onError: _normalizeErrors),
]);
```

Three interceptors in order:
1. **Auth interceptor** (QueuedInterceptorsWrapper): Attaches Bearer token, handles 401 refresh
2. **Error interceptor**: Normalizes errors into `ApiException(statusCode, detail)`

### Token Refresh with Locking

```dart
Completer<String?>? _refreshCompleter;

void _handleAuthError(DioException err, ErrorInterceptorHandler handler) {
  if (err.response?.statusCode != 401) return handler.next(err);
  if (err.requestOptions.extra['_retried'] == true) return handler.next(err);

  if (_refreshCompleter != null) {
    // Another request is already refreshing — wait for it
    _refreshCompleter!.future.then((token) => _retryWithToken(err, token, handler));
    return;
  }

  _refreshCompleter = Completer<String?>();
  _doRefresh().then((token) {
    _refreshCompleter!.complete(token);
    _refreshCompleter = null;
    _retryWithToken(err, token, handler);
  });
}
```

- `Completer` prevents concurrent refresh calls
- `_retried` flag prevents infinite 401 loops
- Use `QueuedInterceptorsWrapper` to serialize requests during refresh

### Error Normalization

```dart
class ApiException implements Exception {
  final int statusCode;
  final String detail;
  ApiException(this.statusCode, this.detail);
}
```

The error interceptor extracts `detail` from Django's `{"detail": "..."}` response shape. Screens catch `DioException` and unwrap `e.error as ApiException` — never catch `ApiException` directly (Dio wraps it).

### API URL Configuration

```dart
const apiBaseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8000');
```

- Compile-time constant via `--dart-define=API_URL=...`
- Production: empty string (same-origin requests)
- Development: `http://localhost:8000` (Django dev server)

## Routing (GoRouter)

### Route Definition

```dart
GoRouter(
  refreshListenable: authNotifier,  // ValueNotifier bridging Riverpod
  redirect: _guardRedirect,
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(
      path: '/password-reset-confirm/:uidb64/:token',
      builder: (_, state) => PasswordResetConfirmScreen(
        uidb64: state.pathParameters['uidb64']!,
        token: state.pathParameters['token']!,
      ),
    ),
  ],
)
```

### Auth Guards

```dart
String? _guardRedirect(BuildContext context, GoRouterState state) {
  final auth = ref.read(authProvider);
  final isAuthRoute = ['/login', '/signup'].contains(state.matchedLocation);

  return auth.when(
    initial: () => null,
    authenticated: (_, __) => isAuthRoute ? '/dashboard' : null,
    unauthenticated: () {
      if (_protectedRoutes.contains(state.matchedLocation)) {
        return '/login?redirect=${state.matchedLocation}';
      }
      return null;
    },
  );
}
```

- Preserve `?redirect=` for post-login navigation
- Authenticated users redirect away from auth pages
- Use a `ValueNotifier` counter to bridge Riverpod → GoRouter's `refreshListenable`

## Testing

### Test Harness (AppHarness)

```dart
class AppHarness {
  final List<Override> providerOverrides;
  final Widget child;

  Widget build() => ProviderScope(
    overrides: providerOverrides,
    child: MaterialApp(home: child),
  );
}
```

### Mocking with Mocktail (Not Mockito)

```dart
class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    // Register fallback values for complex types
    registerFallbackValue(RequestOptions(path: ''));
  });
}
```

Use `mocktail` (not `mockito`) — no code generation required.

### FakeSecureStorage

```dart
class FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<String?> read({required String key, ...}) async => _store[key];

  @override
  Future<void> write({required String key, required String value, ...}) async => _store[key] = value;

  @override
  Future<void> delete({required String key, ...}) async => _store.remove(key);
}
```

### Widget Test Pattern

```dart
testWidgets('shows login form', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authProvider.overrideWith(() => FakeAuth())],
      child: const MaterialApp(home: LoginScreen()),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.byType(TextFormField), findsNWidgets(2));
  expect(find.text('Log in'), findsOneWidget);
});
```

### Test Fixtures (SINGLE Source)

One `test/helpers/test_fixtures.dart` file with all JSON fixtures. Never duplicate between unit and integration test directories. Fixtures mirror Django API response shapes exactly.

### Error Message Assertions

Use `find.textContaining('Something went wrong')` instead of exact string matches for error messages. Exact matches break when error wording changes.

## Widget Patterns

### Screen vs Widget

- **Screens** (`screens/`): Full pages, one per route. Own their own `Scaffold` or receive it from the app shell.
- **Widgets** (`widgets/`): Reusable pieces. No routing logic. Accept data via constructor.

### Extract When >300 Lines

If a widget exceeds ~300 lines, extract sub-widgets:
- Form sections → separate widget files
- Repeated field builders → extracted functions
- Photo/image sections → dedicated widget

### Responsive Layout

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final columns = constraints.maxWidth > 900 ? 3 : constraints.maxWidth > 600 ? 2 : 1;
    // ...
  },
)
```

Never use fixed widths. Use `LayoutBuilder` or `MediaQuery` for responsive sizing.

### Logging (Not print)

```dart
import 'package:logging/logging.dart';
final _log = Logger('MyWidget');

_log.info('Fetching listings');
_log.warning('Retry attempt $n');
_log.severe('Upload failed', error, stackTrace);
```

Never use `print()` in production code. The `logging` package provides structured, leveled output.

## analysis_options.yaml

```yaml
include: package:flutter_lints/flutter.yaml
plugins:
  riverpod_lint: ^3.1.3

analyzer:
  errors:
    invalid_annotation_target: ignore           # Freezed pattern
    non_abstract_class_inherits_abstract_member: ignore  # Freezed factory

linter:
  rules:
    avoid_unnecessary_containers: true
    prefer_const_constructors: true
    prefer_const_literals_to_create_immutables: true
    prefer_single_quotes: true
    require_trailing_commas: true
    sized_box_for_whitespace: true
    use_colored_box: true
```

## Common Bugs to Avoid

1. **Provider disposed mid-upload**: `@riverpod` (auto-dispose) kills providers between async steps. Use `@Riverpod(keepAlive: true)` for multi-step async work.
2. **Catching ApiException directly**: Dio wraps inner exceptions. Catch `DioException`, then unwrap `e.error`.
3. **Stale fixtures**: Backend schema changes must be reflected in test fixture JSON. Two fixture files = guaranteed drift.
4. **Exact error string matching in tests**: Use `find.textContaining()` for error messages that may change wording.
5. **ref.watch in callbacks**: Use `ref.read` in button handlers and event callbacks, `ref.watch` only in reactive contexts.
6. **Missing codegen after model changes**: Always run `build_runner` after editing `@freezed` or `@riverpod` files.
7. **Unused Freezed classes**: They require generated code to compile. Delete immediately if unreferenced.
