import 'package:flutter/material.dart';
import '../models/draw_tool.dart';

const _penColors = <Color>[
  Color(0xFF000000),
  Color(0xFFE53935),
  Color(0xFF1E88E5),
  Color(0xFF43A047),
  Color(0xFFFB8C00),
];

const _highlightColors = <Color>[
  Color(0xFFFFEB3B), // yellow
  Color(0xFF69F0AE), // green
  Color(0xFF40C4FF), // blue
  Color(0xFFFF80AB), // pink
];

const _penWidths = <double>[2, 4, 8, 16];
const _eraserWidths = <double>[12, 24, 40, 64];
const _highlightWidths = <double>[12, 20, 32, 48];

class AnnotationToolbar extends StatelessWidget {
  const AnnotationToolbar({
    super.key,
    required this.activeTool,
    required this.activeColor,
    required this.activeWidth,
    required this.isDrawMode,
    required this.canUndo,
    required this.onToolChanged,
    required this.onColorChanged,
    required this.onWidthChanged,
    required this.onDrawModeToggled,
    required this.onUndo,
  });

  final DrawTool activeTool;
  final Color activeColor;
  final double activeWidth;
  final bool isDrawMode;
  final bool canUndo;
  final void Function(DrawTool) onToolChanged;
  final void Function(Color) onColorChanged;
  final void Function(double) onWidthChanged;
  final VoidCallback onDrawModeToggled;
  final VoidCallback onUndo;

  List<Color> get _colors =>
      activeTool == DrawTool.highlighter ? _highlightColors : _penColors;

  List<double> get _widths {
    if (activeTool == DrawTool.eraser) return _eraserWidths;
    if (activeTool == DrawTool.highlighter) return _highlightWidths;
    return _penWidths;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          border: Border(top: BorderSide(color: scheme.outlineVariant, width: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tool row
            Row(
              children: [
                // Draw mode toggle
                _ToolButton(
                  icon: isDrawMode ? Icons.draw : Icons.draw_outlined,
                  selected: isDrawMode,
                  tooltip: isDrawMode ? 'View mode' : 'Draw mode',
                  onTap: onDrawModeToggled,
                  scheme: scheme,
                ),
                if (isDrawMode) ...[
                  const SizedBox(width: 2),
                  _ToolButton(
                    icon: Icons.edit,
                    selected: activeTool == DrawTool.pen,
                    tooltip: 'Pen',
                    onTap: () => onToolChanged(DrawTool.pen),
                    scheme: scheme,
                  ),
                  _ToolButton(
                    icon: Icons.format_color_fill,
                    selected: activeTool == DrawTool.highlighter,
                    tooltip: 'Highlighter',
                    onTap: () => onToolChanged(DrawTool.highlighter),
                    scheme: scheme,
                  ),
                  _ToolButton(
                    icon: Icons.auto_fix_high,
                    selected: activeTool == DrawTool.eraser,
                    tooltip: 'Eraser',
                    onTap: () => onToolChanged(DrawTool.eraser),
                    scheme: scheme,
                  ),
                  const _Divider(),
                  // Colors (not shown for eraser)
                  if (activeTool != DrawTool.eraser)
                    ...(_colors.map((c) => _ColorDot(
                          color: c,
                          selected: activeColor.value == c.value,
                          onTap: () => onColorChanged(c),
                        ))),
                  if (activeTool != DrawTool.eraser) const _Divider(),
                  // Width dots
                  ...(_widths.map((w) => _WidthDot(
                        width: w,
                        selected: activeWidth == w,
                        color: activeTool == DrawTool.eraser
                            ? scheme.onSurfaceVariant
                            : activeTool == DrawTool.highlighter
                                ? activeColor.withOpacity(0.5)
                                : activeColor,
                        onTap: () => onWidthChanged(w),
                      ))),
                ],
                const Spacer(),
                if (isDrawMode)
                  IconButton(
                    icon: const Icon(Icons.undo),
                    onPressed: canUndo ? onUndo : null,
                    tooltip: 'Undo',
                    iconSize: 22,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.selected,
    required this.tooltip,
    required this.onTap,
    required this.scheme,
  });

  final IconData icon;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: selected ? scheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              size: 20,
              color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color, required this.selected, required this.onTap});

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: selected
              ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 4, spreadRadius: 1)]
              : null,
        ),
      ),
    );
  }
}

class _WidthDot extends StatelessWidget {
  const _WidthDot({
    required this.width,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final double width;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = (width.clamp(2.0, 16.0) + 6).clamp(8.0, 22.0);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? color : Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}
