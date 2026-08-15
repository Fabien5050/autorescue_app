import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/app_colors.dart';
import '../models/vehicle.dart';
import '../services/vehicle_api.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/primary_button.dart';

/// The driver's own vehicle info — view mode by default, with an inline
/// edit mode, mirroring [DriverProfileScreen]'s pattern. Vehicles are
/// created once at registration; this is the only way to see or change
/// that afterward.
class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  late Future<Vehicle> _vehicleFuture;
  Vehicle? _vehicle;
  bool _isEditing = false;
  bool _isSaving = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _makeModelController = TextEditingController();
  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  String _category = vehicleCategories.first;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _makeModelController.dispose();
    _licensePlateController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  void _load() {
    _vehicleFuture = VehicleApi.getMine().then((Vehicle vehicle) {
      _vehicle = vehicle;
      _category = vehicleCategories.contains(vehicle.category) ? vehicle.category : vehicleCategories.first;
      _makeModelController.text = vehicle.makeModel;
      _licensePlateController.text = vehicle.licensePlate;
      _colorController.text = vehicle.color;
      return vehicle;
    });
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

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      final Vehicle updated = await VehicleApi.updateMine(
        category: _category,
        makeModel: _makeModelController.text.trim(),
        licensePlate: _licensePlateController.text.trim(),
        color: _colorController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _vehicle = updated;
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.accentGreen,
          behavior: SnackBarBehavior.floating,
          content: Text('Vehicle updated.'),
        ),
      );
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
        foregroundColor: AppColors.heading,
        title: const Text('My Vehicle', style: TextStyle(color: AppColors.heading, fontWeight: FontWeight.w800)),
        actions: <Widget>[
          if (!_isEditing && _vehicle != null)
            TextButton(
              onPressed: () => setState(() => _isEditing = true),
              child: const Text('Edit'),
            ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<Vehicle>(
          future: _vehicleFuture,
          builder: (BuildContext context, AsyncSnapshot<Vehicle> snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              final String message = snapshot.error is ApiException
                  ? (snapshot.error! as ApiException).message
                  : 'Failed to load your vehicle.';
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.slate)),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: () => setState(_load), child: const Text('Retry')),
                    ],
                  ),
                ),
              );
            }

            final Vehicle vehicle = _vehicle!;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: _isEditing ? _buildEditForm() : _buildView(vehicle),
            );
          },
        ),
      ),
    );
  }

  Widget _buildView(Vehicle vehicle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: AppColors.badgeSoft, shape: BoxShape.circle),
            child: const Icon(Icons.directions_car_filled, color: AppColors.primaryBlue, size: 34),
          ),
        ),
        const SizedBox(height: 20),
        _InfoRow(label: 'Category', value: vehicle.category),
        _InfoRow(label: 'Make & Model', value: vehicle.makeModel),
        _InfoRow(label: 'License Plate', value: vehicle.licensePlate),
        _InfoRow(label: 'Color', value: vehicle.color),
      ],
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Category',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _category,
            onChanged: (String? value) => setState(() => _category = value ?? _category),
            items: <DropdownMenuItem<String>>[
              for (final String category in vehicleCategories)
                DropdownMenuItem<String>(value: category, child: Text(category)),
            ],
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 16),
          LabeledTextField(
            label: 'Make & Model',
            hint: 'e.g. Toyota Corolla',
            controller: _makeModelController,
            validator: (String? v) => (v ?? '').trim().isEmpty ? 'Please enter the make and model' : null,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          LabeledTextField(
            label: 'License Plate',
            hint: 'e.g. SW 1234 AB',
            controller: _licensePlateController,
            validator: (String? v) => (v ?? '').trim().isEmpty ? 'Please enter the license plate' : null,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          LabeledTextField(
            label: 'Color',
            hint: 'e.g. Silver',
            controller: _colorController,
            validator: (String? v) => (v ?? '').trim().isEmpty ? 'Please enter the color' : null,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 22),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving
                      ? null
                      : () => setState(() {
                          _isEditing = false;
                          _category = vehicleCategories.contains(_vehicle!.category)
                              ? _vehicle!.category
                              : vehicleCategories.first;
                          _makeModelController.text = _vehicle!.makeModel;
                          _licensePlateController.text = _vehicle!.licensePlate;
                          _colorController.text = _vehicle!.color;
                        }),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: const BorderSide(color: AppColors.primaryBlue),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  label: _isSaving ? 'Saving…' : 'Save',
                  onPressed: _isSaving ? null : _save,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.slate)),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.heading),
          ),
        ],
      ),
    );
  }
}
