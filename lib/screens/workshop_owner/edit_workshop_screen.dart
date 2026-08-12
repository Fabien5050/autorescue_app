import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_client.dart';
import '../../core/app_colors.dart';
import '../../models/day_hours.dart';
import '../../models/workshop_owner_profile.dart';
import '../../models/workshop_photo.dart';
import '../../models/workshop_service.dart';
import '../../services/workshop_api.dart';
import '../../widgets/floating_label_field.dart';
import '../../widgets/map_location_preview.dart';
import '../../widgets/photo_grid_tile.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_card.dart';
import '../../widgets/service_chip_group.dart';
import 'operating_hours_screen.dart';
import 'workshop_gallery_screen.dart';
import 'workshop_location_screen.dart';

/// "Edit Workshop Profile" — identity, contact, location, services,
/// operating hours and photos, all in one form, matching the structure of
/// the workshop registration screen this project already has.
class EditWorkshopScreen extends StatefulWidget {
  const EditWorkshopScreen({super.key});

  @override
  State<EditWorkshopScreen> createState() => _EditWorkshopScreenState();
}

class _EditWorkshopScreenState extends State<EditWorkshopScreen> {
  final WorkshopOwnerProfile _profile = demoWorkshopOwnerProfile;
  final ImagePicker _imagePicker = ImagePicker();

  late final TextEditingController _nameController = TextEditingController(text: _profile.name);
  late final TextEditingController _ownerController = TextEditingController(text: _profile.ownerName);
  late final TextEditingController _phoneController = TextEditingController(text: _profile.phone);
  late final TextEditingController _emailController = TextEditingController(text: _profile.email);
  late final TextEditingController _descriptionController = TextEditingController(text: _profile.description);
  late final TextEditingController _whatsappController = TextEditingController(text: _profile.whatsapp);
  late final TextEditingController _emergencyController = TextEditingController(text: _profile.emergencyContact);
  late final TextEditingController _addressController = TextEditingController(text: _profile.address);

  late double _latitude = _profile.latitude;
  late double _longitude = _profile.longitude;
  late final Set<String> _selectedServices =
      _profile.services.map((WorkshopService s) => s.name).toSet();
  bool _isSaving = false;

  void _showError(Object error) {
    final String message = error is ApiException ? error.message : 'Something went wrong';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    _whatsappController.dispose();
    _emergencyController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _updateLocation() async {
    final (double, double)? result = await Navigator.of(context).push<(double, double)>(
      MaterialPageRoute<(double, double)>(
        builder: (_) => WorkshopLocationScreen(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
          address: _addressController.text,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _latitude = result.$1;
      _longitude = result.$2;
    });
  }

  void _toggleService(String service) {
    setState(() {
      if (_selectedServices.contains(service)) {
        _selectedServices.remove(service);
      } else {
        _selectedServices.add(service);
      }
    });
  }

  Future<ImageSource?> _chooseImageSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (BuildContext sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primaryBlue),
              title: const Text('Take Photo'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primaryBlue),
              title: const Text('Choose from Device'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadPhoto(String category, {WorkshopPhotoItem? replacing}) async {
    final ImageSource? source = await _chooseImageSource();
    if (source == null || !mounted) return;
    final XFile? picked = await _imagePicker.pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted) return;
    final Uint8List bytes = await picked.readAsBytes();
    if (!mounted) return;

    try {
      if (replacing?.id != null) {
        await WorkshopApi.deletePhoto(replacing!.id!);
      }
      final WorkshopPhotoItem uploaded = await WorkshopApi.addPhoto(
        category: category,
        fileBytes: bytes,
        fileName: picked.name,
      )
        ..bytes = bytes;
      if (!mounted) return;
      setState(() {
        if (replacing != null) {
          final int index = _profile.photos.indexOf(replacing);
          if (index != -1) _profile.photos[index] = uploaded;
        } else {
          _profile.photos.add(uploaded);
        }
      });
    } on ApiException catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _fillPhotoSlot(WorkshopPhotoItem photo) => _uploadPhoto(photo.category, replacing: photo);

  Future<void> _addPhoto() => _uploadPhoto('Other');

  Future<void> _deletePhoto(WorkshopPhotoItem photo) async {
    if (photo.id == null) return;
    try {
      await WorkshopApi.deletePhoto(photo.id!);
      if (!mounted) return;
      setState(() {
        if (defaultPhotoCategories.contains(photo.category)) {
          photo
            ..bytes = null
            ..id = null
            ..photoUrl = null;
        } else {
          _profile.photos.remove(photo);
        }
      });
    } on ApiException catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      // Mutate `_profile.services` immediately after each call succeeds
      // (rather than only after the whole save completes) — if a later
      // step in this method throws and the user retries, the diff below
      // must see what's already been created/deleted, or a retry
      // re-creates services that already exist on the backend.
      for (final WorkshopService existing in List<WorkshopService>.of(_profile.services)) {
        if (!_selectedServices.contains(existing.name)) {
          await WorkshopApi.deleteService(existing.id!);
          _profile.services.remove(existing);
        }
      }
      final Set<String> existingNames = _profile.services.map((WorkshopService s) => s.name).toSet();
      for (final String name in _selectedServices) {
        if (!existingNames.contains(name)) {
          final WorkshopService created =
              await WorkshopApi.addService(name: name, description: 'Service offered by this workshop.');
          _profile.services.add(created);
        }
      }

      await WorkshopApi.updateProfile(
        name: _nameController.text.trim().isEmpty ? _profile.name : _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        phone: _phoneController.text.trim(),
        whatsapp: _whatsappController.text.trim(),
        emergencyContact: _emergencyController.text.trim(),
        address: _addressController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        open24Hours: _profile.open24Hours,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.accentGreen,
          content: Text('Workshop profile updated successfully.'),
        ),
      );
      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.primaryText,
        title: const Text('Edit Workshop Profile', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SectionCard(
                icon: Icons.storefront_outlined,
                title: 'Workshop Identity',
                iconColor: AppColors.primaryBlue,
                children: <Widget>[
                  FloatingLabelField(label: 'Workshop Name', controller: _nameController, accentColor: AppColors.primaryBlue),
                  FloatingLabelField(
                    label: 'Owner Name',
                    controller: _ownerController,
                    accentColor: AppColors.primaryBlue,
                    enabled: false,
                  ),
                  FloatingLabelField(
                    label: 'Phone Number',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    accentColor: AppColors.primaryBlue,
                  ),
                  FloatingLabelField(
                    label: 'Email Address',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    accentColor: AppColors.primaryBlue,
                    enabled: false,
                  ),
                  FloatingLabelField(
                    label: 'Description',
                    controller: _descriptionController,
                    accentColor: AppColors.primaryBlue,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SectionCard(
                icon: Icons.call_outlined,
                title: 'Workshop Contact',
                iconColor: AppColors.secondaryCyan,
                children: <Widget>[
                  FloatingLabelField(
                    label: 'Primary Phone',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    accentColor: AppColors.secondaryCyan,
                  ),
                  FloatingLabelField(
                    label: 'WhatsApp Number',
                    controller: _whatsappController,
                    keyboardType: TextInputType.phone,
                    accentColor: AppColors.secondaryCyan,
                  ),
                  FloatingLabelField(
                    label: 'Emergency Contact',
                    controller: _emergencyController,
                    keyboardType: TextInputType.phone,
                    accentColor: AppColors.secondaryCyan,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SectionCard(
                icon: Icons.place_outlined,
                title: 'Workshop Location',
                iconColor: AppColors.dangerRed,
                children: <Widget>[
                  FloatingLabelField(
                    label: 'Address',
                    controller: _addressController,
                    accentColor: AppColors.dangerRed,
                  ),
                  MapLocationPreview(
                    latitude: _latitude,
                    longitude: _longitude,
                    onSetLocation: _updateLocation,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SectionCard(
                icon: Icons.miscellaneous_services_outlined,
                title: 'Workshop Services',
                iconColor: AppColors.primaryBlue,
                children: <Widget>[
                  ServiceChipGroup(
                    options: <String>[for (final (String name, IconData _) in workshopServiceCatalogue) name],
                    selected: _selectedServices,
                    onChanged: _toggleService,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SectionCard(
                icon: Icons.schedule_outlined,
                title: 'Operating Hours',
                iconColor: AppColors.warningOrange,
                children: <Widget>[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Open 24 Hours', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
                    value: _profile.open24Hours,
                    activeTrackColor: AppColors.accentGreen,
                    onChanged: (bool value) => setState(() => _profile.open24Hours = value),
                  ),
                  if (!_profile.open24Hours)
                    for (final DayHours day in _profile.operatingHours)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(day.day, style: const TextStyle(fontSize: 13, color: AppColors.primaryText)),
                            Text(
                              day.label(context),
                              style: const TextStyle(fontSize: 12.5, color: AppColors.secondaryText),
                            ),
                          ],
                        ),
                      ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const OperatingHoursScreen()),
                    ),
                    icon: const Icon(Icons.edit_calendar_outlined, size: 16, color: AppColors.warningOrange),
                    label: const Text('Edit Full Schedule'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.warningOrange,
                      side: const BorderSide(color: AppColors.warningOrange),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SectionCard(
                icon: Icons.photo_library_outlined,
                title: 'Workshop Photos',
                iconColor: AppColors.secondaryCyan,
                children: <Widget>[
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    children: <Widget>[
                      for (final WorkshopPhotoItem photo in _profile.photos)
                        PhotoGridTile(
                          photo: photo,
                          onTap: () => _fillPhotoSlot(photo),
                          onDelete: () => _deletePhoto(photo),
                        ),
                      AddPhotoTile(onTap: _addPhoto),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const WorkshopGalleryScreen()),
                    ),
                    icon: const Icon(Icons.open_in_full, size: 15, color: AppColors.secondaryCyan),
                    label: const Text('View Full Gallery'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.secondaryCyan),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              PrimaryButton(
                label: _isSaving ? 'Saving…' : 'Save Workshop Profile',
                trailingIcon: null,
                onPressed: _isSaving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
