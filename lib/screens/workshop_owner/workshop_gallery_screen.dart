import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_colors.dart';
import '../../models/workshop_owner_profile.dart';
import '../../models/workshop_photo.dart';
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

  Future<void> _fillSlot(WorkshopPhotoItem photo) async {
    final ImageSource? source = await _chooseImageSource();
    if (source == null || !mounted) return;

    final XFile? picked = await _imagePicker.pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted) return;

    final Uint8List bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() => photo.bytes = bytes);
  }

  Future<void> _addNewSlot() async {
    final ImageSource? source = await _chooseImageSource();
    if (source == null || !mounted) return;

    final XFile? picked = await _imagePicker.pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted) return;

    final Uint8List bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() => _photos.add(WorkshopPhotoItem(category: 'Other', bytes: bytes)));
  }

  void _deletePhoto(WorkshopPhotoItem photo) {
    setState(() => photo.bytes = null);
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
