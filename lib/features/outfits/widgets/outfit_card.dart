import 'package:armariovirtual/features/outfits/widgets/outfit_canvas.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:armariovirtual/features/outfits/screen/outfit_detail_screen.dart';
import 'package:flutter/material.dart';

class OutfitCard extends StatelessWidget {
  final String outfitId;
  final Map<String, dynamic> topData;
  final Map<String, dynamic> bottomData;
  final Map<String, dynamic> shoesData;
  final List<String> tags;
  final Map<String, dynamic>? layout;

  const OutfitCard({
    super.key,
    required this.outfitId,
    required this.topData,
    required this.bottomData,
    required this.shoesData,
    this.tags = const [],
    this.layout,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OutfitDetailScreen(
                outfitId: outfitId,
                outfitData: {
                  'topGarment': topData,
                  'bottomGarment': bottomData,
                  'shoesGarment': shoesData,
                  'tags': tags,
                  'layout': layout,
                },
              ),
            ),
          );
        },
        child: (layout != null && layout!.isNotEmpty)
            ? OutfitCanvas(
                topData: topData,
                bottomData: bottomData,
                shoesData: shoesData,
                initialLayout: layout,
                isEditing: false,
              )
            : Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: CachedNetworkImage(
                        imageUrl: topData['imageUrl'],
                        fit: BoxFit.contain,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: CachedNetworkImage(
                        imageUrl: bottomData['imageUrl'],
                        fit: BoxFit.contain,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: CachedNetworkImage(
                        imageUrl: shoesData['imageUrl'],
                        fit: BoxFit.contain,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
