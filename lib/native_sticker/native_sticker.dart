import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NativeStickerPlugin {
  static const MethodChannel _channel = MethodChannel('zulip_native_sticker');

  final int? textureId;

  NativeStickerPlugin() : textureId = null;

  Future<int> createTexture(String assetPath, int width, int height) async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'create',
        {'assetPath': assetPath, 'width': width, 'height': height},
      );

      if (result != null && result['textureId'] != null) {
        final textureIdValue = result['textureId'];
        if (textureIdValue is int) {
          return textureIdValue;
        } else if (textureIdValue is num) {
          return textureIdValue.toInt();
        }
        throw Exception(
          'Invalid textureId type: ${textureIdValue.runtimeType}',
        );
      }
      throw Exception('Failed to create native sticker texture');
    } on PlatformException catch (e) {
      throw Exception('Failed to create texture: ${e.message}');
    }
  }

  Future<void> destroyTexture(int textureId) async {
    await _channel.invokeMethod('destroy', {'textureId': textureId});
  }

  Future<void> play(int textureId) async {
    await _channel.invokeMethod('play', {'textureId': textureId});
  }

  Future<void> pause(int textureId) async {
    await _channel.invokeMethod('pause', {'textureId': textureId});
  }

  Future<void> setLooping(int textureId, bool loop) async {
    await _channel.invokeMethod('setLooping', {
      'textureId': textureId,
      'loop': loop,
    });
  }
}

class OptimizedNativeSticker extends StatefulWidget {
  final String assetPath;
  final double? size;
  final bool loop;
  final Widget? errorWidget;

  const OptimizedNativeSticker({
    super.key,
    required this.assetPath,
    this.size,
    this.loop = true,
    this.errorWidget,
  });

  @override
  State<OptimizedNativeSticker> createState() => _OptimizedNativeStickerState();
}

class _OptimizedNativeStickerState extends State<OptimizedNativeSticker> {
  int? _textureId;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isPlaying = true;
  bool _isVisible = true;
  int _frameCount = 0;
  final _plugin = NativeStickerPlugin();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSticker();
      _checkVisibility();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkVisibility();
  }

  void _checkVisibility() {
    final isVisible = _isActuallyVisible();
    if (isVisible != _isVisible) {
      setState(() => _isVisible = isVisible);
      _updatePlaybackState();
    }
  }

  bool _isActuallyVisible() {
    final renderObject = context.findRenderObject();
    if (renderObject == null || !renderObject.attached) return false;

    final box = renderObject as RenderBox;
    if (!box.hasSize) return false;

    final bounds = box.paintBounds;
    return bounds.width > 0 && bounds.height > 0;
  }

  void _updatePlaybackState() {
    if (_textureId == null) return;

    if (_isVisible && !_isPlaying) {
      _plugin.play(_textureId!);
      setState(() => _isPlaying = true);
    } else if (!_isVisible && _isPlaying) {
      _plugin.pause(_textureId!);
      setState(() => _isPlaying = false);
    }
  }

  Future<void> _initSticker() async {
    try {
      final size = widget.size ?? 100;
      final dpr = MediaQuery.devicePixelRatioOf(context);
      final scaledSize = (size * dpr).round();

      _textureId = await _plugin.createTexture(
        widget.assetPath,
        scaledSize,
        scaledSize,
      );

      if (widget.loop) {
        await _plugin.setLooping(_textureId!, true);
      }

      if (mounted) {
        setState(() => _isInitialized = true);
        _startFrameUpdater();
      }
    } catch (e) {
      debugPrint('Native sticker initialization failed: $e');
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  void _startFrameUpdater() {
    Future.doWhile(() async {
      if (!mounted || _textureId == null) return false;

      await Future.delayed(const Duration(milliseconds: 16));

      if (mounted && _textureId != null && _isVisible) {
        setState(() => _frameCount++);
        return true;
      }
      return false;
    });
  }

  @override
  void dispose() {
    if (_textureId != null) {
      _plugin.destroyTexture(_textureId!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorWidget ?? _buildPlaceholder();
    }

    if (!_isInitialized || _textureId == null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const _StickerShimmer(),
      );
    }

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      width: widget.size,
      height: widget.size,
      child: Texture(textureId: _textureId!),
    );
  }

  Widget _buildPlaceholder() {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Icon(
        Icons.broken_image_outlined,
        size: (widget.size ?? 100) * 0.4,
        color: Colors.grey[400],
      ),
    );
  }
}

class _StickerShimmer extends StatefulWidget {
  const _StickerShimmer();

  @override
  State<_StickerShimmer> createState() => _StickerShimmerState();
}

class _StickerShimmerState extends State<_StickerShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: const [Colors.black, Color(0xFF333333), Colors.black],
            ),
          ),
        );
      },
    );
  }
}

class OptimizedNativeStickerGrid extends StatelessWidget {
  final List<String> stickerPaths;
  final double itemSize;
  final int crossAxisCount;
  final void Function(String stickerPath)? onStickerTap;

  const OptimizedNativeStickerGrid({
    super.key,
    required this.stickerPaths,
    this.itemSize = 80,
    this.crossAxisCount = 4,
    this.onStickerTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: stickerPaths.length,
      itemBuilder: (context, index) {
        final path = stickerPaths[index];
        return OptimizedNativeSticker(
          key: ValueKey(path),
          assetPath: path,
          size: itemSize,
          loop: true,
        );
      },
    );
  }
}
