import 'package:armariovirtual/features/outfits/widgets/draggable_resizable_garment.dart';
import 'package:flutter/material.dart';

class OutfitCanvas extends StatefulWidget {
  final Map<String, dynamic> topData;
  final Map<String, dynamic> bottomData;
  final Map<String, dynamic> shoesData;
  final Map<String, dynamic>? initialLayout;
  final bool isEditing;
  final Function(Map<String, dynamic>)? onLayoutChanged;

  const OutfitCanvas({
    super.key,
    required this.topData,
    required this.bottomData,
    required this.shoesData,
    this.initialLayout,
    this.isEditing = false,
    this.onLayoutChanged,
  });

  @override
  State<OutfitCanvas> createState() => _OutfitCanvasState();
}

class _OutfitCanvasState extends State<OutfitCanvas> {
  late Map<String, dynamic> _layout;

  @override
  void initState() {
    super.initState();
    _initializeLayout();
  }

  @override
  void didUpdateWidget(OutfitCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLayout != oldWidget.initialLayout) {
      _initializeLayout();
    }
  }

  void _initializeLayout() {
    if (widget.initialLayout != null && widget.initialLayout!.isNotEmpty) {
      _layout = Map<String, dynamic>.from(widget.initialLayout!);
    } else {
      // Default layout (vertical stack simulation)
      // Refined values for better initial appearance
      _layout = {
        'top': {'x': 0.5, 'y': 0.25, 'scale': 1.0, 'zIndex': 2},
        'bottom': {'x': 0.5, 'y': 0.60, 'scale': 1.0, 'zIndex': 1},
        'shoes': {'x': 0.5, 'y': 0.88, 'scale': 1.0, 'zIndex': 0},
      };
    }
    // Ensure zIndex exists for all items (migration for existing layouts)
    _layout.forEach((key, value) {
      if (!value.containsKey('zIndex')) {
        value['zIndex'] = 0;
      }
    });
  }

  void _updateGarmentLayout(
    String key,
    Offset position,
    double scale,
    Size size,
  ) {
    // Convert absolute position to relative (0.0 - 1.0)
    final relativeX = position.dx / size.width;
    final relativeY = position.dy / size.height;

    setState(() {
      _layout[key] = {
        ..._layout[key],
        'x': relativeX,
        'y': relativeY,
        'scale': scale,
      };
    });

    if (widget.onLayoutChanged != null) {
      widget.onLayoutChanged!(_layout);
    }
  }

  void _bringToFront(String key) {
    if (!widget.isEditing) return;

    // Find current max zIndex
    int maxZ = 0;
    _layout.forEach((k, v) {
      final int z = v['zIndex'] ?? 0;
      if (z > maxZ) maxZ = z;
    });

    // If already at top, do nothing
    // Removed optimization check because it fails when multiple items have the same maxZ
    // final int currentZ = _layout[key]['zIndex'] ?? 0;
    // if (currentZ == maxZ) return;

    setState(() {
      _layout[key]['zIndex'] = maxZ + 1;
    });

    if (widget.onLayoutChanged != null) {
      widget.onLayoutChanged!(_layout);
    }
  }

  Widget _buildGarment(String key, Map<String, dynamic> data, Size size) {
    final layoutData =
        _layout[key] ?? {'x': 0.5, 'y': 0.5, 'scale': 1.0, 'zIndex': 0};
    final double x = (layoutData['x'] as double) * size.width;
    final double y = (layoutData['y'] as double) * size.height;
    final double scale = (layoutData['scale'] as double);

    // Responsive base size: 55% of the container width (restored to larger size)
    final double baseSize = size.width * 0.55;

    // Centering adjustment: coordinates represent center of the image
    final double offset = (baseSize * scale) / 2;

    return Positioned(
      left: x - offset,
      top: y - offset,
      child: DraggableResizableGarment(
        imageUrl: data['imageUrl'],
        isEditing: widget.isEditing,
        initialScale: scale,
        initialPosition: Offset(x - offset, y - offset),
        baseSize: baseSize,
        onUpdate: (pos, s) =>
            _updateGarmentLayout(key, pos + Offset(offset, offset), s, size),
        onSelect: () => _bringToFront(key),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        // Sort keys by zIndex
        final sortedKeys = _layout.keys.toList()
          ..sort((a, b) {
            final zA = _layout[a]['zIndex'] ?? 0;
            final zB = _layout[b]['zIndex'] ?? 0;
            return zA.compareTo(zB);
          });

        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.grey[100], // Background for canvas
          child: Stack(
            children: sortedKeys.map((key) {
              if (key == 'top')
                return _buildGarment('top', widget.topData, size);
              if (key == 'bottom')
                return _buildGarment('bottom', widget.bottomData, size);
              if (key == 'shoes')
                return _buildGarment('shoes', widget.shoesData, size);
              return const SizedBox.shrink();
            }).toList(),
          ),
        );
      },
    );
  }
}
