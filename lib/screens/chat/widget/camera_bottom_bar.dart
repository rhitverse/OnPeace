import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:on_peace/colors.dart';

class CameraBottomBar extends StatelessWidget {
  final bool isTakingPhoto;
  final bool isSwitching;
  final Animation<double> shutterAnimation;
  final VoidCallback onShutterTap;
  final VoidCallback onFilterTap;
  final VoidCallback onFlipTap;

  const CameraBottomBar({
    super.key,
    required this.isTakingPhoto,
    required this.isSwitching,
    required this.shutterAnimation,
    required this.onShutterTap,
    required this.onFilterTap,
    required this.onFlipTap,
  });

  static const double barHeight = 100;
  static const double shutterSize = 80;
  static const double shutterRaise = 80;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: barHeight + shutterRaise,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  height: barHeight,
                  color: backgroundColor.withOpacity(0.2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 38),
                        child: GestureDetector(
                          onTap: onFilterTap,
                          child: SvgPicture.asset(
                            "assets/svg/filter.svg",
                            width: 38,
                            height: 38,
                          ),
                        ),
                      ),

                      const Spacer(),

                      Padding(
                        padding: const EdgeInsets.only(right: 28),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onFlipTap();
                          },
                          child: SvgPicture.asset(
                            'assets/svg/flip.svg',
                            width: 34,
                            height: 34,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          Positioned(
            bottom: barHeight - shutterRaise,
            child: GestureDetector(
              onTap: onShutterTap,
              child: ScaleTransition(
                scale: shutterAnimation,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: shutterSize,
                  height: shutterSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.18),
                    border: Border.all(color: whiteColor, width: 4.4),
                  ),

                  child: Center(
                    child: isTakingPhoto
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                        : AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(31),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
