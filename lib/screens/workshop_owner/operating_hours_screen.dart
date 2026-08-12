import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/app_colors.dart';
import '../../models/day_hours.dart';
import '../../models/workshop_owner_profile.dart';
import '../../services/workshop_api.dart';
import '../../widgets/operating_hours_row.dart';
import '../../widgets/primary_button.dart';

/// Dedicated weekly-schedule editor, reachable from the Edit Workshop
/// Profile screen.
class OperatingHoursScreen extends StatefulWidget {
  const OperatingHoursScreen({super.key});

  @override
  State<OperatingHoursScreen> createState() => _OperatingHoursScreenState();
}

class _OperatingHoursScreenState extends State<OperatingHoursScreen> {
  List<DayHours> get _hours => demoWorkshopOwnerProfile.operatingHours;
  bool get _open24Hours => demoWorkshopOwnerProfile.open24Hours;
  bool _isSaving = false;

  Future<void> _pickTime(DayHours day, {required bool isOpenTime}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isOpenTime ? day.openTime : day.closeTime,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isOpenTime) {
        day.openTime = picked;
      } else {
        day.closeTime = picked;
      }
    });
  }

  void _applyMondayToWeekdays() {
    final DayHours monday = _hours.first;
    setState(() {
      for (final DayHours day in _hours.sublist(1, 5)) {
        day.isOpen = monday.isOpen;
        day.openTime = monday.openTime;
        day.closeTime = monday.closeTime;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(behavior: SnackBarBehavior.floating, content: Text('Monday hours applied to Tue-Fri')),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await WorkshopApi.replaceHours(_hours);
      await WorkshopApi.updateProfile(
        name: demoWorkshopOwnerProfile.name,
        description: demoWorkshopOwnerProfile.description,
        phone: demoWorkshopOwnerProfile.phone,
        whatsapp: demoWorkshopOwnerProfile.whatsapp,
        emergencyContact: demoWorkshopOwnerProfile.emergencyContact,
        address: demoWorkshopOwnerProfile.address,
        latitude: demoWorkshopOwnerProfile.latitude,
        longitude: demoWorkshopOwnerProfile.longitude,
        open24Hours: demoWorkshopOwnerProfile.open24Hours,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(behavior: SnackBarBehavior.floating, content: Text('Operating hours saved')),
      );
      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          content: Text(error.message),
        ),
      );
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
        title: const Text('Operating Hours', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Open 24 Hours', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.primaryText)),
                value: _open24Hours,
                activeTrackColor: AppColors.accentGreen,
                onChanged: (bool value) => setState(() => demoWorkshopOwnerProfile.open24Hours = value),
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Apply Monday hours to all weekdays', style: TextStyle(fontSize: 13, color: AppColors.primaryText)),
              value: false,
              activeColor: AppColors.primaryBlue,
              onChanged: (_) => _applyMondayToWeekdays(),
            ),
            const SizedBox(height: 8),
            if (_open24Hours)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Your workshop is set to Open 24 Hours — daily times below are hidden.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.secondaryText),
                ),
              )
            else
              for (final DayHours day in _hours) ...<Widget>[
                OperatingHoursRow(
                  hours: day,
                  onToggleOpen: (bool value) => setState(() => day.isOpen = value),
                  onEditOpenTime: () => _pickTime(day, isOpenTime: true),
                  onEditCloseTime: () => _pickTime(day, isOpenTime: false),
                ),
                const SizedBox(height: 10),
              ],
            const SizedBox(height: 12),
            PrimaryButton(
              label: _isSaving ? 'Saving…' : 'Save Hours',
              onPressed: _isSaving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
