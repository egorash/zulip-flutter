import 'package:flutter/material.dart';

import '../utils/actions.dart';

class CustomSwipeTo extends StatefulWidget {
  final Widget child;

  final Duration animationDuration;
  final IconData iconOnLeftSwipe;
  final Widget? leftSwipeWidget;
  final VoidCallback onLeftSwipe;

  const CustomSwipeTo({
    super.key,
    required this.child,
    required this.onLeftSwipe,
    this.iconOnLeftSwipe = Icons.reply,
    this.leftSwipeWidget,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  CustomSwipeToState createState() => CustomSwipeToState();
}

class CustomSwipeToState extends State<CustomSwipeTo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Tween<double> _positionTween;
  Offset _currentOffset = Offset.zero;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _positionTween = Tween<double>(begin: 0.0, end: 0.0);
    _controller.addListener(() {
      setState(() {
        _currentOffset = Offset(_positionTween.transform(_controller.value), 0);
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateBack() {
    if (_controller.isAnimating) return;
    _isDragging = false;
    _positionTween = Tween<double>(begin: _currentOffset.dx, end: 0.0);
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (details) {
        if (_controller.isAnimating) return;
        _isDragging = true;
      },
      onHorizontalDragUpdate: (details) {
        if (!_isDragging || _controller.isAnimating) return;
        double newOffset = _currentOffset.dx + details.delta.dx / 500;
        newOffset = newOffset.clamp(-1.0, 1.0);
        setState(() {
          _currentOffset = Offset(newOffset, 0);
        });
        if (_currentOffset.dx < -0.2) {
          ZulipAction.triggerFeedback();
          widget.onLeftSwipe();
          _animateBack();
        }
      },
      onHorizontalDragEnd: (details) {
        if (!_isDragging) return;
        _animateBack();
      },
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.passthrough,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: AnimatedOpacity(
                opacity: _currentOffset.dx > 0
                    ? 0
                    : (_currentOffset.dx.abs() / 0.2).clamp(0, 1),
                duration: Duration(
                  milliseconds: widget.animationDuration.inMilliseconds ~/ 2,
                ),
                curve: Curves.decelerate,
                child:
                    widget.leftSwipeWidget ??
                    Icon(
                      widget.iconOnLeftSwipe,
                      size: 26,
                      color: Theme.of(context).iconTheme.color,
                    ),
              ),
            ),
          ),
          FractionalTranslation(
            translation: _currentOffset,
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
