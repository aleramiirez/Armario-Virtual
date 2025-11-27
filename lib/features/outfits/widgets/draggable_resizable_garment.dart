import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class DraggableResizableGarment extends StatefulWidget {
  final String imageUrl;
  final bool isEditing;
  final double initialScale;
  final Offset initialPosition;
  final double baseSize;
  final Function(Offset position, double scale) onUpdate;
  final VoidCallback? onSelect;

  const DraggableResizableGarment({
    super.key,
    required this.imageUrl,
    required this.isEditing,
    required this.initialScale,
    required this.initialPosition,
    required this.baseSize,
    required this.onUpdate,
    this.onSelect,
  });

  @override
  State<DraggableResizableGarment> createState() =>
      _DraggableResizableGarmentState();
}

class _DraggableResizableGarmentState extends State<DraggableResizableGarment> {
  late double _scale;
  late Offset _position;

  @override
  void initState() {
    super.initState();
    _scale = widget.initialScale;
    _position = widget.initialPosition;
  }

  @override
  void didUpdateWidget(DraggableResizableGarment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPosition != oldWidget.initialPosition) {
      _position = widget.initialPosition;
    }
    if (widget.initialScale != oldWidget.initialScale) {
      _scale = widget.initialScale;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Content widget (Image)
    Widget content = CachedNetworkImage(
      imageUrl: widget.imageUrl,
      fit: BoxFit.contain,
      width: widget.baseSize,
      placeholder: (context, url) => SizedBox(
        width: widget.baseSize / 3,
        height: widget.baseSize / 3,
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => const Icon(Icons.error),
    );

    if (!widget.isEditing) {
      return Transform.scale(scale: _scale, child: content);
    }

    // Editing Mode
    return Transform.scale(
      scale: _scale,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Move Gesture Detector (wraps the content)
          GestureDetector(
            onPanStart: (_) => widget.onSelect?.call(),
            onTap: widget.onSelect,
            onPanUpdate: (details) {
              setState(() {
                _position += details.delta;
              });
              widget.onUpdate(_position, _scale);
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.blue.withOpacity(0.5),
                  width: 2 / _scale, // Keep border width constant visually
                ),
              ),
              child: content,
            ),
          ),

          // 2. Resize Handle (Bottom Right)
          Positioned(
            right:
                -12 / _scale, // Adjust for scale to keep handle size constant
            bottom: -12 / _scale,
            child: GestureDetector(
              onPanStart: (_) => widget.onSelect?.call(),
              onPanUpdate: (details) {
                // Calculate new scale based on drag
                // Dragging down/right increases scale
                final double scaleDelta =
                    (details.delta.dx + details.delta.dy) / 200;
                final double newScale = (_scale + scaleDelta).clamp(0.5, 3.0);

                if (newScale != _scale) {
                  setState(() {
                    _scale = newScale;
                  });
                  widget.onUpdate(_position, _scale);
                }
              },
              child: Container(
                width: 24 / _scale,
                height: 24 / _scale,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2 / _scale),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4 / _scale,
                      offset: Offset(0, 2 / _scale),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.open_in_full,
                  size: 14 / _scale,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
