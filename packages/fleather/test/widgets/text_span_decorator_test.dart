import 'package:fleather/fleather.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FleatherEditor textSpanDecorator', () {
    testWidgets('decorates inline cloze with background color', (tester) async {
      final doc = ParchmentDocument.fromDelta(
        Delta()..insert('The capital of France is Paris.\n'),
      );
      final parisOffset = 'The capital of France is '.length;
      doc.format(
        parisOffset,
        'Paris'.length,
        ParchmentAttribute.cloze.withData(groupId: 1, hint: 'city'),
      );

      final controller = FleatherController(document: doc);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FleatherEditor(
              controller: controller,
              readOnly: true,
              textSpanDecorator: (context, node, defaultSpan) {
                final clozeAttr = node.style.get(ParchmentAttribute.cloze);
                if (clozeAttr != null) {
                  return TextSpan(
                    text: defaultSpan.text,
                    style: (defaultSpan.style ?? const TextStyle()).copyWith(
                      backgroundColor: Colors.amber,
                    ),
                    recognizer: defaultSpan.recognizer,
                  );
                }
                return defaultSpan;
              },
            ),
          ),
        ),
      );

      final richTextFinder = find.byType(RichText);
      expect(richTextFinder, findsOneWidget);

      final richText = tester.widget<RichText>(richTextFinder);
      final rootSpan = richText.text as TextSpan;
      expect(rootSpan.children, isNotNull);

      // Find the decorated TextSpan for 'Paris'
      final decoratedSpan = rootSpan.children!.firstWhere(
        (span) => span is TextSpan && span.text == 'Paris',
      ) as TextSpan;

      expect(decoratedSpan.style?.backgroundColor, equals(Colors.amber));
    });

    testWidgets('attaches gesture recognizer to decorated span', (tester) async {
      final doc = ParchmentDocument.fromDelta(
        Delta()..insert('Target cloze text\n'),
      );
      doc.format(
        0,
        6,
        ParchmentAttribute.cloze.withData(groupId: 1),
      );

      final controller = FleatherController(document: doc);
      var tappedCloze = false;

      final tapRecognizer = TapGestureRecognizer()
        ..onTap = () {
          tappedCloze = true;
        };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FleatherEditor(
              controller: controller,
              readOnly: true,
              textSpanDecorator: (context, node, defaultSpan) {
                if (node.style.contains(ParchmentAttribute.cloze)) {
                  return TextSpan(
                    text: defaultSpan.text,
                    style: defaultSpan.style,
                    recognizer: tapRecognizer,
                  );
                }
                return defaultSpan;
              },
            ),
          ),
        ),
      );

      expect(find.textContaining('Target cloze text', findRichText: true), findsOneWidget);

      final richText = tester.widget<RichText>(find.byType(RichText));
      final rootSpan = richText.text as TextSpan;
      final span = rootSpan.children!.firstWhere(
        (s) => s is TextSpan && s.text == 'Target',
      ) as TextSpan;

      expect(span.recognizer, equals(tapRecognizer));
      (span.recognizer as TapGestureRecognizer).onTap?.call();
      expect(tappedCloze, isTrue);

      // Clean up recognizer
      addTearDown(tapRecognizer.dispose);
    });

    testWidgets('preserves exact character offsets and caret positioning', (tester) async {
      final doc = ParchmentDocument.fromDelta(
        Delta()..insert('Prefix Paris Suffix\n'),
      );
      doc.format(7, 5, ParchmentAttribute.cloze.withData(groupId: 1));

      final controller = FleatherController(document: doc);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FleatherEditor(
              controller: controller,
              textSpanDecorator: (context, node, defaultSpan) {
                if (node.style.contains(ParchmentAttribute.cloze)) {
                  return TextSpan(
                    text: defaultSpan.text,
                    style: (defaultSpan.style ?? const TextStyle()).copyWith(
                      color: Colors.red,
                    ),
                  );
                }
                return defaultSpan;
              },
            ),
          ),
        ),
      );

      // Verify that total text length rendered equals document text length minus newline
      final richText = tester.widget<RichText>(find.byType(RichText));
      final rootSpan = richText.text as TextSpan;

      var totalRenderedLength = 0;
      rootSpan.visitChildren((span) {
        if (span is TextSpan && span.text != null) {
          totalRenderedLength += span.text!.length;
        }
        return true;
      });

      // Total rendered length must match doc length minus trailing newline
      expect(totalRenderedLength, equals(doc.length - 1));

      // Verify caret movement to the end of the cloze span
      controller.updateSelection(const TextSelection.collapsed(offset: 12));
      await tester.pump();
      expect(controller.selection.baseOffset, equals(12));
      expect(controller.selection.isCollapsed, isTrue);
    });
  });
}
