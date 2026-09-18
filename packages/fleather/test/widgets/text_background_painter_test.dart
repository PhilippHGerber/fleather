import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FleatherEditor textBackgroundPainter', () {
    testWidgets('is invoked for lines with decorated text nodes',
        (tester) async {
      final doc = ParchmentDocument.fromDelta(
        Delta()..insert('The capital of France is Paris.\n'),
      );
      final parisOffset = 'The capital of France is '.length;
      doc.format(parisOffset, 'Paris'.length,
          ParchmentAttribute.cloze.withData(groupId: 1, hint: 'city'));

      final controller = FleatherController(document: doc);
      final decoratedTexts = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FleatherEditor(
              controller: controller,
              readOnly: true,
              textBackgroundPainter:
                  (canvas, offset, nodes, getBoxesForRange) {
                for (final node in nodes) {
                  if (node.style.contains(ParchmentAttribute.cloze)) {
                    decoratedTexts.add(node.value);
                  }
                }
              },
            ),
          ),
        ),
      );

      expect(decoratedTexts, contains('Paris'));
    });

    testWidgets('is not invoked when not configured', (tester) async {
      final doc = ParchmentDocument.fromDelta(
        Delta()..insert('Plain text\n'),
      );
      final controller = FleatherController(document: doc);

      // Should build and paint without error when the hook is omitted.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FleatherEditor(controller: controller, readOnly: true),
          ),
        ),
      );

      expect(find.byType(FleatherEditor), findsOneWidget);
    });

    testWidgets('threads through a block (list/quote) line', (tester) async {
      final doc = ParchmentDocument.fromDelta(
        Delta()
          ..insert('quoted text')
          ..insert('\n', {'block': 'quote'}),
      );
      final controller = FleatherController(document: doc);
      var invokedForBlockLine = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FleatherEditor(
              controller: controller,
              readOnly: true,
              textBackgroundPainter:
                  (canvas, offset, nodes, getBoxesForRange) {
                if (nodes.any((n) => n.value == 'quoted text')) {
                  invokedForBlockLine = true;
                }
              },
            ),
          ),
        ),
      );

      expect(invokedForBlockLine, isTrue);
    });

    testWidgets('threads through FleatherField (the editor field wrapper)',
        (tester) async {
      final doc = ParchmentDocument.fromDelta(
        Delta()..insert('Hello field\n'),
      );
      final controller = FleatherController(document: doc);
      var invoked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FleatherField(
              controller: controller,
              readOnly: true,
              textBackgroundPainter:
                  (canvas, offset, nodes, getBoxesForRange) {
                invoked = true;
              },
            ),
          ),
        ),
      );

      expect(invoked, isTrue);
    });

    testWidgets(
        'caret offset and tap-to-position are unchanged with a painter '
        'configured', (tester) async {
      Future<TextSelection> pumpAndTapMiddle(
          {required FleatherTextBackgroundPainter? painter}) async {
        final doc = ParchmentDocument.fromDelta(
          Delta()..insert('Tap somewhere in here\n'),
        );
        final controller = FleatherController(document: doc);
        final focusNode = FocusNode();
        addTearDown(focusNode.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 300,
                  child: FleatherField(
                    controller: controller,
                    focusNode: focusNode,
                    textBackgroundPainter: painter,
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tapAt(tester.getCenter(find.byType(RichText).first));
        await tester.pumpAndSettle();
        return controller.selection;
      }

      final selectionWithout =
          await pumpAndTapMiddle(painter: null);
      final selectionWith = await pumpAndTapMiddle(
          painter: (canvas, offset, nodes, getBoxesForRange) {});

      expect(selectionWith, selectionWithout);
    });
  });
}
