import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({
    super.key,
    required this.initialTarget,
    required this.markers,
    this.initialZoom = 15,
    this.myLocationEnabled = false,
    this.myLocationButtonEnabled = false,
    this.zoomControlsEnabled = false,
    this.mapType = MapType.normal,
    this.mapToolbarEnabled = true,
    this.buildingsEnabled = true,
    this.trafficEnabled = true,
    this.indoorViewEnabled = true,
    this.tiltGesturesEnabled = true,
    this.rotateGesturesEnabled = true,
    this.onTap,
    this.onMapCreated,
  });

  final LatLng initialTarget;
  final Set<Marker> markers;
  final double initialZoom;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final bool zoomControlsEnabled;
  final MapType mapType;
  final bool mapToolbarEnabled;
  final bool buildingsEnabled;
  final bool trafficEnabled;
  final bool indoorViewEnabled;
  final bool tiltGesturesEnabled;
  final bool rotateGesturesEnabled;
  final ValueChanged<LatLng>? onTap;
  final ValueChanged<GoogleMapController>? onMapCreated;

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      mapType: mapType,
      initialCameraPosition: CameraPosition(
        target: initialTarget,
        zoom: initialZoom,
      ),
      markers: markers,
      myLocationEnabled: myLocationEnabled,
      myLocationButtonEnabled: myLocationButtonEnabled,
      zoomControlsEnabled: zoomControlsEnabled,
      buildingsEnabled: buildingsEnabled,
      trafficEnabled: trafficEnabled,
      indoorViewEnabled: indoorViewEnabled,
      tiltGesturesEnabled: tiltGesturesEnabled,
      rotateGesturesEnabled: rotateGesturesEnabled,
      compassEnabled: true,
      mapToolbarEnabled: mapToolbarEnabled,
      onTap: onTap,
      onMapCreated: onMapCreated,
    );
  }
}
