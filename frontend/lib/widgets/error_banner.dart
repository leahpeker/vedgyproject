import 'package:flutter/material.dart';

/// Parses a raw Django Ninja auth error response body into a user-facing
/// message. Handles both `{"detail": "..."}` and list-format validation
/// responses. Returns [fallback] when the body does not match either shape.
String parseAuthError(dynamic data, {required String fallback}) {
  if (data is Map<String, dynamic>) {
    return data['detail']?.toString() ?? fallback;
  }
  if (data is List && data.isNotEmpty) {
    final first = data.first;
    if (first is Map<String, dynamic>) {
      return first['msg']?.toString() ?? fallback;
    }
  }
  return fallback;
}

/// Displays a styled error message inside auth forms.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 18,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
