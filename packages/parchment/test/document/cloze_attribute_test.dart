import 'package:parchment/parchment.dart';
import 'package:test/test.dart';

void main() {
  group('ClozeAttributeData', () {
    test('value equality and hashCode', () {
      const a = ClozeAttributeData(groupId: 1, hint: 'capital');
      const b = ClozeAttributeData(groupId: 1, hint: 'capital');
      const c = ClozeAttributeData(groupId: 2, hint: 'capital');
      const d = ClozeAttributeData(groupId: 1, hint: 'different');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
      expect(a, isNot(equals(d)));
    });

    test('round-trip JSON serialization', () {
      const data = ClozeAttributeData(groupId: 1, hint: 'hint text');
      final json = data.toJson();
      expect(json, equals({'groupId': 1, 'hint': 'hint text'}));

      final decoded = ClozeAttributeData.fromJson(json);
      expect(decoded, equals(data));
    });

    test('omits empty hint from JSON', () {
      const data = ClozeAttributeData(groupId: 2);
      expect(data.toJson(), equals({'groupId': 2}));
    });
  });

  group('ParchmentDocument with Cloze Attributes', () {
    test('round-trips custom cloze attribute from JSON', () {
      final json = [
        {
          'insert': 'The capital is ',
        },
        {
          'insert': 'Paris',
          'attributes': {
            'cloze': {'groupId': 1, 'hint': 'capital'},
          },
        },
        {
          'insert': '.\n',
        },
      ];

      final doc = ParchmentDocument.fromJson(json);
      expect(doc.toPlainText(), 'The capital is Paris.\n');

      final delta = doc.toDelta();
      final ops = delta.toList();
      expect(ops.length, equals(3));
      expect(ops[1].data, equals('Paris'));
      expect(
        ops[1].attributes?['cloze'],
        equals({'groupId': 1, 'hint': 'capital'}),
      );

      final style = doc.collectStyle('The capital is '.length, 'Paris'.length);
      final clozeAttr = style.get(ParchmentAttribute.cloze);
      expect(clozeAttr, isNotNull);
      expect(
        clozeAttr!.value,
        equals(const ClozeAttributeData(groupId: 1, hint: 'capital')),
      );
    });

    test('typing adjacent characters merges operations without delta fragmentation', () {
      final doc = ParchmentDocument();
      final clozeAttr = ParchmentAttribute.cloze.withData(groupId: 1);

      // Insert first character with cloze
      doc.insert(0, 'P');
      doc.format(0, 1, clozeAttr);

      // Insert second adjacent character with cloze
      doc.insert(1, 'a');
      doc.format(1, 1, clozeAttr);

      // Insert third adjacent character with cloze
      doc.insert(2, 'r');
      doc.format(2, 1, clozeAttr);

      final delta = doc.toDelta();
      final ops = delta.toList();
      // Should be merged into a single 'Par' operation, NOT 3 separate 1-char operations
      expect(ops.first.data, equals('Par'));
      expect(ops.first.length, equals(3));
      expect(ops.first.attributes?['cloze'], equals({'groupId': 1}));
    });

    test('adjacent clozes with different groupIds do not merge', () {
      final doc = ParchmentDocument();
      final cloze1 = ParchmentAttribute.cloze.withData(groupId: 1);
      final cloze2 = ParchmentAttribute.cloze.withData(groupId: 2);

      doc.insert(0, 'AB');
      doc.format(0, 1, cloze1);
      doc.format(1, 1, cloze2);

      final ops = doc.toDelta().toList();
      expect(ops[0].data, equals('A'));
      expect(ops[0].attributes?['cloze'], equals({'groupId': 1}));
      expect(ops[1].data, equals('B'));
      expect(ops[1].attributes?['cloze'], equals({'groupId': 2}));
    });

    test('unsetting cloze attribute removes formatting', () {
      final doc = ParchmentDocument();
      doc.insert(0, 'Word\n');
      doc.format(0, 4, ParchmentAttribute.cloze.withData(groupId: 1));

      expect(doc.toDelta().first.attributes?['cloze'], isNotNull);

      // Unset cloze
      doc.format(0, 4, ParchmentAttribute.cloze.unset);
      expect(doc.toDelta().first.attributes?['cloze'], isNull);
    });

    test('supports arbitrary custom dynamic attributes', () {
      final doc = ParchmentDocument();
      doc.insert(0, 'Custom text\n');
      final customAttr = ParchmentAttribute.custom<String>(
        'my_custom_scope',
        'active',
      );
      doc.format(0, 6, customAttr);

      final ops = doc.toDelta().toList();
      expect(ops.first.attributes?['my_custom_scope'], equals('active'));

      // Unsetting dynamic attribute
      doc.format(0, 6, customAttr.unset);
      expect(doc.toDelta().first.attributes?['my_custom_scope'], isNull);
    });
  });
}
