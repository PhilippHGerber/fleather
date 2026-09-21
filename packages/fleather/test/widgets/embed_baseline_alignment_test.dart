import 'package:fleather/fleather.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('Fleather inline embed baseline alignment', () {
    testWidgets(
        'configures WidgetSpan with PlaceholderAlignment.baseline and TextBaseline.alphabetic when embedConfig is provided',
        (tester) async {
      final doc = ParchmentDocument.fromJson([
        {'insert': 'Hello '},
        {
          'insert': SpanEmbed('chip', data: {'text': 'inline'}).toJson(),
        },
        {'insert': ' world\n'},
      ]);
      final controller = FleatherController(document: doc);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FleatherEditor(
              controller: controller,
              embedBuilder: (context, node) {
                if (node.value.type == 'chip') {
                  return const SizedBox(width: 20, height: 10);
                }
                return defaultFleatherEmbedBuilder(context, node);
              },
              embedConfig: (context, node) {
                if (node.value.type == 'chip') {
                  return const FleatherSpanEmbedConfig(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                  );
                }
                return null;
              },
            ),
          ),
        ),
      );

      final richTextFinder = find.descendant(
        of: find.byType(TextLine),
        matching: find.byType(RichText),
      );
      final richText = tester.widget<RichText>(richTextFinder.first);
      final rootSpan = richText.text as TextSpan;

      WidgetSpan? embedSpan;
      rootSpan.visitChildren((span) {
        if (span is WidgetSpan) {
          embedSpan = span;
          return false;
        }
        return true;
      });

      expect(embedSpan, isNotNull);
      expect(embedSpan!.alignment, equals(PlaceholderAlignment.baseline));
      expect(embedSpan!.baseline, equals(TextBaseline.alphabetic));
    });

    testWidgets(
        'configures WidgetSpan using FleatherSpanEmbedConfig.baseline convenience constructor',
        (tester) async {
      final doc = ParchmentDocument.fromJson([
        {'insert': 'Leading '},
        {
          'insert': SpanEmbed('badge', data: {'val': '1'}).toJson(),
        },
        {'insert': ' trailing\n'},
      ]);
      final controller = FleatherController(document: doc);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FleatherEditor(
              controller: controller,
              embedBuilder: (context, node) {
                if (node.value.type == 'badge') {
                  return const SizedBox(width: 14, height: 14);
                }
                return defaultFleatherEmbedBuilder(context, node);
              },
              embedConfig: (context, node) {
                if (node.value.type == 'badge') {
                  return const FleatherSpanEmbedConfig.baseline();
                }
                return null;
              },
            ),
          ),
        ),
      );

      final richTextFinder = find.descendant(
        of: find.byType(TextLine),
        matching: find.byType(RichText),
      );
      final richText = tester.widget<RichText>(richTextFinder.first);
      final rootSpan = richText.text as TextSpan;

      WidgetSpan? embedSpan;
      rootSpan.visitChildren((span) {
        if (span is WidgetSpan) {
          embedSpan = span;
          return false;
        }
        return true;
      });

      expect(embedSpan, isNotNull);
      expect(embedSpan!.alignment, equals(PlaceholderAlignment.baseline));
      expect(embedSpan!.baseline, equals(TextBaseline.alphabetic));
    });

    testWidgets(
        'defaults to PlaceholderAlignment.bottom and null baseline when embedConfig is omitted',
        (tester) async {
      final doc = ParchmentDocument.fromJson([
        {'insert': 'Standard '},
        {
          'insert': SpanEmbed('chip', data: {'text': 'default'}).toJson(),
        },
        {'insert': ' text\n'},
      ]);
      final controller = FleatherController(document: doc);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FleatherEditor(
              controller: controller,
              embedBuilder: (context, node) {
                if (node.value.type == 'chip') {
                  return const SizedBox(width: 20, height: 10);
                }
                return defaultFleatherEmbedBuilder(context, node);
              },
            ),
          ),
        ),
      );

      final richTextFinder = find.descendant(
        of: find.byType(TextLine),
        matching: find.byType(RichText),
      );
      final richText = tester.widget<RichText>(richTextFinder.first);
      final rootSpan = richText.text as TextSpan;

      WidgetSpan? embedSpan;
      rootSpan.visitChildren((span) {
        if (span is WidgetSpan) {
          embedSpan = span;
          return false;
        }
        return true;
      });

      expect(embedSpan, isNotNull);
      expect(embedSpan!.alignment, equals(PlaceholderAlignment.bottom));
      expect(embedSpan!.baseline, isNull);
    });

    testWidgets('block embeds (horizontal rule) continue to render normally',
        (tester) async {
      final controller = FleatherController();
      controller.replaceText(0, 0, BlockEmbed.horizontalRule);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FleatherEditor(
              controller: controller,
            ),
          ),
        ),
      );

      expect(find.byType(Divider), findsOneWidget);
    });
  });
}
