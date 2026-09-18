// ignore_for_file: use_full_hex_values_for_flutter_colors

import 'dart:ui';

import 'package:fleather/fleather.dart';
import 'package:fleather/src/rendering/editable_text_line.dart';
import 'package:fleather/src/rendering/paragraph_proxy.dart';
import 'package:fleather/util.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tools.dart';

void main() {
  late final CursorController cursorController;

  setUpAll(() {
    cursorController = CursorController(
      showCursor: ValueNotifier(false),
      style:
          const CursorStyle(color: Colors.blue, backgroundColor: Colors.blue),
      tickerProvider: FakeTickerProvider(),
    );
    TestRenderingFlutterBinding.ensureInitialized();
  });

  group('$RenderEditableTextLine', () {
    test('Correctly computes containsCursor if node is updated', () {
      final lineNode = LineNode()..insert(0, 'some text', null);
      final rootNode = RootNode();
      rootNode.addFirst(lineNode);
      final renderBox = RenderEditableTextLine(
          node: lineNode,
          padding: EdgeInsets.zero,
          textDirection: TextDirection.ltr,
          cursorController: cursorController,
          selection: const TextSelection.collapsed(offset: 6),
          selectionColor: Colors.blue,
          enableInteractiveSelection: false,
          hasFocus: false,
          inlineCodeTheme: InlineCodeThemeData(style: const TextStyle()));
      layout(renderBox, constraints: const BoxConstraints(maxWidth: 100));
      expect(renderBox.containsCursor, equals(true));
      lineNode.delete(4, 5);
      expect(renderBox.containsCursor, equals(false));
    });

    test('Correctly computes containsCursor if node is detached', () {
      final lineNode = LineNode()..insert(0, 'some text', null);
      final renderBox = RenderEditableTextLine(
          node: lineNode,
          padding: EdgeInsets.zero,
          textDirection: TextDirection.ltr,
          cursorController: cursorController,
          selection: const TextSelection.collapsed(offset: 6),
          selectionColor: Colors.blue,
          enableInteractiveSelection: false,
          hasFocus: false,
          inlineCodeTheme: InlineCodeThemeData(style: const TextStyle()));
      layout(renderBox, constraints: const BoxConstraints(maxWidth: 100));
      expect(renderBox.containsCursor, equals(false));
    });

    test('Does not hit test body when tap is outside of text boxes', () {
      final lineNode = LineNode();
      final rootNode = RootNode();
      rootNode.addFirst(lineNode);
      final renderBox = RenderEditableTextLine(
          node: lineNode,
          padding: EdgeInsets.zero,
          textDirection: TextDirection.ltr,
          cursorController: cursorController,
          selection: const TextSelection.collapsed(offset: 0),
          selectionColor: Colors.blue,
          enableInteractiveSelection: false,
          hasFocus: false,
          inlineCodeTheme: InlineCodeThemeData(style: const TextStyle()));
      renderBox.body = RenderParagraphProxy(
          textStyle: const TextStyle(),
          textScaler: TextScaler.noScaling,
          child: RenderParagraph(
            const TextSpan(
                text: 'A text with that will be broken into multiple lines'),
            textDirection: TextDirection.ltr,
          ),
          textDirection: TextDirection.ltr,
          textWidthBasis: TextWidthBasis.parent);
      layout(renderBox, constraints: const BoxConstraints(maxWidth: 100));
      expect(
          renderBox.hitTestChildren(BoxHitTestResult(),
              position: const Offset(10, 2)),
          equals(true));
      expect(
          renderBox.hitTestChildren(BoxHitTestResult(),
              position: const Offset(80, 100)),
          equals(false));
    });

    test('Background color', () {
      final lineNode = LineNode()
        ..insert(0, 'some text', ParchmentStyle.fromJson({'bg': 0xffff0000}));
      final rootNode = RootNode();
      rootNode.addFirst(lineNode);
      final paintingContext = MockPaintingContext();
      final renderParagraph = RenderParagraph(const TextSpan(text: 'some text'),
          textDirection: TextDirection.ltr);
      final renderBox = RenderEditableTextLine(
          node: lineNode,
          padding: EdgeInsets.zero,
          textDirection: TextDirection.ltr,
          cursorController: cursorController,
          selection: const TextSelection.collapsed(offset: 0),
          selectionColor: Colors.blue,
          enableInteractiveSelection: false,
          hasFocus: false,
          inlineCodeTheme: InlineCodeThemeData(style: const TextStyle()));
      renderBox.body = RenderParagraphProxy(
          child: renderParagraph,
          textStyle: const TextStyle(),
          textScaler: TextScaler.noScaling,
          textDirection: TextDirection.ltr,
          textWidthBasis: TextWidthBasis.parent);
      layout(renderBox);
      renderBox.paint(paintingContext, Offset.zero);
      expect(paintingContext.canvas.drawnRect, isNotNull);
      expect(paintingContext.canvas.drawnRect!.width, greaterThan(100));
      expect(paintingContext.canvas.drawnRect!.height, greaterThan(10));
      expect(paintingContext.canvas.drawnRectPaint!.style, PaintingStyle.fill);
      expect(paintingContext.canvas.drawnRectPaint!.color,
          const Color(0xffff0000));
    });

    test('inline code', () {
      final lineNode = LineNode()
        ..insert(0, 'some text', ParchmentStyle.fromJson({'c': true}));
      final rootNode = RootNode();
      rootNode.addFirst(lineNode);
      final paintingContext = MockPaintingContext();
      final renderParagraph = RenderParagraph(const TextSpan(text: 'some text'),
          textDirection: TextDirection.ltr);
      final renderBox = RenderEditableTextLine(
          node: lineNode,
          padding: EdgeInsets.zero,
          textDirection: TextDirection.ltr,
          cursorController: cursorController,
          selection: const TextSelection.collapsed(offset: 0),
          selectionColor: Colors.blue,
          enableInteractiveSelection: false,
          hasFocus: false,
          inlineCodeTheme: InlineCodeThemeData(
              style: const TextStyle(),
              backgroundColor: const Color(0xffff00000)));
      renderBox.body = RenderParagraphProxy(
          child: renderParagraph,
          textStyle: const TextStyle(),
          textScaler: TextScaler.noScaling,
          textDirection: TextDirection.ltr,
          textWidthBasis: TextWidthBasis.parent);
      layout(renderBox);
      renderBox.paint(paintingContext, Offset.zero);
      expect(paintingContext.canvas.drawnRect, isNotNull);
      expect(paintingContext.canvas.drawnRect!.width, greaterThan(100));
      expect(paintingContext.canvas.drawnRect!.height, greaterThan(10));
      expect(paintingContext.canvas.drawnRectPaint!.style, PaintingStyle.fill);
      expect(paintingContext.canvas.drawnRectPaint!.color.value32Bits,
          const Color(0xffff00000).value32Bits);
    });
  });

  group('$FleatherTextBackgroundPainter hook', () {
    const markerColor = Color(0xff123456);
    const selectionColor = Color(0xff000001);

    RenderEditableTextLine buildLine({
      required LineNode lineNode,
      required RenderParagraph renderParagraph,
      TextSelection selection = const TextSelection.collapsed(offset: 0),
      bool enableInteractiveSelection = false,
      bool hasFocus = false,
      FleatherTextBackgroundPainter? textBackgroundPainter,
    }) {
      final renderBox = RenderEditableTextLine(
          node: lineNode,
          padding: EdgeInsets.zero,
          textDirection: TextDirection.ltr,
          cursorController: cursorController,
          selection: selection,
          selectionColor: selectionColor,
          enableInteractiveSelection: enableInteractiveSelection,
          hasFocus: hasFocus,
          inlineCodeTheme: InlineCodeThemeData(style: const TextStyle()),
          textBackgroundPainter: textBackgroundPainter);
      renderBox.body = RenderParagraphProxy(
          child: renderParagraph,
          textStyle: const TextStyle(),
          textScaler: TextScaler.noScaling,
          textDirection: TextDirection.ltr,
          textWidthBasis: TextWidthBasis.parent);
      return renderBox;
    }

    test('is invoked once per line with the line\'s text nodes, before '
        'text and before the selection highlight are painted', () {
      final lineNode = LineNode()
        ..insert(0, 'bold', ParchmentStyle.fromJson({'b': true}))
        ..insert(4, 'plain', null);
      final rootNode = RootNode();
      rootNode.addFirst(lineNode);
      final paintingContext = OrderRecordingPaintingContext();
      final renderParagraph = RenderParagraph(
          const TextSpan(text: 'boldplain'),
          textDirection: TextDirection.ltr);

      List<TextNode>? receivedNodes;
      final renderBox = buildLine(
        lineNode: lineNode,
        renderParagraph: renderParagraph,
        // Non-collapsed selection so the selection highlight actually paints.
        selection: const TextSelection(baseOffset: 0, extentOffset: 9),
        enableInteractiveSelection: true,
        hasFocus: true,
        textBackgroundPainter: (canvas, offset, nodes, getBoxesForRange) {
          receivedNodes = nodes;
          canvas.drawRect(
              const Rect.fromLTWH(0, 0, 1, 1), Paint()..color = markerColor);
        },
      );
      layout(renderBox);
      renderBox.paint(paintingContext, Offset.zero);

      expect(receivedNodes, isNotNull);
      expect(receivedNodes!.map((n) => n.value), ['bold', 'plain']);
      // Node offsets are line-local, matching the coordinate space expected
      // by getBoxesForRange.
      expect(receivedNodes!.map((n) => n.offset), [0, 4]);

      final markerIndex =
          paintingContext.canvas.calls.indexOf('rect:${markerColor.value32Bits}');
      final selectionIndex = paintingContext.canvas.calls
          .indexOf('rect:${selectionColor.value32Bits}');
      final paragraphIndex = paintingContext.canvas.calls.indexOf('paragraph');

      expect(markerIndex, greaterThanOrEqualTo(0),
          reason: 'painter should have drawn to the canvas');
      expect(selectionIndex, greaterThanOrEqualTo(0),
          reason: 'selection should have painted');
      expect(paragraphIndex, greaterThanOrEqualTo(0),
          reason: 'text should have painted');
      expect(markerIndex, lessThan(selectionIndex),
          reason: 'painter must run before the selection highlight');
      expect(markerIndex, lessThan(paragraphIndex),
          reason: 'painter must run before the text');
    });

    test('is not invoked when no painter is configured', () {
      final lineNode = LineNode()..insert(0, 'some text', null);
      final rootNode = RootNode();
      rootNode.addFirst(lineNode);
      final paintingContext = OrderRecordingPaintingContext();
      final renderParagraph = RenderParagraph(const TextSpan(text: 'some text'),
          textDirection: TextDirection.ltr);
      final renderBox = buildLine(
          lineNode: lineNode, renderParagraph: renderParagraph);
      layout(renderBox);
      // Should not throw, and should not draw anything extra.
      renderBox.paint(paintingContext, Offset.zero);
      expect(paintingContext.canvas.calls.contains('rect:${markerColor.value32Bits}'),
          isFalse);
    });

    test(
        'getBoxesForRange returns one box for a range on a single visual '
        'line and multiple boxes for a range wrapping across visual lines',
        () {
      final lineNode = LineNode()
        ..insert(
            0,
            'A text with that will be broken into multiple lines when '
            'laid out in a narrow width',
            null);
      final rootNode = RootNode();
      rootNode.addFirst(lineNode);
      final text = lineNode.toPlainText();
      final renderParagraph =
          RenderParagraph(TextSpan(text: text), textDirection: TextDirection.ltr);

      List<TextBox> Function(TextRange)? getBoxesForRange;
      final renderBox = buildLine(
        lineNode: lineNode,
        renderParagraph: renderParagraph,
        textBackgroundPainter: (canvas, offset, nodes, boxesForRange) {
          getBoxesForRange = boxesForRange;
        },
      );
      layout(renderBox, constraints: const BoxConstraints(maxWidth: 100));
      renderBox.paint(OrderRecordingPaintingContext(), Offset.zero);

      expect(getBoxesForRange, isNotNull);

      // A range covering only the first character is a single visual line.
      final singleLineBoxes = getBoxesForRange!(const TextRange(start: 0, end: 1));
      expect(singleLineBoxes, hasLength(1));

      // A range covering the entire (wrapped) line spans several visual
      // lines: Flutter's RenderParagraph returns one box per visual line for
      // plain LTR text.
      final wrappedBoxes =
          getBoxesForRange!(TextRange(start: 0, end: text.length - 1));
      expect(wrappedBoxes.length, greaterThan(1));

      // The boxes are laid out top-to-bottom, matching the visual line
      // order, and don't overlap vertically.
      for (var i = 1; i < wrappedBoxes.length; i++) {
        expect(wrappedBoxes[i].top,
            greaterThanOrEqualTo(wrappedBoxes[i - 1].bottom - 0.5));
      }
    });

    test(
        'caret offset, position-for-offset, selection boxes, and hit '
        'testing are identical with and without a painter configured', () {
      final lineNode = LineNode()..insert(0, 'some text here', null);
      final rootNode = RootNode();
      rootNode.addFirst(lineNode);

      RenderEditableTextLine build(FleatherTextBackgroundPainter? painter) {
        final renderParagraph = RenderParagraph(
            const TextSpan(text: 'some text here'),
            textDirection: TextDirection.ltr);
        return buildLine(
          lineNode: lineNode,
          renderParagraph: renderParagraph,
          selection: const TextSelection(baseOffset: 2, extentOffset: 9),
          enableInteractiveSelection: true,
          hasFocus: true,
          textBackgroundPainter: painter,
        );
      }

      final without = build(null);
      final with_ = build((canvas, offset, nodes, getBoxesForRange) {
        // Exercises the hook without altering anything observable.
        getBoxesForRange(const TextRange(start: 0, end: 4));
      });

      layout(without, constraints: const BoxConstraints(maxWidth: 300));
      layout(with_, constraints: const BoxConstraints(maxWidth: 300));

      const position = TextPosition(offset: 5);
      expect(with_.getOffsetForCaret(position),
          without.getOffsetForCaret(position));

      const tapOffset = Offset(20, 5);
      expect(with_.getPositionForOffset(tapOffset),
          without.getPositionForOffset(tapOffset));

      const selectionForBoxes = TextSelection(baseOffset: 0, extentOffset: 9);
      expect(with_.getBoxesForSelection(selectionForBoxes).map((b) => b.toRect()),
          without.getBoxesForSelection(selectionForBoxes).map((b) => b.toRect()));

      final hitResult1 = BoxHitTestResult();
      final hitResult2 = BoxHitTestResult();
      expect(
          with_.hitTestChildren(hitResult1, position: const Offset(10, 2)),
          without.hitTestChildren(hitResult2, position: const Offset(10, 2)));

      // Paint both; painting with a painter configured must not throw and
      // must not change layout (sizes stay identical).
      with_.paint(OrderRecordingPaintingContext(), Offset.zero);
      without.paint(OrderRecordingPaintingContext(), Offset.zero);
      expect(with_.size, without.size);
    });
  });
}

class FakeTickerProvider extends Fake implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => FakeTicker();
}

class FakeTicker extends Fake implements Ticker {
  @override
  String toString({bool debugIncludeStack = false}) {
    return super.toString();
  }
}

class MockCanvas extends Fake implements Canvas {
  Rect? drawnRect;
  Paint? drawnRectPaint;

  @override
  void drawRect(Rect rect, Paint paint) {
    drawnRect = rect;
    drawnRectPaint = paint;
  }

  @override
  void drawParagraph(Paragraph paragraph, Offset offset) {}
}

class MockPaintingContext extends Fake implements PaintingContext {
  @override
  final MockCanvas canvas = MockCanvas();

  @override
  void paintChild(RenderObject child, Offset offset) {
    child.paint(this, offset);
  }
}

/// A canvas that records the order in which draw calls happen, so tests can
/// assert that the [FleatherTextBackgroundPainter] hook runs before the text
/// and the selection highlight.
class OrderRecordingCanvas extends Fake implements Canvas {
  final List<String> calls = [];

  @override
  void drawRect(Rect rect, Paint paint) {
    calls.add('rect:${paint.color.value32Bits}');
  }

  @override
  void drawRRect(RRect rrect, Paint paint) {
    calls.add('rrect:${paint.color.value32Bits}');
  }

  @override
  void drawParagraph(Paragraph paragraph, Offset offset) {
    calls.add('paragraph');
  }
}

class OrderRecordingPaintingContext extends Fake implements PaintingContext {
  @override
  final OrderRecordingCanvas canvas = OrderRecordingCanvas();

  @override
  void paintChild(RenderObject child, Offset offset) {
    child.paint(this, offset);
  }
}
