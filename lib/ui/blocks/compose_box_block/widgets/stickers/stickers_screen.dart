import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../get/controllers/stickers_controller.dart';
import '../../../../../get/services/store_service.dart';
import '../../../../../model/narrow.dart';
import 'sticker_card.dart';
import 'sticker_pack.dart';

class StickersScreen extends StatefulWidget {
  final Narrow narrow;
  const StickersScreen({super.key, required this.narrow});

  @override
  State<StickersScreen> createState() => StickersScreenState();
}

class StickersScreenState extends State<StickersScreen> {
  final _pageController = PageController(initialPage: 0);
  final RxInt _curPage = 1.obs;
  final RxBool _showBackArrow = false.obs;
  final _controller = Get.find<StickersController>();

  void showBackArrow() {
    _showBackArrow.value = true;
  }

  @override
  void initState() {
    super.initState();

    _pageController.addListener(() {
      if (_pageController.page != null &&
          _curPage.value != (_pageController.page! + 0.45).toInt()) {
        _curPage.value = (_pageController.page! + 0.45).toInt();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,

      body: PageView.builder(
        itemCount: _controller.myStickers.length,
        controller: _pageController,
        itemBuilder: (context, index) => StickerPack(
          model: _controller.myStickers[index],
          onTap: (stickerId) {
            final store = requirePerAccountStore();
            store.sendMessage(
              destination: (widget.narrow as SendableNarrow).destination,
              content: stickerId,
            );
            Get.back();
          },
        ),
      ),
      bottomNavigationBar: Container(
        height: 83,
        padding: const EdgeInsets.symmetric(
          vertical: 7,
          horizontal: 12,
        ).copyWith(bottom: 0),
        decoration: BoxDecoration(
          //color: AppColors.white.withOpacity(0.75),
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, -1),
              color: Color.fromRGBO(236, 235, 245, 0.75),
            ),
          ],
        ),
        alignment: Alignment.topCenter,
        child: ListView.builder(
          itemCount: _controller.myStickers.length,
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) => GestureDetector(
            onTap: () {
              _pageController.jumpToPage(index);
            },
            child: Container(
              height: 40,
              width: 58.5,
              alignment: Alignment.center,
              child: Obx(
                () => Container(
                  height: 32,
                  width: 32,
                  decoration: _curPage.value == index
                      ? BoxDecoration(
                          //color: AppColors.bezeledFill,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(12),
                          ).copyWith(bottomLeft: const Radius.circular(2)),
                        )
                      : null,
                  alignment: Alignment.center,
                  child: StickerCard(
                    assetPath: _controller.myStickers[index].stickerIds.first,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
