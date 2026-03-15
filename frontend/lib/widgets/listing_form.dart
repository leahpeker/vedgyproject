import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../models/listing.dart';
import '../models/listing_form_state.dart';
import '../providers/listing_actions_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/photo_provider.dart';
import '../services/api_client.dart';
import '../utils/logger.dart';
import '../utils/platform.dart';
import 'listing_form_fields.dart';
import 'listing_form_validators.dart';
import 'photo_section.dart';

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
  final _size = TextEditingController();
  final _transportation = TextEditingController();
  final _phoneNumber = TextEditingController();

  // ---- Form state (Freezed) ------------------------------------------------
  ListingFormState _fs = const ListingFormState();

  // ---- Auto-save internals (not in Freezed — mutable/non-serializable) -----
  Timer? _debounce;
  final Map<String, dynamic> _pendingChanges = {};

  @override
  void initState() {
    super.initState();
    final l = widget.initial;
    if (l != null) {
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
      _size.text = l.size ?? '';
      _transportation.text = l.transportation ?? '';
      _phoneNumber.text = l.phoneNumber ?? '';
      _fs = _fs.copyWith(
        listingId: l.id,
        city: l.city.isEmpty ? null : l.city,
        borough: l.borough,
        rentalType: l.rentalType.isEmpty ? null : l.rentalType,
        roomType: l.roomType.isEmpty ? null : l.roomType,
        veganHousehold: l.veganHousehold.isEmpty ? null : l.veganHousehold,
        furnished: l.furnished.isEmpty ? null : l.furnished,
        listerRelationship:
            l.listerRelationship.isEmpty ? null : l.listerRelationship,
        seekingRoommate: l.seekingRoommate,
        includePhone: l.includePhone,
        photos: List.of(l.photos),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [
      _title, _description, _neighborhood, _price, _startDate, _endDate,
      _aboutLister, _rentalRequirements, _petPolicy, _size, _transportation,
      _phoneNumber,
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
    if (_fs.firstSaveInProgress) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), _autoSave);
    setState(() => _fs = _fs.copyWith(saveStatus: SaveStatus.saving));
  }

  Future<void> _autoSave() async {
    if (_pendingChanges.isEmpty) return;

    final actions = ref.read(listingActionsProvider);

    if (_fs.listingId == null) {
      setState(() => _fs = _fs.copyWith(firstSaveInProgress: true));
      try {
        final created = await actions.createListing(Map.from(_pendingChanges));
        _pendingChanges.clear();
        if (mounted) {
          setState(() => _fs = _fs.copyWith(
                listingId: created.id,
                saveStatus: SaveStatus.saved,
                firstSaveInProgress: false,
              ));
        }
      } catch (_) {
        if (mounted) {
          setState(() => _fs = _fs.copyWith(
                saveStatus: SaveStatus.error,
                firstSaveInProgress: false,
              ));
        }
      }
    } else {
      try {
        await actions.updateListing(_fs.listingId!, Map.from(_pendingChanges));
        _pendingChanges.clear();
        if (mounted) {
          setState(() => _fs = _fs.copyWith(saveStatus: SaveStatus.saved));
        }
      } catch (_) {
        if (mounted) {
          setState(() => _fs = _fs.copyWith(saveStatus: SaveStatus.error));
        }
      }
    }
  }

  // ---- Photo handling ------------------------------------------------------

  Future<void> _pickAndUploadPhotos() async {
    if (_fs.listingId == null) {
      if (_fs.firstSaveInProgress) {
        ref.read(notificationQueueProvider.notifier)
            .show('Still saving your draft — please try again in a moment.');
        return;
      }
      _debounce?.cancel();
      setState(() => _fs = _fs.copyWith(
            firstSaveInProgress: true,
            saveStatus: SaveStatus.saving,
          ));
      try {
        final created = await ref
            .read(listingActionsProvider)
            .createListing(Map.from(_pendingChanges));
        _pendingChanges.clear();
        if (mounted) {
          setState(() => _fs = _fs.copyWith(
                listingId: created.id,
                saveStatus: SaveStatus.saved,
                firstSaveInProgress: false,
              ));
        }
      } catch (e) {
        if (mounted) {
          setState(() => _fs = _fs.copyWith(
                saveStatus: SaveStatus.error,
                firstSaveInProgress: false,
              ));
          ref.read(notificationQueueProvider.notifier).showError(
              'Could not save your draft. Check your connection and try again.');
        }
        return;
      }
    }

    final picker = ImagePicker();
    final remaining = 10 - _fs.photos.length;
    if (remaining <= 0) {
      ref.read(notificationQueueProvider.notifier)
          .show('Maximum 10 photos per listing.');
      return;
    }

    if (PlatformUtils.isMobile && mounted) {
      await showModalBottomSheet<void>(
        context: context,
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a photo'),
                onTap: () async {
                  Navigator.pop(context);
                  await _uploadFromCamera(picker, remaining);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  await _uploadFromGallery(picker, remaining);
                },
              ),
            ],
          ),
        ),
      );
    } else {
      await _uploadFromGallery(picker, remaining);
    }
  }

  Future<void> _uploadFromCamera(ImagePicker picker, int remaining) async {
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked == null) return;
    await _doPhotoUpload([picked], remaining);
  }

  Future<void> _uploadFromGallery(ImagePicker picker, int remaining) async {
    final picked = await picker.pickMultiImage(limit: remaining);
    if (picked.isEmpty) return;
    await _doPhotoUpload(picked, remaining);
  }

  Future<void> _doPhotoUpload(List<XFile> picked, int remaining) async {
    setState(() => _fs = _fs.copyWith(uploadingPhotos: true));
    try {
      final uploaded = await ref
          .read(photoActionsProvider)
          .uploadPhotos(_fs.listingId!, picked);
      setState(() => _fs = _fs.copyWith(
            photos: [..._fs.photos, ...uploaded],
            uploadingPhotos: false,
          ));
      ref.read(notificationQueueProvider.notifier)
          .show('${uploaded.length} photo${uploaded.length == 1 ? '' : 's'} uploaded.');
    } on DioException catch (e) {
      final inner = e.error;
      final msg = inner is ApiException
          ? inner.detail
          : 'Upload failed. Please try again.';
      log.warning(
          '[photo upload] DioException: ${e.type} | response: ${e.response?.statusCode} ${e.response?.data} | inner: $inner');
      ref.read(notificationQueueProvider.notifier).showError(msg);
      if (mounted) {
        setState(() => _fs = _fs.copyWith(uploadingPhotos: false));
      }
    } catch (e, st) {
      log.severe('[photo upload] unexpected error: $e', e, st);
      ref.read(notificationQueueProvider.notifier)
          .showError('Upload failed. Please try again.');
      if (mounted) {
        setState(() => _fs = _fs.copyWith(uploadingPhotos: false));
      }
    }
  }

  Future<void> _deletePhoto(ListingPhoto photo) async {
    try {
      await ref
          .read(photoActionsProvider)
          .deletePhoto(_fs.listingId!, photo.id);
      setState(() => _fs = _fs.copyWith(
            photos: _fs.photos.where((p) => p != photo).toList(),
          ));
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

  List<String> _validate() => validateListingForm(
        title: _title.text,
        city: _fs.city,
        price: _price.text,
        startDate: _startDate.text,
        endDate: _endDate.text,
      );

  // ---- Preview navigation --------------------------------------------------

  Future<void> _previewOrSaveFirst() async {
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

    if (_fs.photos.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tip: listings with photos get more interest.'),
          duration: Duration(seconds: 3),
        ),
      );
    }

    _debounce?.cancel();
    if (_pendingChanges.isNotEmpty || _fs.listingId == null) {
      await _autoSave();
    }
    if (_fs.listingId != null && mounted) {
      context.go('/preview/${_fs.listingId}');
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
                  _SaveIndicator(_fs.saveStatus),
                ],
              ),
              const SizedBox(height: 24),
              const SectionHeader('Basic Information'),
              buildFormField(label: 'Title *', hint: 'Cozy room in vegan-friendly house', controller: _title, onChanged: (v) => _onChange('title', v)),
              const SizedBox(height: 12),
              buildFormField(label: 'Description *', hint: 'Describe your space, lifestyle, and what you\'re looking for...', controller: _description, maxLines: 4, onChanged: (v) => _onChange('description', v)),
              const SizedBox(height: 24),
              const SectionHeader('Location'),
              buildFormDropdown<String>(label: 'City *', value: _fs.city, items: listingCities.map((c) => (c, c)).toList(), onChanged: (v) { setState(() { _fs = _fs.copyWith(city: v); if (v != 'New York') _fs = _fs.copyWith(borough: null); }); _onChange('city', v); if (v != 'New York') _onChange('borough', null); }),
              if (_fs.city == 'New York') ...[
                const SizedBox(height: 12),
                buildFormDropdown<String>(label: 'Borough *', value: _fs.borough, items: listingBoroughs.map((b) => (b, b)).toList(), onChanged: (v) { setState(() => _fs = _fs.copyWith(borough: v)); _onChange('borough', v); }),
              ],
              const SizedBox(height: 12),
              buildFormField(label: 'Neighborhood', hint: 'e.g. Williamsburg, Silver Lake, Wicker Park', controller: _neighborhood, onChanged: (v) => _onChange('neighborhood', v)),
              const SizedBox(height: 24),
              const SectionHeader('Rental Details'),
              buildFormDropdown<String>(label: 'Vegan Household *', value: _fs.veganHousehold, items: listingVeganHouseholds.toList(), onChanged: (v) { setState(() => _fs = _fs.copyWith(veganHousehold: v)); _onChange('vegan_household', v); }),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: buildFormDropdown<String>(label: 'Rental Type *', value: _fs.rentalType, items: listingRentalTypes.toList(), onChanged: (v) { setState(() => _fs = _fs.copyWith(rentalType: v)); _onChange('rental_type', v); })),
                const SizedBox(width: 12),
                Expanded(child: buildFormDropdown<String>(label: 'Room Type *', value: _fs.roomType, items: listingRoomTypes.toList(), onChanged: (v) { setState(() => _fs = _fs.copyWith(roomType: v)); _onChange('room_type', v); })),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: buildFormField(label: 'Monthly Rent (\$) *', hint: '1200', controller: _price, keyboardType: TextInputType.number, onChanged: (v) => _onChange('price', int.tryParse(v)))),
                const SizedBox(width: 12),
                Expanded(child: buildFormDateField(label: 'Start Date *', controller: _startDate, onPicked: (v) => _onChange('start_date', v), context: context)),
                const SizedBox(width: 12),
                Expanded(child: buildFormDateField(label: 'End Date (optional)', controller: _endDate, onPicked: (v) => _onChange('end_date', v), context: context)),
              ]),
              const SizedBox(height: 12),
              buildFormDropdown<String>(label: 'Furnished Status *', value: _fs.furnished, items: listingFurnishedOptions.toList(), onChanged: (v) { setState(() => _fs = _fs.copyWith(furnished: v)); _onChange('furnished', v); }),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: buildFormField(label: 'Size (optional)', hint: 'e.g. 12x10 feet, 200 sq ft', controller: _size, onChanged: (v) => _onChange('size', v))),
                const SizedBox(width: 12),
                Expanded(child: buildFormField(label: 'Transportation (optional)', hint: 'e.g. Near L train, Bus route 42', controller: _transportation, onChanged: (v) => _onChange('transportation', v))),
              ]),
              const SizedBox(height: 24),
              const SectionHeader('About You'),
              buildFormField(label: 'About you as the lister *', hint: 'Tell potential tenants about yourself, your lifestyle, interests...', controller: _aboutLister, maxLines: 3, onChanged: (v) => _onChange('about_lister', v)),
              const SizedBox(height: 12),
              buildFormDropdown<String>(label: 'Your relationship to this space *', value: _fs.listerRelationship, items: listingRelationships.toList(), onChanged: (v) { setState(() => _fs = _fs.copyWith(listerRelationship: v)); _onChange('lister_relationship', v); }),
              const SizedBox(height: 24),
              const SectionHeader('Rental Requirements'),
              buildFormField(label: 'Requirements for potential tenants *', hint: 'What are you looking for in a tenant?', controller: _rentalRequirements, maxLines: 4, onChanged: (v) => _onChange('rental_requirements', v)),
              const SizedBox(height: 12),
              buildFormField(label: 'Pet policy *', hint: 'e.g. No pets, Cats ok, Dogs with approval', controller: _petPolicy, maxLines: 2, onChanged: (v) => _onChange('pet_policy', v)),
              const SizedBox(height: 24),
              const SectionHeader('Photos'),
              PhotoSection(photos: _fs.photos, uploading: _fs.uploadingPhotos, onAdd: _pickAndUploadPhotos, onDelete: _deletePhoto),
              const SizedBox(height: 24),
              const SectionHeader('Additional Options'),
              SwitchListTile(title: const Text('Seeking a roommate (not just a tenant)'), value: _fs.seekingRoommate, onChanged: (v) { setState(() => _fs = _fs.copyWith(seekingRoommate: v)); _onChange('seeking_roommate', v); }, contentPadding: EdgeInsets.zero),
              SwitchListTile(title: const Text('Include phone number in listing'), value: _fs.includePhone, onChanged: (v) { setState(() => _fs = _fs.copyWith(includePhone: v)); _onChange('include_phone', v); }, contentPadding: EdgeInsets.zero),
              if (_fs.includePhone) ...[
                const SizedBox(height: 8),
                buildFormField(label: 'Phone Number', hint: '(555) 123-4567', controller: _phoneNumber, keyboardType: TextInputType.phone, onChanged: (v) => _onChange('phone_number', v)),
              ],
              const SizedBox(height: 32),
              Row(children: [
                FilledButton(onPressed: _previewOrSaveFirst, child: const Text('Preview listing')),
                const SizedBox(width: 12),
                OutlinedButton(onPressed: () => context.go('/dashboard'), child: const Text('Save & exit')),
              ]),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Save status indicator
// ---------------------------------------------------------------------------

class _SaveIndicator extends StatelessWidget {
  const _SaveIndicator(this.status);
  final SaveStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      SaveStatus.idle => const SizedBox.shrink(),
      SaveStatus.saving => Row(
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
      SaveStatus.saved => Row(
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
      SaveStatus.error => Row(
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
