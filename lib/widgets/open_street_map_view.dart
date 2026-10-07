import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

/// OpenStreetMap tile view shared by the app's maps and location previews.
class OpenStreetMapView extends StatelessWidget {
  const OpenStreetMapView({
    super.key,
    required this.center,
    this.zoom = 13,
    this.markers = const <Marker>[],
    this.interactive = true,
    this.onTap,
    this.mapController,
  });

  final LatLng center;
  final double zoom;
  final List<Marker> markers;
  final bool interactive;
  final void Function(TapPosition, LatLng)? onTap;
  final MapController? mapController;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        interactionOptions: InteractionOptions(
          flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
        ),
        onTap: onTap,
      ),
      children: <Widget>[
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.autorescue.autorescue_app',
          maxZoom: 19,
        ),
        MarkerLayer(markers: markers),
        RichAttributionWidget(
          attributions: <SourceAttribution>[
            TextSourceAttribution(
              'OpenStreetMap contributors',
              onTap: () async {
                await launchUrl(Uri.parse('https://www.openstreetmap.org/copyright'));
              },
            ),
          ],
        ),
      ],
    );
  }
}
