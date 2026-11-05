import 'package:flutter/material.dart';
import 'package:tiktok_mobile/core/theme/app_theme.dart';
import 'package:tiktok_mobile/core/widgets/design_system.dart';
import 'package:tiktok_mobile/features/create/data/overlay_item.dart';
import 'package:tiktok_mobile/features/create/presentation/widgets/overlay_painter.dart';

/// The text and stickers over the preview, and the gestures that arrange
/// them: tap to select, drag to move, pinch to size and turn, tap selected
/// text to change it, drag onto the bin to remove. Sized by its parent to
/// exactly the video's frame.
class OverlayEditor extends StatefulWidget {
  const OverlayEditor({
    super.key,
    required this.items,
    required this.stickers,
    required this.onChanged,
    required this.onEditText,
    required this.onTapEmpty,
    required this.onSelect,
    this.selectedId,
    this.playedAt,
    this.onDragging,
  });

  final List<OverlayItem> items;
  final StickerImages stickers;
  final ValueChanged<List<OverlayItem>> onChanged;

  /// Selected text was tapped again.
  final ValueChanged<OverlayItem> onEditText;

  /// A tap that landed on no item while none was selected — the preview's
  /// play/pause.
  final VoidCallback onTapEmpty;

  /// An item was tapped or grabbed, or null when a tap cleared the selection.
  final ValueChanged<OverlayItem?> onSelect;
  final int? selectedId;

  /// Where the preview is on the edited video's clock. Items not up at that
  /// moment are hidden and cannot be grabbed — except the selected one, so
  /// its timing can be set while looking at it. Null shows everything.
  final double? playedAt;

  /// True while an item is being dragged, for the screen to make room for
  /// the bin.
  final ValueChanged<bool>? onDragging;

  @override
  State<OverlayEditor> createState() => _OverlayEditorState();
}

class _OverlayEditorState extends State<OverlayEditor> {
  /// The item under the fingers, as it was when they came down.
  OverlayItem? _grabbed;

  /// The same item as it is now. Kept here rather than read back from
  /// [OverlayEditor.items]: the parent only rebuilds at the next frame, and
  /// several gesture updates can land before it does.
  OverlayItem? _moving;
  Offset _focal = Offset.zero;
  var _pointers = 0;

  /// Where the first finger came down. The scale gesture only starts once it
  /// has moved past the touch slop, so its own start point is already off
  /// the item that was touched.
  Offset? _down;
  var _overBin = false;

  static const _binRadius = 26.0;

  Offset _bin(Size frame) => Offset(frame.width / 2, frame.height - 56);

  List<OverlayItem> get _visible {
    final at = widget.playedAt;
    if (at == null) return widget.items;
    return [
      for (final item in widget.items)
        if (item.id == widget.selectedId || item.showsAt(at)) item,
    ];
  }

  void _start(ScaleStartDetails details, Size frame) {
    final down = _down ?? details.localFocalPoint;
    final item = overlayItemAt(_visible, frame, down);
    if (item == null) return;
    _grabbed = item;
    // Measured from where the finger came down, so the way it travelled
    // before the gesture began still counts. Updates go on from here.
    _focal = details.localFocalPoint;
    _pointers = details.pointerCount;
    _moving = _movedBy(item, details.localFocalPoint - down, frame);
    // Whatever is touched comes to the front, as it would on paper.
    widget.onChanged([...widget.items.where((i) => i.id != item.id), _moving!]);
    if (item.id != widget.selectedId) widget.onSelect(_moving);
    widget.onDragging?.call(true);
  }

  OverlayItem _movedBy(OverlayItem item, Offset by, Size frame) =>
      item.copyWith(
        x: (item.x + by.dx / frame.width).clamp(0.0, 1.0),
        y: (item.y + by.dy / frame.height).clamp(0.0, 1.0),
      );

  void _update(ScaleUpdateDetails details, Size frame) {
    final grabbed = _grabbed;
    final current = _moving;
    if (grabbed == null || current == null) return;
    // A finger landing or lifting moves the focal point without the item
    // moving: start measuring again from there.
    if (details.pointerCount != _pointers) {
      _pointers = details.pointerCount;
      _focal = details.localFocalPoint;
    }
    final by = details.localFocalPoint - _focal;
    _focal = details.localFocalPoint;
    final moved = _movedBy(current, by, frame).copyWith(
      scale: (grabbed.scale * details.scale).clamp(
        overlayMinScale,
        overlayMaxScale,
      ),
      rotation: grabbed.rotation + details.rotation,
    );
    final overBin =
        details.pointerCount == 1 &&
        (_focal - _bin(frame)).distance <= _binRadius * 2;
    if (overBin != _overBin) setState(() => _overBin = overBin);
    _moving = moved;
    // Kept on top, where _start put it: the parent may not have rebuilt yet.
    widget.onChanged([...widget.items.where((i) => i.id != moved.id), moved]);
  }

  void _end() {
    final grabbed = _grabbed;
    if (grabbed == null) return;
    if (_overBin) {
      widget.onChanged(widget.items.where((i) => i.id != grabbed.id).toList());
      widget.onSelect(null);
    }
    setState(() {
      _grabbed = null;
      _moving = null;
      _overBin = false;
    });
    widget.onDragging?.call(false);
  }

  void _tap(TapUpDetails details, Size frame) {
    final item = overlayItemAt(_visible, frame, details.localPosition);
    if (item == null) {
      widget.selectedId == null ? widget.onTapEmpty() : widget.onSelect(null);
    } else if (item.id == widget.selectedId && item.kind == OverlayKind.text) {
      widget.onEditText(item);
    } else {
      widget.onSelect(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final frame = constraints.biggest;
        final bin = _bin(frame);
        return Listener(
          onPointerDown: (event) => _down ??= event.localPosition,
          onPointerUp: (_) => _down = null,
          onPointerCancel: (_) => _down = null,
          child: GestureDetector(
            key: const Key('overlay_editor'),
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _tap(d, frame),
            onScaleStart: (d) => _start(d, frame),
            onScaleUpdate: (d) => _update(d, frame),
            onScaleEnd: (_) => _end(),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: OverlayPainter(
                      _visible,
                      widget.stickers,
                      highlight: _overBin ? _grabbed?.id : null,
                      outlined: _grabbed == null ? widget.selectedId : null,
                    ),
                  ),
                ),
                if (_grabbed != null)
                  Positioned(
                    left: bin.dx - _binRadius,
                    top: bin.dy - _binRadius,
                    child: AnimatedScale(
                      scale: _overBin ? 1.25 : 1,
                      duration: const Duration(milliseconds: 120),
                      child: Container(
                        key: const Key('overlay_bin'),
                        width: _binRadius * 2,
                        height: _binRadius * 2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _overBin ? NowaColors.danger : Colors.black54,
                          border: Border.all(color: Colors.white70),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// What the text editor hands back: the item as typed, or [removed] when the
/// text was cleared.
typedef TextEditResult = ({
  String text,
  int colour,
  bool boxed,
  int font,
  bool removed,
});

/// Full-screen typing over a dimmed preview, with the font, colour and box
/// style around the field. Null when dismissed without Done.
Future<TextEditResult?> showOverlayTextEditor(
  BuildContext context, {
  OverlayItem? editing,
}) {
  return showGeneralDialog<TextEditResult>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    pageBuilder: (_, _, _) => _TextEditor(editing: editing),
  );
}

class _TextEditor extends StatefulWidget {
  const _TextEditor({this.editing});

  final OverlayItem? editing;

  @override
  State<_TextEditor> createState() => _TextEditorState();
}

class _TextEditorState extends State<_TextEditor> {
  late final _controller = TextEditingController(
    text: widget.editing?.text ?? '',
  );
  late int _colour = widget.editing?.colour ?? 0;
  late bool _boxed = widget.editing?.boxed ?? false;
  late int _font = widget.editing?.font ?? 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _done() {
    final text = _controller.text.trim();
    Navigator.of(context).pop<TextEditResult>((
      text: text,
      colour: _colour,
      boxed: _boxed,
      font: _font,
      removed: text.isEmpty,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colour = overlayPalette[_colour];
    final ink = _boxed
        ? (colour.computeLuminance() > 0.5 ? Colors.black : Colors.white)
        : colour;
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  key: const Key('overlay_text_box_toggle'),
                  tooltip: 'Background',
                  onPressed: () => setState(() => _boxed = !_boxed),
                  icon: Icon(
                    _boxed ? Icons.format_color_fill : Icons.format_color_text,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                TextButton(
                  key: const Key('overlay_text_done'),
                  onPressed: _done,
                  child: Text(
                    'Done',
                    style: sora(
                      size: 15,
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _boxed ? colour : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IntrinsicWidth(
                      child: TextField(
                        key: const Key('overlay_text_field'),
                        controller: _controller,
                        autofocus: true,
                        maxLines: null,
                        maxLength: 150,
                        textAlign: TextAlign.center,
                        cursorColor: ink,
                        style: overlayTextStyle(
                          overlayFonts[_font],
                          fontSize: 28,
                          colour: ink,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          counterText: '',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: overlayFonts.length,
                itemBuilder: (context, i) {
                  final selected = i == _font;
                  return GestureDetector(
                    key: Key('overlay_font_$i'),
                    onTap: () => setState(() => _font = i),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : Colors.white24,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        overlayFonts[i].name,
                        style: overlayTextStyle(
                          overlayFonts[i],
                          fontSize: 15,
                          colour: selected ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              height: 52,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: overlayPalette.length,
                itemBuilder: (context, i) => GestureDetector(
                  key: Key('overlay_colour_$i'),
                  onTap: () => setState(() => _colour = i),
                  child: Container(
                    width: 30,
                    height: 30,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: overlayPalette[i],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: i == _colour ? 3 : 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// A grid of stickers to lay over the video. Resolves to the id picked, or null.
Future<String?> showStickerPicker(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: NowaColors.surface,
    showDragHandle: true,
    builder: (context) => SizedBox(
      height: 340,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
        ),
        itemCount: overlayStickers.length,
        itemBuilder: (context, i) => InkWell(
          key: Key('overlay_sticker_${overlayStickers[i]}'),
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context).pop(overlayStickers[i]),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Image.asset(
              stickerAsset(overlayStickers[i]),
              cacheWidth: 128,
            ),
          ),
        ),
      ),
    ),
  );
}

/// The editor's text and sticker buttons, stacked on the right like the
/// camera's tools.
class OverlayTools extends StatelessWidget {
  const OverlayTools({
    super.key,
    required this.onText,
    required this.onSticker,
  });

  final VoidCallback onText;
  final VoidCallback onSticker;

  @override
  Widget build(BuildContext context) {
    Widget tool(Key key, IconData icon, String label, VoidCallback onTap) =>
        GestureDetector(
          key: key,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              children: [
                Glass(
                  radius: 12,
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(icon, size: 20, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: sora(
                    size: 10,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        tool(const Key('edit_tool_text'), Icons.text_fields, 'Text', onText),
        tool(
          const Key('edit_tool_sticker'),
          Icons.emoji_emotions_outlined,
          'Stickers',
          onSticker,
        ),
      ],
    );
  }
}

/// The selected item's controls in place of the editor's: when it shows,
/// on the edited video's clock, and what else can be done with it.
class OverlayItemPanel extends StatelessWidget {
  const OverlayItemPanel({
    super.key,
    required this.item,
    required this.duration,
    required this.onTiming,
    required this.onEdit,
    required this.onDelete,
    required this.onDone,
  });

  final OverlayItem item;

  /// How long the edited video plays, in seconds.
  final double duration;

  /// The new range, and where the end that moved now is — so the preview can
  /// show that frame.
  final void Function(double? start, double? end, double movedTo) onTiming;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDone;

  /// Closer than this to either end of the video is the end itself, which is
  /// sent as "no limit" so a later trim does not leave it short.
  static const _snap = 0.05;

  static String _clock(double seconds) {
    final tenths = (seconds * 10).round();
    return '${tenths ~/ 600}:${((tenths % 600) / 10).toStringAsFixed(1).padLeft(4, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final max = duration <= 0 ? 1.0 : duration;
    final start = (item.start ?? 0).clamp(0.0, max);
    final end = (item.end ?? max).clamp(start, max);
    return Glass(
      radius: 14,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text('Shows', style: sora(size: 11.5, color: NowaColors.dim)),
                const Spacer(),
                Text(
                  '${_clock(start)} – ${_clock(end)}',
                  key: const Key('overlay_timing_label'),
                  style: sora(
                    size: 12.5,
                    weight: FontWeight.w600,
                    color: NowaColors.text,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: NowaColors.accent,
                inactiveTrackColor: NowaColors.hairline,
                thumbColor: NowaColors.text,
                rangeThumbShape: const RoundRangeSliderThumbShape(
                  enabledThumbRadius: 8,
                ),
              ),
              child: RangeSlider(
                key: const Key('overlay_timing_slider'),
                min: 0,
                max: max,
                values: RangeValues(start, end),
                onChanged: (values) {
                  if (values.end - values.start < 0.2) return;
                  final movedTo = values.start != start
                      ? values.start
                      : values.end;
                  onTiming(
                    values.start <= _snap ? null : values.start,
                    values.end >= max - _snap ? null : values.end,
                    movedTo,
                  );
                },
              ),
            ),
            Row(
              children: [
                if (item.kind == OverlayKind.text)
                  TextButton.icon(
                    key: const Key('overlay_item_edit'),
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                    label: Text(
                      'Edit',
                      style: sora(size: 12.5, color: Colors.white),
                    ),
                  ),
                TextButton.icon(
                  key: const Key('overlay_item_delete'),
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: NowaColors.danger,
                  ),
                  label: Text(
                    'Delete',
                    style: sora(size: 12.5, color: NowaColors.danger),
                  ),
                ),
                const Spacer(),
                TextButton(
                  key: const Key('overlay_item_done'),
                  onPressed: onDone,
                  child: Text(
                    'Done',
                    style: sora(
                      size: 13,
                      weight: FontWeight.w700,
                      color: NowaColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
