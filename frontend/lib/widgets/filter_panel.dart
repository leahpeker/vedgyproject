import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/listing.dart';
import '../providers/listings_provider.dart';

class FilterPanel extends ConsumerStatefulWidget {
  const FilterPanel({super.key});

  @override
  ConsumerState<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends ConsumerState<FilterPanel> {
  final _priceMinController = TextEditingController();
  final _priceMaxController = TextEditingController();
  Timer? _debounce;

  static const _cities = ['New York City', 'Los Angeles', 'Chicago', 'Other'];
  static const _boroughs = ['Manhattan', 'Brooklyn', 'Queens', 'The Bronx', 'Staten Island'];
  static const _rentalTypes = ['Long-term', 'Short-term', 'Both'];
  static const _roomTypes = ['Entire place', 'Private room', 'Shared room'];
  static const _veganHouseholds = ['Fully vegan', 'Mostly vegan', 'Vegan-friendly'];
  static const _furnishedOptions = ['Furnished', 'Unfurnished', 'Partially furnished'];

  @override
  void dispose() {
    _priceMinController.dispose();
    _priceMaxController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onPriceChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final filters = ref.read(browseFiltersProvider);
      ref.read(browseFiltersProvider.notifier).update(
            filters.copyWith(
              priceMin: int.tryParse(_priceMinController.text),
              priceMax: int.tryParse(_priceMaxController.text),
              page: 1,
            ),
          );
    });
  }

  void _updateFilter(ListingFilters Function(ListingFilters) updater) {
    final current = ref.read(browseFiltersProvider);
    ref.read(browseFiltersProvider.notifier).update(updater(current).copyWith(page: 1));
  }

  void _clearAll() {
    _priceMinController.clear();
    _priceMaxController.clear();
    ref.read(browseFiltersProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(browseFiltersProvider);
    final isNyc = filters.city == 'New York City';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Filters',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearAll,
                  child: const Text('Clear all'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                // Compute item width so items never overflow: fit 3 cols on
                // wide screens, 2 on medium, 1 on narrow. The 12px spacing
                // between items is subtracted before dividing.
                final w = constraints.maxWidth;
                final cols = w >= 580 ? 3 : w >= 360 ? 2 : 1;
                final itemW = (w - 12 * (cols - 1)) / cols;
                final priceW = (itemW).clamp(80.0, 160.0);

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _FilterDropdown(
                      width: itemW,
                      label: 'City',
                      value: filters.city,
                      items: _cities,
                      onChanged: (v) => _updateFilter((f) => f.copyWith(city: v, borough: null)),
                    ),
                    if (isNyc)
                      _FilterDropdown(
                        width: itemW,
                        label: 'Borough',
                        value: filters.borough,
                        items: _boroughs,
                        onChanged: (v) => _updateFilter((f) => f.copyWith(borough: v)),
                      ),
                    _FilterDropdown(
                      width: itemW,
                      label: 'Rental type',
                      value: filters.rentalType,
                      items: _rentalTypes,
                      onChanged: (v) => _updateFilter((f) => f.copyWith(rentalType: v)),
                    ),
                    _FilterDropdown(
                      width: itemW,
                      label: 'Room type',
                      value: filters.roomType,
                      items: _roomTypes,
                      onChanged: (v) => _updateFilter((f) => f.copyWith(roomType: v)),
                    ),
                    _FilterDropdown(
                      width: itemW,
                      label: 'Vegan household',
                      value: filters.veganHousehold,
                      items: _veganHouseholds,
                      onChanged: (v) => _updateFilter((f) => f.copyWith(veganHousehold: v)),
                    ),
                    _FilterDropdown(
                      width: itemW,
                      label: 'Furnished',
                      value: filters.furnished,
                      items: _furnishedOptions,
                      onChanged: (v) => _updateFilter((f) => f.copyWith(furnished: v)),
                    ),
                    _SeeingRoommateToggle(
                      width: itemW,
                      value: filters.seekingRoommate,
                      onChanged: (v) => _updateFilter((f) => f.copyWith(seekingRoommate: v)),
                    ),
                    SizedBox(
                      width: priceW,
                      child: TextField(
                        controller: _priceMinController,
                        decoration: const InputDecoration(
                          labelText: 'Min price',
                          prefixText: '\$',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _onPriceChanged(),
                      ),
                    ),
                    SizedBox(
                      width: priceW,
                      child: TextField(
                        controller: _priceMaxController,
                        decoration: const InputDecoration(
                          labelText: 'Max price',
                          prefixText: '\$',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _onPriceChanged(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.width,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final double width;
  final String label;
  final String? value;
  final List<String> items;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        key: ValueKey(value),
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('Any')),
          ...items.map((item) => DropdownMenuItem(value: item, child: Text(item))),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _SeeingRoommateToggle extends StatelessWidget {
  const _SeeingRoommateToggle({required this.width, required this.value, required this.onChanged});

  final double width;
  final bool? value;
  final void Function(bool?) onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<bool?>(
        key: ValueKey(value),
        initialValue: value,
        decoration: const InputDecoration(
          labelText: 'Seeking roommate',
          isDense: true,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        items: const [
          DropdownMenuItem(value: null, child: Text('Any')),
          DropdownMenuItem(value: true, child: Text('Yes')),
          DropdownMenuItem(value: false, child: Text('No')),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
