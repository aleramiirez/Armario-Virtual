import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonOutfitCard extends StatelessWidget {
  const SkeletonOutfitCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          children: [
            Expanded(flex: 2, child: Container(color: Colors.white)),
            const SizedBox(height: 2),
            Expanded(flex: 2, child: Container(color: Colors.white)),
            const SizedBox(height: 2),
            Expanded(flex: 1, child: Container(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
