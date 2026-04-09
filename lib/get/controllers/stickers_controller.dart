import 'package:get/get.dart';

import '../../model/sticker_pack_model.dart';

class StickersController extends GetxController {
  List<StickerPackModel> myStickers = [];
  List<int> lastestStickers = [];

  @override
  void onInit() {
    final stickers = <String>[];
    for (var i = 0; i < 68; i++) {
      stickers.add('assets/stickers/animals_webp/$i.webp');
    }
    myStickers.add(
      StickerPackModel(id: 0, title: 'Животинки', stickerIds: stickers),
    );

    super.onInit();
  }
}
