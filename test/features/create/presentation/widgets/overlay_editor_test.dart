import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_mobile/features/create/data/overlay_item.dart';
import 'package:tiktok_mobile/features/create/presentation/widgets/overlay_editor.dart';
import 'package:tiktok_mobile/features/create/presentation/widgets/overlay_painter.dart';

/// The editor over a 360x640 "video", holding its items and selection the
/// way the preview screen does.
class _Host extends StatefulWidget {
  const _Host({required this.items, this.playedAt});

  final List<OverlayItem> items;
  final double? playedAt;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late var items = widget.items;
  int? selectedId;
  final edited = <OverlayItem>[];
  var tappedEmpty = 0;
  final stickers = StickerImages();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 360,
          height: 640,
          child: OverlayEditor(
            items: items,
            stickers: stickers,
            selectedId: selectedId,
            playedAt: widget.playedAt,
            onChanged: (next) => setState(() => items = next),
            onSelect: (item) => setState(() => selectedId = item?.id),
            onEditText: edited.add,
            onTapEmpty: () => tappedEmpty++,
          ),
        ),
      ),
    );
  }
}

void main() {
  const hello = OverlayItem(
    id: 1,
    kind: OverlayKind.text,
    text: 'Hello',
    x: 0.5,
    y: 0.25,
  );
  const later = OverlayItem(
    id: 2,
    kind: OverlayKind.text,
    text: 'Later',
    x: 0.5,
    y: 0.75,
    start: 3,
  );

  Future<_HostState> pump(WidgetTester tester, {double? playedAt}) async {
    // The frame is the whole test screen, so every coordinate below is exact.
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _Host(items: const [hello, later], playedAt: playedAt),
    );
    return tester.state<_HostState>(find.byType(_Host));
  }

  Future<void> tapAt(WidgetTester tester, Offset at) async {
    await tester.tapAt(at);
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('dragging an item moves it by the same fraction of the frame', (
    tester,
  ) async {
    final host = await pump(tester);

    await tester.dragFrom(const Offset(180, 160), const Offset(36, 128));
    await tester.pump();

    final moved = host.items.firstWhere((i) => i.id == 1);
    expect(moved.x, closeTo(0.6, 0.02));
    expect(moved.y, closeTo(0.45, 0.02));
    // What is grabbed is selected, and comes to the front.
    expect(host.selectedId, 1);
    expect(host.items.last.id, 1);
  });

  testWidgets('dropping an item on the bin removes it', (tester) async {
    final host = await pump(tester);

    final gesture = await tester.startGesture(const Offset(180, 160));
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    expect(find.byKey(const Key('overlay_bin')), findsOneWidget);
    await gesture.moveTo(const Offset(180, 640 - 56));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(host.items.map((i) => i.id), [2]);
    expect(host.selectedId, isNull);
    expect(find.byKey(const Key('overlay_bin')), findsNothing);
  });

  testWidgets('a tap selects; a second tap on selected text edits it', (
    tester,
  ) async {
    final host = await pump(tester);

    await tapAt(tester, const Offset(180, 160));
    expect(host.selectedId, 1);
    expect(host.edited, isEmpty);

    await tapAt(tester, const Offset(180, 160));
    expect(host.edited.single.id, 1);
  });

  testWidgets(
    'a tap on nothing clears the selection, and with none toggles playback',
    (tester) async {
      final host = await pump(tester);
      await tapAt(tester, const Offset(180, 160));

      await tapAt(tester, const Offset(40, 500));
      expect(host.selectedId, isNull);
      expect(host.tappedEmpty, 0);

      await tapAt(tester, const Offset(40, 500));
      expect(host.tappedEmpty, 1);
    },
  );

  testWidgets('an item not up at the current moment cannot be touched', (
    tester,
  ) async {
    final host = await pump(tester, playedAt: 1);

    await tapAt(tester, const Offset(180, 480));
    expect(host.selectedId, isNull);
    expect(host.tappedEmpty, 1);
  });

  testWidgets('it can once playback reaches its start', (tester) async {
    final host = await pump(tester, playedAt: 3.5);

    await tapAt(tester, const Offset(180, 480));
    expect(host.selectedId, 2);
  });

  testWidgets('a drag that starts on no item moves nothing', (tester) async {
    final host = await pump(tester);

    await tester.dragFrom(const Offset(40, 560), const Offset(100, -100));
    await tester.pump();

    expect(host.items, const [hello, later]);
  });

  group('OverlayItemPanel', () {
    Future<List<(double?, double?, double)>> panel(
      WidgetTester tester,
      OverlayItem item,
    ) async {
      final timings = <(double?, double?, double)>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OverlayItemPanel(
              item: item,
              duration: 10,
              onTiming: (start, end, movedTo) =>
                  timings.add((start, end, movedTo)),
              onEdit: () {},
              onDelete: () {},
              onDone: () {},
            ),
          ),
        ),
      );
      return timings;
    }

    testWidgets('shows the whole video for an untimed item', (tester) async {
      await panel(tester, hello);
      expect(find.text('0:00.0 – 0:10.0'), findsOneWidget);
    });

    testWidgets(
      'moving the start handle times the item from there, end left open',
      (tester) async {
        final timings = await panel(tester, hello);
        final slider = tester.getRect(
          find.byKey(const Key('overlay_timing_slider')),
        );

        await tester.dragFrom(
          Offset(slider.left + 24, slider.center.dy),
          Offset(slider.width * 0.3, 0),
        );
        await tester.pump();

        final (start, end, movedTo) = timings.last;
        expect(start, isNotNull);
        expect(start!, greaterThan(1));
        expect(end, isNull);
        expect(movedTo, start);
      },
    );

    testWidgets('a sticker has no Edit', (tester) async {
      await panel(
        tester,
        const OverlayItem(id: 3, kind: OverlayKind.sticker, text: 'fire'),
      );
      expect(find.byKey(const Key('overlay_item_edit')), findsNothing);
      expect(find.byKey(const Key('overlay_item_delete')), findsOneWidget);
    });
  });
}
