import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng? selectedLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Location")),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(28.6139, 77.2090),
          initialZoom: 13,
          onTap: (tapPosition, point) {
            setState(() {
              selectedLocation = point;
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
          ),
          if (selectedLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: selectedLocation!,
                  width: 80,
                  height: 80,
                  child: const Icon(
                    Icons.location_on,
                    size: 40,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (selectedLocation != null) {
            print(selectedLocation!.latitude);
            print(selectedLocation!.longitude);
          }
        },
        child: const Icon(Icons.send),
      ),
    );
  }
}
