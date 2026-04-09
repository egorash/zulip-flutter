// ignore_for_file: unawaited_futures

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class StickerCard extends StatefulWidget {
  final String assetPath;
  final double? size;
  const StickerCard({super.key, required this.assetPath, this.size});

  @override
  State<StickerCard> createState() => _StickerCardState();
}

class _StickerCardState extends State<StickerCard> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    _controller = VideoPlayerController.asset(widget.assetPath);
    try {
    await _controller.initialize();
    } catch (e) {
      log(e.toString());
    }

    if (mounted) {
      setState(() => _isInitialized = true);
    }

    _controller.setLooping(true);
    _controller.play();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return SizedBox(
        height: widget.size,
        width: widget.size,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      height: widget.size,
      width: widget.size,
      child: VideoPlayer(_controller),
    );
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _controller.dispose();
    }
    super.dispose();
  }
}
