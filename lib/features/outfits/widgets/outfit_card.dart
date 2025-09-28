import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class _OutfitGarmentImage extends StatelessWidget {
  final String imageUrl;

  const _OutfitGarmentImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      ),
    );
  }
}

class OutfitCard extends StatelessWidget {
  final Map<String, dynamic> topData;
  final Map<String, dynamic> bottomData;
  final Map<String, dynamic> shoesData;

  const OutfitCard({
    super.key,
    required this.topData,
    required this.bottomData,
    required this.shoesData,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(child: _OutfitGarmentImage(imageUrl: topData['imageUrl'])),
            const SizedBox(height: 8),
            Expanded(
              child: _OutfitGarmentImage(imageUrl: bottomData['imageUrl']),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _OutfitGarmentImage(imageUrl: shoesData['imageUrl']),
            ),
          ],
        ),
      ),
    );
  }
}
