/// Base URL for the Django backend API.
/// Set via --dart-define=API_URL=https://your-backend.railway.app at build time.
/// Defaults to localhost:8000 for local development.
const apiBaseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:8000',
);
