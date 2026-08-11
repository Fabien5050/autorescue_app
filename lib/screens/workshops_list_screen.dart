import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/workshop.dart';
import '../widgets/stylized_map.dart';
import '../widgets/workshop_cards.dart';
import 'workshop_profile_screen.dart';

/// Workshops tab: full searchable directory plus a coverage-area overview.
class WorkshopsListScreen extends StatefulWidget {
  const WorkshopsListScreen({super.key, required this.onViewMap});

  final VoidCallback onViewMap;

  @override
  State<WorkshopsListScreen> createState() => _WorkshopsListScreenState();
}

class _WorkshopsListScreenState extends State<WorkshopsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Workshop> get _results {
    if (_query.trim().isEmpty) return sampleWorkshops;
    final String q = _query.trim().toLowerCase();
    return sampleWorkshops.where((Workshop w) {
      return w.name.toLowerCase().contains(q) ||
          w.town.toLowerCase().contains(q) ||
          w.services.any((String s) => s.toLowerCase().contains(q));
    }).toList();
  }

  void _openWorkshop(Workshop workshop) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => WorkshopProfileScreen(workshop: workshop)),
    );
  }

  void _call(Workshop workshop) {
    // Hook a real tel: launcher (e.g. url_launcher) in here.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.navy,
        behavior: SnackBarBehavior.floating,
        content: Text('Calling ${workshop.name}…'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Workshop> results = _results;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () {
                      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.arrow_back, color: AppColors.heading, size: 21),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Workshops',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.heading,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.tune, color: AppColors.primaryBlue, size: 20),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                children: <Widget>[
                  Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.search, size: 18, color: AppColors.slateLight),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (String v) => setState(() => _query = v),
                            style: const TextStyle(fontSize: 13.5, color: AppColors.heading),
                            decoration: const InputDecoration(
                              hintText: 'Search by service or town (e.g. Buea)',
                              hintStyle: TextStyle(fontSize: 13, color: AppColors.slateLight),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (results.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No workshops match your search.',
                        style: TextStyle(fontSize: 13, color: AppColors.slate),
                      ),
                    )
                  else
                    for (final Workshop w in results) ...<Widget>[
                      WorkshopListCard(
                        workshop: w,
                        onCall: () => _call(w),
                        onDetails: () => _openWorkshop(w),
                      ),
                      const SizedBox(height: 12),
                    ],
                  const SizedBox(height: 8),
                  _CoverageAreaCard(onViewMap: widget.onViewMap),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverageAreaCard extends StatelessWidget {
  const _CoverageAreaCard({required this.onViewMap});

  final VoidCallback onViewMap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Live Coverage Area',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.heading,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Currently serving South-West Region',
            style: TextStyle(fontSize: 11.5, color: AppColors.slate),
          ),
          const SizedBox(height: 10),
          Stack(
            alignment: Alignment.bottomCenter,
            children: <Widget>[
              StylizedMap(
                height: 130,
                pins: <MapPin>[
                  for (final Workshop w in sampleWorkshops)
                    MapPin(alignment: w.pinAlignment, size: 18, color: AppColors.navy),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: AppColors.heading,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: onViewMap,
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                      child: Text(
                        'View Map',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
