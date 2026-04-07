import 'package:get/get.dart';

import '../../../../model/unreads.dart';
import '../../store_service.dart';

class UnreadsService extends GetxService {
  static UnreadsService get to => Get.find<UnreadsService>();

  final Rx<Unreads?> _unreads = Rx<Unreads?>(null);

  Unreads? get unreads => _unreads.value;

  void syncFromStore() {
    final oldUnreads = _unreads.value;
    if (oldUnreads != null) {
      oldUnreads.removeListener(_onUnreadsChanged);
    }

    _unreads.value = StoreService.to.store?.unreads;
    _unreads.value?.addListener(_onUnreadsChanged);
  }

  void _onUnreadsChanged() {
    _unreads.refresh();
  }

  void clear() {
    _unreads.value?.removeListener(_onUnreadsChanged);
    _unreads.value = null;
  }
}
