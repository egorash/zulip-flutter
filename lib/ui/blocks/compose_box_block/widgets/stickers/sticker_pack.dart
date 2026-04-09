import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../../../../model/sticker_pack_model.dart';
import 'sticker_card.dart';

class StickerPack extends StatefulWidget {
  final StickerPackModel model;
  final void Function(String stcikerId) onTap;
  const StickerPack({super.key, required this.onTap, required this.model});

  @override
  State<StickerPack> createState() => _StickerPackState();
}

class _StickerPackState extends State<StickerPack> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            widget.model.title,
            //style: AppText.h7.copyWith(color: AppColors.high),
          ),
        ),
        Expanded(
          child: GridView.builder(
            itemCount: widget.model.stickerIds.length,
            padding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 16,
            ).copyWith(bottom: 91),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 6.5,
            ),
            itemBuilder: (context, index) => GestureDetector(
              onTap: () {
                widget.onTap(widget.model.stickerIds[index]);
              },
              child: StickerCard(assetPath: widget.model.stickerIds[index]),
            ),
          ),
        ),
      ],
    );
  }
}
