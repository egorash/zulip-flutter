import 'package:flutter/material.dart';

class StickerCard extends StatelessWidget {
  final String assetPath;
  final double? size;
  const StickerCard({super.key, required this.assetPath, this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: size, width: size, child: Image.asset(assetPath));
  }
}
