/// Returns a list of error messages for the listing form fields.
///
/// All parameters accept the raw text values from controllers.
/// [city] is `required String?` because `null` means no selection (= error).
/// [price], [startDate], [endDate] default to `''` (empty = valid, optional).
List<String> validateListingForm({
  required String title,
  required String? city,
  String price = '',
  String startDate = '',
  String endDate = '',
}) {
  final errors = <String>[];

  if (title.trim().isEmpty) {
    errors.add('Title is required.');
  }

  if (city == null) {
    errors.add('City is required.');
  }

  final priceText = price.trim();
  if (priceText.isNotEmpty) {
    final parsed = int.tryParse(priceText);
    if (parsed == null || parsed <= 0) {
      errors.add('Price must be a positive whole number.');
    }
  }

  if (startDate.isNotEmpty && endDate.isNotEmpty) {
    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      if (start.isAfter(end)) {
        errors.add('Start date must be before end date.');
      }
    } catch (_) {
      // If date parsing fails, let the API validation handle it.
    }
  }

  return errors;
}
