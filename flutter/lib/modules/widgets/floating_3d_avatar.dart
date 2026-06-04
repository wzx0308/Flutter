import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';

class Floating3dAvatar extends StatefulWidget {
  const Floating3dAvatar({super.key});

  @override
  State<Floating3dAvatar> createState() => _Floating3dAvatarState();
}

class _Floating3dAvatarState extends State<Floating3dAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  double _posX = 0;
  double _posY = 0;
  Offset _dragStart = Offset.zero;
  bool _didDrag = false;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (_posX == 0 && _posY == 0) {
      _posX = size.width - 110;
      _posY = size.height - 260;
    }

    return Positioned(
      left: _posX,
      top: _posY,
      child: Listener(
        onPointerDown: (e) {
          _dragStart = e.position;
          _didDrag = false;
        },
        onPointerMove: (e) {
          if ((e.position - _dragStart).distance > 8) _didDrag = true;
          if (_didDrag) {
            setState(() {
              _posX += e.delta.dx;
              _posY += e.delta.dy;
              _posX = _posX.clamp(0.0, size.width - 100);
              _posY = _posY.clamp(0.0, size.height - 140);
            });
          }
        },
        onPointerUp: (_) {
          if (!_didDrag) {
            Get.toNamed(AppRoutes.aiChatList);
          } else {
            setState(() {
              _posX = (_posX + 50 > size.width / 2) ? size.width - 100 : 0;
            });
          }
        },
        child: AnimatedBuilder(
          animation: _floatAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -_floatAnimation.value),
              child: child,
            );
          },
          child: _buildAvatar(),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final isDark = Get.isDarkMode;

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFF8B7FD4) : const Color(0xFF2D2B55))
                .withValues(alpha: 0.35),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: ModelViewer(
          src: 'assets/3d/142e7b4c6bc7473cbf6ba80fd49eb7a3.glb',
          alt: 'AI Assistant',
          ar: false,
          arModes: const [],
          autoPlay: true,
          autoRotate: false,
          cameraOrbit: '0deg 75deg 2.5m',
          cameraTarget: '0m 0m 0m',
          cameraControls: false,
          disableTap: true,
          fieldOfView: '30deg',
          backgroundColor: Colors.transparent,
          shadowIntensity: 0,
          shadowSoftness: 0,
        ),
      ),
    );
  }
}
