// path: lib/views/location_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/location_controller.dart';

class LocationView extends GetView<LocationController> {
  const LocationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location (Live/GPS/Network)'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              final pos = controller.currentPosition.value;

              // Gunakan LatLng default jika posisi belum ada
              final center = pos != null
                  ? LatLng(pos.latitude, pos.longitude)
                  : const LatLng(-6.200000, 106.816666);

              return FlutterMap(
                mapController: controller.mapController,
                options: MapOptions(
                  // PERBAIKAN V7: Ganti center -> initialCenter
                  initialCenter: center,
                  // PERBAIKAN V7: Ganti zoom -> initialZoom
                  initialZoom: 15.0,
                  minZoom: 3.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.flutter_application',
                  ),
                  if (pos != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(pos.latitude, pos.longitude),
                          width: 40,
                          height: 40,
                          // PERBAIKAN V7: Ganti builder -> child
                          child: const Icon(
                            Icons.location_on,
                            size: 40,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                ],
              );
            }),
          ),

          // Info + Controls
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Obx(() {
              final p = controller.currentPosition.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p == null
                        ? 'Koordinat: - , Akurasi: -'
                        : 'Lat: ${p.latitude.toStringAsFixed(6)}, Lng: ${p.longitude.toStringAsFixed(6)} — acc: ${p.accuracy.toStringAsFixed(1)} m',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    // Ganti Row dengan Wrap agar tidak overflow di layar kecil
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : controller.refreshOnce,
                        child: controller.isLoading.value
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Refresh'),
                      ),
                      ElevatedButton(
                        onPressed: controller.isTracking.value
                            ? controller.stopTracking
                            : () => controller.startTracking(),
                        child: Text(
                          controller.isTracking.value
                              ? 'Stop Live'
                              : 'Start Live',
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: controller.isGpsEnabled.value,
                            onChanged: (v) => controller.toggleGpsMode(v),
                          ),
                          const Text('GPS'),
                        ],
                      ),
                      const SizedBox(width: 8),
                      const Text('Distance:'),
                      DropdownButton<int>(
                        value: controller.distanceFilter.value,
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('1m')),
                          DropdownMenuItem(value: 3, child: Text('3m')),
                          DropdownMenuItem(value: 5, child: Text('5m')),
                          DropdownMenuItem(value: 10, child: Text('10m')),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          controller.setDistanceFilter(v);
                        },
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
