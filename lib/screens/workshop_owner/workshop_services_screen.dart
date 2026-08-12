import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/app_colors.dart';
import '../../models/workshop_owner_profile.dart';
import '../../models/workshop_service.dart';
import '../../services/workshop_api.dart';
import '../../widgets/service_management_card.dart';

/// "Services Offered" management screen: list, toggle, edit, delete, and
/// add services for the signed-in workshop.
class WorkshopServicesScreen extends StatefulWidget {
  const WorkshopServicesScreen({super.key});

  @override
  State<WorkshopServicesScreen> createState() => _WorkshopServicesScreenState();
}

class _WorkshopServicesScreenState extends State<WorkshopServicesScreen> {
  List<WorkshopService> get _services => demoWorkshopOwnerProfile.services;

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

  Future<void> _addService() async {
    final Set<String> existingNames = _services.map((WorkshopService s) => s.name).toSet();
    final List<(String, IconData)> available =
        workshopServiceCatalogue.where(((String, IconData) entry) => !existingNames.contains(entry.$1)).toList();

    final (String, IconData)? picked = await showModalBottomSheet<(String, IconData)>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (BuildContext sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Add Service', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primaryText)),
              ),
            ),
            if (available.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('All catalogue services have been added.', style: TextStyle(color: AppColors.secondaryText)),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    for (final (String, IconData) entry in available)
                      ListTile(
                        leading: Icon(entry.$2, color: AppColors.primaryBlue),
                        title: Text(entry.$1),
                        onTap: () => Navigator.of(sheetContext).pop(entry),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;

    try {
      final WorkshopService created = await WorkshopApi.addService(
        name: picked.$1,
        description: 'Service offered by this workshop.',
      );
      if (mounted) setState(() => _services.add(created));
    } on ApiException catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _editService(WorkshopService service) async {
    final TextEditingController descriptionController = TextEditingController(text: service.description);
    final TextEditingController priceController = TextEditingController(text: service.price ?? '');

    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(service.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price (optional)', hintText: 'From 5,000 FCFA'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true || !mounted) return;

    final String newDescription = descriptionController.text.trim().isEmpty
        ? service.description
        : descriptionController.text.trim();
    final String? newPrice = priceController.text.trim().isEmpty ? null : priceController.text.trim();

    try {
      final WorkshopService updated = await WorkshopApi.updateService(
        serviceId: service.id!,
        name: service.name,
        description: newDescription,
        price: newPrice,
        available: service.available,
      );
      if (!mounted) return;
      setState(() {
        final int index = _services.indexOf(service);
        if (index != -1) _services[index] = updated;
      });
    } on ApiException catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _setAvailable(WorkshopService service, bool value) async {
    try {
      final WorkshopService updated = await WorkshopApi.updateService(
        serviceId: service.id!,
        name: service.name,
        description: service.description,
        price: service.price,
        available: value,
      );
      if (!mounted) return;
      setState(() {
        final int index = _services.indexOf(service);
        if (index != -1) _services[index] = updated;
      });
    } on ApiException catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _deleteService(WorkshopService service) async {
    try {
      await WorkshopApi.deleteService(service.id!);
      if (mounted) setState(() => _services.remove(service));
    } on ApiException catch (error) {
      if (mounted) _showError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addService,
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Service', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Text(
                'Services Offered',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primaryText),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 4, 18, 0),
              child: Text(
                'Manage the services your workshop provides.',
                style: TextStyle(fontSize: 12.5, color: AppColors.secondaryText),
              ),
            ),
            Expanded(
              child: _services.isEmpty
                  ? const Center(
                      child: Text('No services added yet.', style: TextStyle(color: AppColors.secondaryText)),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 90),
                      itemCount: _services.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (BuildContext context, int index) {
                        final WorkshopService service = _services[index];
                        return ServiceManagementCard(
                          service: service,
                          onAvailabilityChanged: (bool value) => _setAvailable(service, value),
                          onEdit: () => _editService(service),
                          onDelete: () => _deleteService(service),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
