import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/core/providers/theme_provider.dart';

class ThemeScreen extends ConsumerStatefulWidget {
  const ThemeScreen({super.key, required this.initialIsDarkTheme});

  final bool initialIsDarkTheme;

  @override
  ConsumerState<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends ConsumerState<ThemeScreen>
    with SingleTickerProviderStateMixin {
  bool isDarkTheme = true;
  late AnimationController _controller;
  late Animation<double> _sunAnimation;

  @override
  void initState() {
    super.initState();
    isDarkTheme = widget.initialIsDarkTheme;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _sunAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (!isDarkTheme) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleTheme() {
    _applyThemeSelection(!isDarkTheme);
  }

  void _applyThemeSelection(bool darkTheme) {
    setState(() {
      isDarkTheme = darkTheme;
      if (darkTheme) {
        _controller.reverse();
      } else {
        _controller.forward();
      }
    });

    ref.read(appThemeProvider.notifier).setDarkTheme(darkTheme);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkTheme ? backgroundColor : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDarkTheme ? whiteColor : backgroundColor,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _toggleTheme,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isDarkTheme
                            ? [
                                const Color(0xFF000000),
                                const Color(0xFF020024),
                                const Color.fromARGB(255, 0, 0, 75),
                              ]
                            : [
                                const Color(0xFF87CEEB),
                                const Color(0xFFFFD89B),
                              ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        if (isDarkTheme) ..._buildStars(),
                        Align(
                          alignment: Alignment(
                            0,
                            _sunAnimation.value * 2 - 0.3,
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: isDarkTheme ? _buildMoon() : _buildSun(),
                          ),
                        ),

                        if (!isDarkTheme) ..._buildClouds(),
                        Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Tap to change theme',
                                style: TextStyle(
                                  color: whiteColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
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
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Theme',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkTheme ? whiteColor : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildThemeOption(
                    icon: Icons.wb_sunny,
                    title: 'Light Theme',
                    isSelected: !isDarkTheme,
                    color: Colors.orange,
                    onTap: () => _applyThemeSelection(false),
                  ),
                  const SizedBox(height: 15),
                  _buildThemeOption(
                    icon: Icons.nightlight_round,
                    title: 'Dark Theme',
                    isSelected: isDarkTheme,
                    color: Colors.indigo,
                    onTap: () => _applyThemeSelection(true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSun() {
    return Container(
      key: const ValueKey('sun'),
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.yellow,
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.6),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Stack(
        children: List.generate(8, (index) {
          return Transform.rotate(
            angle: (index * 45) * 3.14159 / 180,
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 5),
                width: 3,
                height: 15,
                decoration: BoxDecoration(
                  color: Colors.yellow,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMoon() {
    return Container(
      key: const ValueKey('moon'),
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFECECEC), Color(0xFFBEBEBE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        boxShadow: [
          BoxShadow(color: Colors.white24, blurRadius: 20, spreadRadius: 5),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 20,
            left: 15,
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[400],
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: 35,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[400],
              ),
            ),
          ),
          Positioned(
            top: 35,
            right: 20,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[400],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStars() {
    return [
      _buildStar(0.2, 0.1, 2.0),
      _buildStar(0.8, 0.15, 1.5),
      _buildStar(0.1, 0.3, 1.8),
      _buildStar(0.9, 0.25, 2.2),
      _buildStar(0.3, 0.2, 1.5),
      _buildStar(0.7, 0.35, 1.7),
      _buildStar(0.15, 0.45, 2.0),
      _buildStar(0.85, 0.5, 1.8),
      _buildStar(0.4, 0.4, 1.6),
      _buildStar(0.6, 0.3, 2.0),
    ];
  }

  Widget _buildStar(double x, double y, double size) {
    return Positioned(
      left: MediaQuery.of(context).size.width * x,
      top: MediaQuery.of(context).size.height * y * 0.5,
      child: Icon(Icons.star, color: whiteColor, size: size),
    );
  }

  List<Widget> _buildClouds() {
    return [
      _buildCloud(0.1, 0.2, 60),
      _buildCloud(0.6, 0.15, 80),
      _buildCloud(0.3, 0.4, 70),
    ];
  }

  Widget _buildCloud(double x, double y, double size) {
    return Positioned(
      left: MediaQuery.of(context).size.width * x,
      top: MediaQuery.of(context).size.height * y * 0.5,
      child: Opacity(
        opacity: 0.7,
        child: Row(
          children: [
            Container(
              width: size * 0.5,
              height: size * 0.4,
              decoration: BoxDecoration(
                color: whiteColor,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: size * 0.6,
              height: size * 0.5,
              decoration: BoxDecoration(
                color: whiteColor,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: size * 0.5,
              height: size * 0.4,
              decoration: BoxDecoration(
                color: whiteColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required IconData icon,
    required String title,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkTheme ? color.withOpacity(0.2) : color.withOpacity(0.1))
              : (isDarkTheme ? Colors.grey[800] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? color
                  : (isDarkTheme ? Colors.grey : Colors.grey[600]),
              size: 30,
            ),
            const SizedBox(width: 15),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDarkTheme ? whiteColor : backgroundColor,
              ),
            ),
            const Spacer(),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }
}
