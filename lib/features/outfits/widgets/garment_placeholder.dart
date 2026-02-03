import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

class GarmentPlaceholder extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final String placeholderIconPath;
  final String? selectedGarmentUrl;
  final double iconSize;
  final BoxFit fit;
  final VoidCallback? onToggleFit;

  const GarmentPlaceholder({
    super.key,
    required this.label,
    required this.onTap,
    required this.placeholderIconPath,
    this.selectedGarmentUrl,
    this.iconSize = 70,
    this.fit = BoxFit.contain,
    this.onToggleFit,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DottedBorder(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            color: Colors.grey.withOpacity(0.05),
            child: selectedGarmentUrl != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: selectedGarmentUrl!,
                        fit: fit,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                      if (onToggleFit != null)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Material(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              onTap: onToggleFit,
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  fit == BoxFit.contain
                                      ? Icons.zoom_out_map
                                      : Icons.zoom_in_map,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  )
                : _PlaceholderContent(
                    iconPath: placeholderIconPath,
                    iconSize: iconSize,
                    label: label,
                  ),
          ),
        ),
      ),
    );
  }
}

// Widget interno para no repetir el contenido del placeholder
class _PlaceholderContent extends StatelessWidget {
  const _PlaceholderContent({
    required this.iconPath,
    required this.iconSize,
    required this.label,
  });

  final String iconPath;
  final double iconSize;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(iconPath, height: iconSize, color: Colors.grey.shade500),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
