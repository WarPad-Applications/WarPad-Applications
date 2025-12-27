import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/location_controller.dart';

class LocationView extends StatelessWidget {
  const LocationView({super.key});

  @override
  Widget build(BuildContext context) {
    // Pastikan LocationController sudah di-put (di binding atau di sini)
    final LocationController controller = Get.put(LocationController());

    return Scaffold(
      appBar: AppBar(title: const Text("Lokasi Warung"), centerTitle: true),
      body: Stack(
        children: [
          // 1. PETA
          Obx(() {
            final myPos = controller.currentPosition.value;
            // Pusat peta: Kalau user ada lokasi pakai user, kalau gak pakai warung
            final center = myPos != null
                ? LatLng(myPos.latitude, myPos.longitude)
                : controller.warungLocation;

            return FlutterMap(
              mapController: controller.mapController,
              options: MapOptions(initialCenter: center, initialZoom: 15.0),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.warpad.app',
                ),
                MarkerLayer(
                  markers: [
                    // MARKER WARUNG (TETAP)
                    Marker(
                      point: controller.warungLocation,
                      width: 80,
                      height: 80,
                      child: const Column(
                        children: [
                          Icon(Icons.store, color: Colors.red, size: 40),
                          Text(
                            "WarPad",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // MARKER USER (JIKA GPS NYALA)
                    if (myPos != null)
                      Marker(
                        point: LatLng(myPos.latitude, myPos.longitude),
                        width: 60,
                        height: 60,
                        child: const Icon(
                          Icons.person_pin_circle,
                          color: Colors.blue,
                          size: 40,
                        ),
                      ),
                  ],
                ),
                // GARIS PENGHUBUNG (OPSIONAL)
                if (myPos != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [
                          LatLng(myPos.latitude, myPos.longitude),
                          controller.warungLocation,
                        ],
                        strokeWidth: 3.0,
                        color: Colors.blueAccent,
                      ),
                    ],
                  ),
              ],
            );
          }),

          // 2. PANEL INFO BAWAH
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- BAGIAN ALAMAT DITAMBAHKAN DI SINI ---
                  const Text(
                    "Alamat WarPad:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Jl. Raya Bululawang No.45, Bululawang,\nKec. Bululawang, Kab. Malang, Jatim 65171",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 10),

                  // -----------------------------------------
                  const Text(
                    "Jarak Kamu ke WarPad",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 5),
                  Obx(
                    () => Text(
                      "${controller.distanceToWarung.value.toStringAsFixed(1)} KM",
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: controller.refreshOnce,
                    icon: const Icon(Icons.my_location),
                    label: const Text("Update Lokasi Saya"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
