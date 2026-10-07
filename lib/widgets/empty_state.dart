import 'package:flutter/material.dart';

import '../core/theme.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        builder: (context, v, child) => Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, 14 * (1 - v)), child: child),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 0, 40, 120),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 132,
                height: 132,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 132,
                      height: 118,
                      decoration: const BoxDecoration(
                        color: QN.peach,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(56),
                          topRight: Radius.circular(44),
                          bottomLeft: Radius.circular(42),
                          bottomRight: Radius.circular(60),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 6,
                      bottom: 8,
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: const BoxDecoration(
                            color: QN.softPink, shape: BoxShape.circle),
                      ),
                    ),
                    Icon(icon, size: 52, color: QN.ink),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 21, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
              const SizedBox(height: 8),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, height: 1.4, color: QN.soft(context))),
            ],
          ),
        ),
      ),
    );
  }
}
