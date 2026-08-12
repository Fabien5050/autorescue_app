import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_client.dart';
import '../../core/app_colors.dart';
import '../../models/workshop_owner_profile.dart';
import '../../models/workshop_photo.dart';
import '../../services/workshop_api.dart';
import '../../widgets/photo_grid_tile.dart';

/// "Workshop Gallery" — a modern 2-column photo grid the owner can fill
/// in from the camera or their device.
class WorkshopGalleryScreen extends StatefulWidget {
  const WorkshopGalleryScreen({super.key});

  @override
  State<WorkshopGalleryScreen> createState() => _WorkshopGalleryScreenState();
}

class _WorkshopGalleryScreenState extends State<WorkshopGalleryScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  List<WorkshopPhotoItem> get _photos => demoWorkshopOwnerProfile.photos;

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

  Future<void> _upload(String category, {WorkshopPhotoItem? replacing}) async {
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
          final int index = _photos.indexOf(replacing);
          if (index != -1) _photos[index] = uploaded;
        } else {
          _photos.add(uploaded);
        }
      });
    } on ApiException catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _fillSlot(WorkshopPhotoItem photo) => _upload(photo.category, replacing: photo);

  Future<void> _addNewSlot() => _upload('Other');

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
          _photos.remove(photo);
        }
      });
    } on ApiException catch (error) {
      if (mounted) _showError(error);
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
        title: const Text('Workshop Gallery', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
          children: <Widget>[
            const Text(
              'Show customers your workshop, equipment and services.',
              style: TextStyle(fontSize: 12.5, color: AppColors.secondaryText),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: <Widget>[
                for (final WorkshopPhotoItem photo in _photos)
                  PhotoGridTile(
                    photo: photo,
                    onTap: () => _fillSlot(photo),
                    onDelete: () => _deletePhoto(photo),
                  ),
                AddPhotoTile(onTap: _addNewSlot),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
