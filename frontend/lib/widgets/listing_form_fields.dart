import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Listing form dropdown option constants
// ---------------------------------------------------------------------------

const listingCities = ['New York', 'Los Angeles', 'Chicago'];
const listingBoroughs = [
  'Manhattan',
  'Brooklyn',
  'Queens',
  'Bronx',
  'Staten Island',
];
const listingRentalTypes = [
  ('sublet', 'Sublet'),
  ('new_lease', 'New Lease'),
  ('month_to_month', 'Month to Month'),
  ('short_term', 'Short Term'),
];
const listingRoomTypes = [
  ('private_room', 'Private Room'),
  ('shared_room', 'Shared Room'),
  ('entire_place', 'Entire Place'),
];
const listingVeganHouseholds = [
  ('fully_vegan', 'Fully vegan household'),
  ('mixed_household', 'Mixed household'),
];
const listingFurnishedOptions = [
  ('unfurnished', 'Unfurnished'),
  ('partially_furnished', 'Partially furnished'),
  ('fully_furnished', 'Fully furnished'),
];
const listingRelationships = [
  ('owner', 'I own the space'),
  ('manager', 'I manage the space'),
  ('tenant', 'I am the current tenant'),
  ('roommate', 'I am a current roommate'),
];

// ---------------------------------------------------------------------------
// Reusable form field builders
// ---------------------------------------------------------------------------

/// Labeled text field with standard styling.
Widget buildFormField({
  required String label,
  required String hint,
  required TextEditingController controller,
  required void Function(String) onChanged,
  int maxLines = 1,
  TextInputType? keyboardType,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 4),
      TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
        onChanged: onChanged,
      ),
    ],
  );
}

/// Labeled dropdown with standard styling.
Widget buildFormDropdown<T>({
  required String label,
  required T? value,
  required List<(T, String)> items,
  required void Function(T?) onChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 4),
      DropdownButtonFormField<T>(
        key: ValueKey(value),
        initialValue: value,
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('Select...')),
          ...items.map(
            (pair) => DropdownMenuItem(value: pair.$1, child: Text(pair.$2)),
          ),
        ],
        onChanged: onChanged,
      ),
    ],
  );
}

/// Labeled date picker field with standard styling.
Widget buildFormDateField({
  required String label,
  required TextEditingController controller,
  required void Function(String?) onPicked,
  required BuildContext context,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 4),
      TextField(
        controller: controller,
        readOnly: true,
        decoration: const InputDecoration(
          hintText: 'YYYY-MM-DD',
          isDense: true,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          suffixIcon: Icon(Icons.calendar_today, size: 16),
        ),
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: now,
            firstDate: now.subtract(const Duration(days: 30)),
            lastDate: now.add(const Duration(days: 730)),
          );
          if (picked != null) {
            final formatted =
                '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
            controller.text = formatted;
            onPicked(formatted);
          }
        },
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Divider(),
        const SizedBox(height: 12),
      ],
    );
  }
}
