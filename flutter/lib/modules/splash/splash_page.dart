import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'splash_controller.dart';

class SplashPage extends GetView<SplashController> {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2D2B55),
              Color(0xFF3D3B70),
              Color(0xFF4A4580),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              // Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                ),
                child: const Icon(
                  Icons.home_outlined,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 28),
              // App name
              const Text(
                '安隅',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  letterSpacing: 12,
                ),
              ),
              const SizedBox(height: 16),
              // Slogan
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  '世界偶尔荒凉，安隅\n让孤独有处安放',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                    height: 1.8,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const Spacer(flex: 3),
              // Loading indicator
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
