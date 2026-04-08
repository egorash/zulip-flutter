// ignore_for_file: unawaited_futures

import 'package:flutter/material.dart';

import '../../../../../native_sticker/native_sticker.dart';

class StickerCard extends StatefulWidget {
  final String assetPath;
  final double? size;
  const StickerCard({super.key, required this.assetPath, this.size});

  @override
  State<StickerCard> createState() => _StickerCardState();
}

class _StickerCardState extends State<StickerCard> {
  @override
  Widget build(BuildContext context) {
    return OptimizedNativeSticker(
      assetPath: widget.assetPath,
      size: widget.size,
      loop: true,
      errorWidget: SizedBox(
        height: widget.size,
        width: widget.size,
        child: Icon(
          Icons.broken_image_outlined,
          size: (widget.size ?? 100) * 0.4,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}
