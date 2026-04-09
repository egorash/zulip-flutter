import 'package:get/get.dart';

import '../../model/sticker_pack_model.dart';

class StickersController extends GetxController {
  List<StickerPackModel> myStickers = [];
  List<int> lastestStickers = [];

  @override
  void onInit() {
    final stickers = <String>[];
    for (var i = 0; i < 12; i++) {
      stickers.add('assets/stickers/animals/$i.mp4');
    }
    myStickers.add(StickerPackModel(id: 0, title: 'Животинки', stickerIds: stickers));

    super.onInit();
  }
}
