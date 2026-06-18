import 'package:flutter/material.dart';

const _colors = <Color>[
  Color(0xFF000000), // black
  Color(0xFFE53935), // red
  Color(0xFF1E88E5), // blue
  Color(0xFF43A047), // green
  Color(0xFFFB8C00), // orange
];

const _widths = <double>[2, 4, 8, 16];

class AnnotationToolbar extends StatelessWidget {
  const AnnotationToolbar({
    super.key,
    required this.activeColor,
    required this.activeWidth,
    required this.isEraser,
    required this.isDrawMode,
    required this.canUndo,
    required this.onColorChanged,
    required this.onWidthChanged,
    required this.onEraserToggled,
    required this.onDrawModeToggled,
    required this.onUndo,
  });

  final Color activeColor;
  final double activeWidth;
  final bool isEraser;
  final bool isDrawMode;
  final bool canUndo;
  final void Function(Color) onColorChanged;
  final void Function(double) onWidthChanged;
  final VoidCallback onEraserToggled;
  final VoidCallback onDrawModeToggled;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        color: scheme.surfaceVariant,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          children: [
            // Draw mode toggle
            Tooltip(
              message: isDrawMode ? 'Switch to view mode' : 'Switch to draw mode',
              child: IconButton(
                icon: Icon(isDrawMode ? Icons.draw : Icons.draw_outlined),
                color: isDrawMode ? scheme.primary : null,
                onPressed: onDrawModeToggled,
              ),
            ),
            if (isDrawMode) ...[
              const SizedBox(width: 4),
              // Pen
              Tooltip(
                message: 'Pen',
                child: IconButton(
                  icon: const Icon(Icons.edit),
                  color: !isEraser ? scheme.primary : null,
                  onPressed: isEraser ? onEraserToggled : null,
                ),
              ),
              // Eraser
              Tooltip(
                message: 'Eraser',
                child: IconButton(
                  icon: const Icon(Icons.auto_fix_high),
                  color: isEraser ? scheme.primary : null,
                  onPressed: isEraser ? null : onEraserToggled,
                ),
              ),
              const SizedBox(width: 4),
              // Color swatches
              for (final color in _colors)
                GestureDetector(
                  onTap: () {
                    if (isEraser) onEraserToggled();
                    onColorChanged(color);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: !isEraser && activeColor.value == color.value
                            ? scheme.primary
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              // Width dots
              for (final w in _widths)
                GestureDetector(
                  onTap: () => onWidthChanged(w),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: w + 6,
                    height: w + 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: activeWidth == w
                          ? (isEraser ? Colors.grey : activeColor)
                          : Colors.grey[400],
                    ),
                  ),
                ),
            ],
            const Spacer(),
            // Undo
            if (isDrawMode)
              IconButton(
                icon: const Icon(Icons.undo),
                onPressed: canUndo ? onUndo : null,
                tooltip: 'Undo',
              ),
          ],
        ),
      ),
    );
  }
}
