import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/admin_operations.dart';
import '../../services/admin_dashboard_api.dart';

class AdminFleetManagementScreen extends StatefulWidget {
  const AdminFleetManagementScreen({super.key});

  @override
  State<AdminFleetManagementScreen> createState() => _AdminFleetManagementScreenState();
}

class _AdminFleetManagementScreenState extends State<AdminFleetManagementScreen> {
  late Future<List<AdminVehicle>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() => _future = AdminDashboardApi.getFleet());

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Row(
              children: <Widget>[
                const Expanded(child: Text('Fleet Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.navy))),
                IconButton(onPressed: _load, tooltip: 'Refresh', icon: const Icon(Icons.refresh_rounded)),
              ],
            ),
          ),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Text('Registered driver vehicles', style: TextStyle(color: AppColors.slate))),
          Expanded(
            child: FutureBuilder<List<AdminVehicle>>(
              future: _future,
              builder: (BuildContext context, AsyncSnapshot<List<AdminVehicle>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return _ErrorState(message: snapshot.error.toString(), onRetry: _load);
                final List<AdminVehicle> vehicles = snapshot.data ?? <AdminVehicle>[];
                if (vehicles.isEmpty) return const Center(child: Text('No registered vehicles found.', style: TextStyle(color: AppColors.slate)));
                return ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: vehicles.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (BuildContext context, int index) {
                    final AdminVehicle vehicle = vehicles[index];
                    return Card(
                      elevation: 0,
                      color: AppColors.card,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        leading: const CircleAvatar(backgroundColor: AppColors.badgeSoft, child: Icon(Icons.directions_car_outlined, color: AppColors.primaryBlue)),
                        title: Text(vehicle.makeModel, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
                        subtitle: Text('${vehicle.driverName}  •  ${vehicle.driverPhone}\n${vehicle.category}  •  ${vehicle.color}', style: const TextStyle(height: 1.5, color: AppColors.slate)),
                        trailing: Text(vehicle.licensePlate, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryBlue)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.slate)), const SizedBox(height: 12), FilledButton(onPressed: onRetry, child: const Text('Retry'))]));
}
