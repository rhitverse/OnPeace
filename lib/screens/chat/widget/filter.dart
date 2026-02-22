import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraFilter {
  final String label;
  final ColorFilter? colorFilter;
  const CameraFilter(this.label, this.colorFilter);
}

final List<CameraFilter> cameraFilters = [
  const CameraFilter('Normal', null),
  CameraFilter(
    'B&W',
    const ColorFilter.matrix([
      0.2126,
      0.7152,
      0.0722,
      0,
      0,
      0.2126,
      0.7152,
      0.0722,
      0,
      0,
      0.2126,
      0.7152,
      0.0722,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]),
  ),
  CameraFilter(
    'Vivid',
    const ColorFilter.matrix([
      1.4,
      -0.2,
      -0.1,
      0,
      0,
      -0.1,
      1.3,
      -0.1,
      0,
      0,
      -0.1,
      -0.2,
      1.4,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]),
  ),
  CameraFilter(
    'Fade',
    const ColorFilter.matrix([
      1.0,
      0,
      0,
      0,
      40,
      0,
      1.0,
      0,
      0,
      40,
      0,
      0,
      1.0,
      0,
      40,
      0,
      0,
      0,
      1,
      0,
    ]),
  ),
  CameraFilter(
    'Drama',
    const ColorFilter.matrix([
      1.5,
      -0.3,
      -0.1,
      0,
      -10,
      -0.1,
      1.4,
      -0.2,
      0,
      -10,
      -0.1,
      -0.3,
      1.5,
      0,
      -10,
      0,
      0,
      0,
      1,
      0,
    ]),
  ),
];

class Filter extends StatelessWidget {
  final CameraFilter filter;
  final bool isSelected;
  final VoidCallback onTap;
  final CameraController? cameraController;
  const Filter({
    super.key,
    required this.filter,
    required this.isSelected,
    required this.onTap,
    this.cameraController,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.greenAccent : Colors.white38,
                width: isSelected ? 2.5 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.greenAccent.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _buildPreview(),
            ),
          ),
          const SizedBox(height: 6),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),

            style: TextStyle(
              color: isSelected ? Colors.greenAccent : Colors.white60,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              letterSpacing: 0.3,
            ),
            child: Text(filter.label),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (cameraController != null && cameraController!.value.isInitialized) {
      final preview = CameraPreview(cameraController!);
      if (filter.colorFilter != null) {
        return ColorFiltered(colorFilter: filter.colorFilter!, child: preview);
      }
      return preview;
    }
    return ColorFiltered(
      colorFilter:
          filter.colorFilter ??
          const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
      child: Container(
        color: const Color(0xFF4A6572),
        child: const Center(
          child: Icon(Icons.landscape, color: Colors.white38, size: 28),
        ),
      ),
    );
  }
}

class FilterBottomSheet extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onFilterSelected;
  final CameraController? camController;
  const FilterBottomSheet({
    super.key,
    required this.selectedIndex,
    required this.onFilterSelected,
    this.camController,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late int _currentIndex;
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: const BoxDecoration(
        color: Color(0xdd111111),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: cameraFilters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (_, i) {
                return Filter(
                  filter: cameraFilters[i],
                  isSelected: _currentIndex == i,
                  cameraController: widget.camController,
                  onTap: () {
                    setState(() => _currentIndex = i);
                    widget.onFilterSelected(i);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

void showFilterBottomSheet({
  required BuildContext context,
  required int selectedIndex,
  required ValueChanged<int> onFilterSelected,
  CameraController? camController,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => FilterBottomSheet(
      selectedIndex: selectedIndex,
      onFilterSelected: onFilterSelected,
      camController: camController,
    ),
  );
}
