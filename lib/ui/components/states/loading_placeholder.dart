import 'package:flutter/material.dart';

enum LoadingStyle { circular, shimmer, skeleton }

class LoadingPlaceholder extends StatelessWidget {
  const LoadingPlaceholder({
    super.key,
    this.style = LoadingStyle.circular,
    this.message,
  });

  final LoadingStyle style;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: switch (style) {
        LoadingStyle.circular => _buildCircular(),
        LoadingStyle.shimmer => _buildShimmer(context),
        LoadingStyle.skeleton => _buildSkeleton(),
      },
    );
  }

  Widget _buildCircular() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        if (message != null) ...[const SizedBox(height: 16), Text(message!)],
      ],
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildSkeleton() {
    return const Center(child: CircularProgressIndicator());
  }
}

class LoadingListItem extends StatelessWidget {
  const LoadingListItem({
    super.key,
    this.height = 72,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  final double height;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: double.infinity,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 120,
                    color: Colors.grey.shade300,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoadingList extends StatelessWidget {
  const LoadingList({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) => const LoadingListItem(),
    );
  }
}
