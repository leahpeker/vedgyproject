import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../models/listing.dart';
import '../providers/listing_actions_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/photo_provider.dart';
import '../services/api_client.dart';

// ---------------------------------------------------------------------------
// Shared listing form — used by CreateListingScreen and EditListingScreen.
// Handles auto-save: POST on first input, then PATCH debounced 2s.
// Photos upload immediately on selection.
// ---------------------------------------------------------------------------

class ListingForm extends ConsumerStatefulWidget {
  const ListingForm({
    super.key,
    this.initial,
  });

  /// Pre-populate form fields (edit mode). Null = create mode.
  final Listing? initial;

  @override
  ConsumerState<ListingForm> createState() => _ListingFormState();
}

class _ListingFormState extends ConsumerState<ListingForm> {
  // ---- Controllers ---------------------------------------------------------
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _neighborhood = TextEditingController();
  final _price = TextEditingController();
  final _startDate = TextEditingController();
  final _endDate = TextEditingController();
  final _aboutLister = TextEditingController();
  final _rentalRequirements = TextEditingController();
  final _petPolicy = TextEditingController();
  final _phoneNumber = TextEditingController();

  // ---- Dropdown state ------------------------------------------------------
  String? _city;
  String? _borough;
  String? _rentalType;
  String? _roomType;
  String? _veganHousehold;
  String? _furnished;
  String? _listerRelationship;
  bool _seekingRoommate = false;
  bool _includePhone = false;

  // ---- Auto-save state -----------------------------------------------------
  String? _listingId;
  _SaveStatus _saveStatus = _SaveStatus.idle;
  Timer? _debounce;
  final Map<String, dynamic> _pendingChanges = {};
  bool _firstSaveInProgress = false;

  // ---- Photo state ---------------------------------------------------------
  List<ListingPhoto> _photos = [];
  bool _uploadingPhotos = false;

  // ---- Constants -----------------------------------------------------------
  static const _cities = ['New York', 'Los Angeles', 'Chicago'];
  static const _boroughs = [
    'Manhattan', 'Brooklyn', 'Queens', 'Bronx', 'Staten Island'
  ];
  static const _rentalTypes = [
    ('sublet', 'Sublet'),
    ('new_lease', 'New Lease'),
    ('month_to_month', 'Month to Month'),
  ];
  static const _roomTypes = [
    ('private_room', 'Private Room'),
    ('shared_room', 'Shared Room'),
    ('entire_place', 'Entire Place'),
  ];
  static const _veganHouseholds = [
    ('fully_vegan', 'Fully vegan household'),
    ('mixed_household', 'Mixed household'),
  ];
  static const _furnishedOptions = [
    ('unfurnished', 'Unfurnished'),
    ('partially_furnished', 'Partially furnished'),
    ('fully_furnished', 'Fully furnished'),
  ];
  static const _relationships = [
    ('owner', 'I own the space'),
    ('manager', 'I manage the space'),
    ('tenant', 'I am the current tenant'),
    ('roommate', 'I am a current roommate'),
    ('agent', 'I am a rental agent/broker'),
    ('other', 'Other'),
  ];

  @override
  void initState() {
    super.initState();
    final l = widget.initial;
    if (l != null) {
      _listingId = l.id;
      _title.text = l.title;
      _description.text = l.description;
      _neighborhood.text = l.neighborhood ?? '';
      _price.text = l.price?.toString() ?? '';
      _startDate.text = l.startDate != null
          ? '${l.startDate!.year}-${l.startDate!.month.toString().padLeft(2, '0')}-${l.startDate!.day.toString().padLeft(2, '0')}'
          : '';
      _endDate.text = l.endDate != null
          ? '${l.endDate!.year}-${l.endDate!.month.toString().padLeft(2, '0')}-${l.endDate!.day.toString().padLeft(2, '0')}'
          : '';
      _aboutLister.text = l.aboutLister ?? '';
      _rentalRequirements.text = l.rentalRequirements ?? '';
      _petPolicy.text = l.petPolicy ?? '';
      _phoneNumber.text = l.phoneNumber ?? '';
      _city = l.city.isEmpty ? null : l.city;
      _borough = l.borough;
      _rentalType = l.rentalType.isEmpty ? null : l.rentalType;
      _roomType = l.roomType.isEmpty ? null : l.roomType;
      _veganHousehold = l.veganHousehold.isEmpty ? null : l.veganHousehold;
      _furnished = l.furnished.isEmpty ? null : l.furnished;
      _listerRelationship =
          l.listerRelationship.isEmpty ? null : l.listerRelationship;
      _seekingRoommate = l.seekingRoommate;
      _includePhone = l.includePhone;
      _photos = List.from(l.photos);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [
      _title, _description, _neighborhood, _price, _startDate, _endDate,
      _aboutLister, _rentalRequirements, _petPolicy, _phoneNumber,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ---- Auto-save logic -----------------------------------------------------

  void _onChange(String field, dynamic value) {
    _pendingChanges[field] = value;
    _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    if (_firstSaveInProgress) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), _autoSave);
    setState(() => _saveStatus = _SaveStatus.saving);
  }

  Future<void> _autoSave() async {
    if (_pendingChanges.isEmpty) return;

    final actions = ref.read(listingActionsProvider);

    if (_listingId == null) {
      _firstSaveInProgress = true;
      try {
        final created = await actions.createListing(Map.from(_pendingChanges));
        _listingId = created.id;
        _pendingChanges.clear();
        if (mounted) setState(() => _saveStatus = _SaveStatus.saved);
      } catch (_) {
        if (mounted) setState(() => _saveStatus = _SaveStatus.error);
      } finally {
        _firstSaveInProgress = false;
      }
    } else {
      try {
        await actions.updateListing(_listingId!, Map.from(_pendingChanges));
        _pendingChanges.clear();
        if (mounted) setState(() => _saveStatus = _SaveStatus.saved);
      } catch (_) {
        if (mounted) setState(() => _saveStatus = _SaveStatus.error);
      }
    }
  }

  // ---- Photo handling ------------------------------------------------------

  Future<void> _pickAndUploadPhotos() async {
    if (_listingId == null) {
      // If auto-save is already creating the listing, avoid a concurrent POST.
      if (_firstSaveInProgress) {
        ref.read(notificationQueueProvider.notifier)
            .show('Still saving your draft — please try again in a moment.');
        return;
      }
      // Cancel any pending debounce so it doesn't fire a second create mid-flight.
      _debounce?.cancel();
      _firstSaveInProgress = true;
      setState(() => _saveStatus = _SaveStatus.saving);
      try {
        final created = await ref
            .read(listingActionsProvider)
            .createListing(Map.from(_pendingChanges));
        _listingId = created.id;
        _pendingChanges.clear();
        if (mounted) setState(() => _saveStatus = _SaveStatus.saved);
      } catch (e) {
        if (mounted) {
          setState(() => _saveStatus = _SaveStatus.error);
          ref.read(notificationQueueProvider.notifier)
              .showError('Could not save your draft. Check your connection and try again.');
        }
        return;
      } finally {
        _firstSaveInProgress = false;
      }
    }

    final picker = ImagePicker();
    final remaining = 10 - _photos.length;
    if (remaining <= 0) {
      ref.read(notificationQueueProvider.notifier)
          .show('Maximum 10 photos per listing.');
      return;
    }

    final picked = await picker.pickMultiImage(limit: remaining);
    if (picked.isEmpty) return;

    setState(() => _uploadingPhotos = true);
    try {
      final uploaded = await ref
          .read(photoActionsProvider)
          .uploadPhotos(_listingId!, picked);
      setState(() => _photos.addAll(uploaded));
      ref.read(notificationQueueProvider.notifier)
          .show('${uploaded.length} photo${uploaded.length == 1 ? '' : 's'} uploaded.');
    } on DioException catch (e) {
      // _ErrorInterceptor wraps ApiException inside DioException.error.
      final inner = e.error;
      final msg = inner is ApiException
          ? inner.detail
          : 'Upload failed. Please try again.';
      // ignore: avoid_print
      print('[photo upload] DioException: ${e.type} | response: ${e.response?.statusCode} ${e.response?.data} | inner: $inner');
      ref.read(notificationQueueProvider.notifier).showError(msg);
    } catch (e, st) {
      // ignore: avoid_print
      print('[photo upload] unexpected error: $e\n$st');
      ref.read(notificationQueueProvider.notifier)
          .showError('Upload failed. Please try again.');
    } finally {
      if (mounted) setState(() => _uploadingPhotos = false);
    }
  }

  Future<void> _deletePhoto(ListingPhoto photo) async {
    try {
      await ref
          .read(photoActionsProvider)
          .deletePhoto(_listingId!, photo.id);
      setState(() => _photos.remove(photo));
      ref.read(notificationQueueProvider.notifier).show('Photo deleted.');
    } on DioException catch (e) {
      final inner = e.error;
      final msg = inner is ApiException
          ? inner.detail
          : 'Delete failed. Please try again.';
      ref.read(notificationQueueProvider.notifier).showError(msg);
    }
  }

  // ---- Submit validation ---------------------------------------------------

  /// Returns a list of error messages, or empty list if valid.
  List<String> _validate() {
    final errors = <String>[];
    if (_title.text.trim().isEmpty) errors.add('Title is required.');
    if (_city == null) errors.add('City is required.');
    final priceText = _price.text.trim();
    if (priceText.isNotEmpty) {
      final parsed = int.tryParse(priceText);
      if (parsed == null || parsed <= 0) {
        errors.add('Price must be a positive whole number.');
      }
    }
    // Validate start date before end date if both are provided
    if (_startDate.text.isNotEmpty && _endDate.text.isNotEmpty) {
      try {
        final startDate = DateTime.parse(_startDate.text);
        final endDate = DateTime.parse(_endDate.text);
        if (startDate.isAfter(endDate)) {
          errors.add('Start date must be before end date.');
        }
      } catch (_) {
        // If date parsing fails, let the API validation handle it
      }
    }
    return errors;
  }

  // ---- Preview navigation --------------------------------------------------

  Future<void> _previewOrSaveFirst() async {
    // Client-side validation before allowing preview/submit
    final errors = _validate();
    if (errors.isNotEmpty) {
      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Please fix these issues'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: errors
                  .map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• '),
                            Expanded(child: Text(e)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // Warn (non-blocking) if no photos
    if (_photos.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tip: listings with photos get more interest.'),
          duration: Duration(seconds: 3),
        ),
      );
    }

    // Flush any unsaved changes before navigating to preview
    _debounce?.cancel();
    if (_pendingChanges.isNotEmpty || _listingId == null) {
      await _autoSave();
    }
    if (_listingId != null && mounted) {
      context.go('/preview/$_listingId');
    }
  }

  // ---- Build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status bar
              Row(
                children: [
                  Text(
                    widget.initial == null ? 'Post a listing' : 'Edit listing',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  _SaveIndicator(_saveStatus),
                ],
              ),
              const SizedBox(height: 24),

              // Basic info
              _SectionHeader('Basic Information'),
              _field(
                label: 'Title *',
                hint: 'Cozy room in vegan-friendly house',
                controller: _title,
                onChanged: (v) => _onChange('title', v),
              ),
              const SizedBox(height: 12),
              _field(
                label: 'Description *',
                hint: 'Describe your space, lifestyle, and what you\'re looking for...',
                controller: _description,
                maxLines: 4,
                onChanged: (v) => _onChange('description', v),
              ),
              const SizedBox(height: 24),

              // Location
              _SectionHeader('Location'),
              _dropdown<String>(
                label: 'City *',
                value: _city,
                items: _cities.map((c) => (c, c)).toList(),
                onChanged: (v) {
                  setState(() {
                    _city = v;
                    if (v != 'New York') _borough = null;
                  });
                  _onChange('city', v);
                  if (v != 'New York') _onChange('borough', null);
                },
              ),
              if (_city == 'New York') ...[
                const SizedBox(height: 12),
                _dropdown<String>(
                  label: 'Borough *',
                  value: _borough,
                  items: _boroughs.map((b) => (b, b)).toList(),
                  onChanged: (v) {
                    setState(() => _borough = v);
                    _onChange('borough', v);
                  },
                ),
              ],
              const SizedBox(height: 12),
              _field(
                label: 'Neighborhood',
                hint: 'e.g. Williamsburg, Silver Lake, Wicker Park',
                controller: _neighborhood,
                onChanged: (v) => _onChange('neighborhood', v),
              ),
              const SizedBox(height: 24),

              // Rental details
              _SectionHeader('Rental Details'),
              _dropdown<String>(
                label: 'Vegan Household *',
                value: _veganHousehold,
                items: _veganHouseholds.toList(),
                onChanged: (v) {
                  setState(() => _veganHousehold = v);
                  _onChange('vegan_household', v);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _dropdown<String>(
                      label: 'Rental Type *',
                      value: _rentalType,
                      items: _rentalTypes.toList(),
                      onChanged: (v) {
                        setState(() => _rentalType = v);
                        _onChange('rental_type', v);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dropdown<String>(
                      label: 'Room Type *',
                      value: _roomType,
                      items: _roomTypes.toList(),
                      onChanged: (v) {
                        setState(() => _roomType = v);
                        _onChange('room_type', v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      label: 'Monthly Rent (\$) *',
                      hint: '1200',
                      controller: _price,
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _onChange('price', int.tryParse(v)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dateField(
                      label: 'Start Date *',
                      controller: _startDate,
                      onPicked: (v) => _onChange('start_date', v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dateField(
                      label: 'End Date (optional)',
                      controller: _endDate,
                      onPicked: (v) => _onChange('end_date', v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _dropdown<String>(
                label: 'Furnished Status *',
                value: _furnished,
                items: _furnishedOptions.toList(),
                onChanged: (v) {
                  setState(() => _furnished = v);
                  _onChange('furnished', v);
                },
              ),
              const SizedBox(height: 24),

              // About you
              _SectionHeader('About You'),
              _field(
                label: 'About you as the lister *',
                hint: 'Tell potential tenants about yourself, your lifestyle, interests...',
                controller: _aboutLister,
                maxLines: 3,
                onChanged: (v) => _onChange('about_lister', v),
              ),
              const SizedBox(height: 12),
              _dropdown<String>(
                label: 'Your relationship to this space *',
                value: _listerRelationship,
                items: _relationships.toList(),
                onChanged: (v) {
                  setState(() => _listerRelationship = v);
                  _onChange('lister_relationship', v);
                },
              ),
              const SizedBox(height: 24),

              // Requirements
              _SectionHeader('Rental Requirements'),
              _field(
                label: 'Requirements for potential tenants *',
                hint: 'What are you looking for in a tenant?',
                controller: _rentalRequirements,
                maxLines: 4,
                onChanged: (v) => _onChange('rental_requirements', v),
              ),
              const SizedBox(height: 12),
              _field(
                label: 'Pet policy *',
                hint: 'e.g. No pets, Cats ok, Dogs with approval',
                controller: _petPolicy,
                maxLines: 2,
                onChanged: (v) => _onChange('pet_policy', v),
              ),
              const SizedBox(height: 24),

              // Photos
              _SectionHeader('Photos'),
              _PhotoSection(
                photos: _photos,
                uploading: _uploadingPhotos,
                onAdd: _pickAndUploadPhotos,
                onDelete: _deletePhoto,
              ),
              const SizedBox(height: 24),

              // Additional options
              _SectionHeader('Additional Options'),
              SwitchListTile(
                title: const Text('Seeking a roommate (not just a tenant)'),
                value: _seekingRoommate,
                onChanged: (v) {
                  setState(() => _seekingRoommate = v);
                  _onChange('seeking_roommate', v);
                },
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: const Text('Include phone number in listing'),
                value: _includePhone,
                onChanged: (v) {
                  setState(() => _includePhone = v);
                  _onChange('include_phone', v);
                },
                contentPadding: EdgeInsets.zero,
              ),
              if (_includePhone) ...[
                const SizedBox(height: 8),
                _field(
                  label: 'Phone Number',
                  hint: '(555) 123-4567',
                  controller: _phoneNumber,
                  keyboardType: TextInputType.phone,
                  onChanged: (v) => _onChange('phone_number', v),
                ),
              ],
              const SizedBox(height: 32),

              // Actions
              Row(
                children: [
                  FilledButton(
                    onPressed: _previewOrSaveFirst,
                    child: const Text('Preview listing'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => context.go('/dashboard'),
                    child: const Text('Save & exit'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Small builders ------------------------------------------------------

  Widget _field({
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
        Text(label,
            style:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            border: const OutlineInputBorder(),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<(T, String)> items,
    required void Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          key: ValueKey(value),
          initialValue: value,
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('Select...')),
            ...items.map((pair) =>
                DropdownMenuItem(value: pair.$1, child: Text(pair.$2))),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _dateField({
    required String label,
    required TextEditingController controller,
    required void Function(String?) onPicked,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          readOnly: true,
          decoration: const InputDecoration(
            hintText: 'YYYY-MM-DD',
            isDense: true,
            border: OutlineInputBorder(),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
}

// ---------------------------------------------------------------------------
// Photo section
// ---------------------------------------------------------------------------

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({
    required this.photos,
    required this.uploading,
    required this.onAdd,
    required this.onDelete,
  });

  final List<ListingPhoto> photos;
  final bool uploading;
  final VoidCallback onAdd;
  final void Function(ListingPhoto) onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (photos.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: photos.map((p) => _PhotoThumb(photo: p, onDelete: onDelete)).toList(),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: uploading || photos.length >= 10 ? null : onAdd,
              icon: uploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.add_photo_alternate_outlined),
              label: Text(uploading ? 'Uploading...' : 'Add photos'),
            ),
            const SizedBox(width: 12),
            Text(
              '${photos.length}/10 photos',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.photo, required this.onDelete});

  final ListingPhoto photo;
  final void Function(ListingPhoto) onDelete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            photo.url,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) => Container(
              width: 80,
              height: 80,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: () => onDelete(photo),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 13, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const Divider(),
        const SizedBox(height: 12),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Save status indicator
// ---------------------------------------------------------------------------

enum _SaveStatus { idle, saving, saved, error }

class _SaveIndicator extends StatelessWidget {
  const _SaveIndicator(this.status);
  final _SaveStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      _SaveStatus.idle => const SizedBox.shrink(),
      _SaveStatus.saving => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 6),
            Text('Saving…',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
          ],
        ),
      _SaveStatus.saved => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, size: 14,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 4),
            Text('Saved',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    )),
          ],
        ),
      _SaveStatus.error => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 14,
                color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 4),
            Text('Save failed',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    )),
          ],
        ),
    };
  }
}
