/// Parses Django Ninja validation error responses.
///
/// Handles the standard Pydantic validation error format:
/// ```json
/// {
///   "detail": [
///     { "loc": ["body", "field_name"], "msg": "error message" },
///     { "loc": ["body", "other_field"], "msg": "another error" }
///   ]
/// }
/// ```
///
/// Returns a map of field names to error messages.
Map<String, String> parseFieldErrors(dynamic data) {
  final errors = <String, String>{};

  if (data is! Map<String, dynamic>) return errors;

  final detail = data['detail'];
  if (detail is! List) return errors;

  for (final item in detail) {
    if (item is! Map<String, dynamic>) continue;

    final loc = item['loc'];
    final msg = item['msg'];

    if (loc is! List || msg is! String) continue;

    // Extract field name from loc array (typically ["body", "field_name"])
    if (loc.length >= 2) {
      final fieldName = loc[1].toString();
      errors[fieldName] = msg;
    }
  }

  return errors;
}
