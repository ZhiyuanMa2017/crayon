import 'package:crayon/editor/core/node_controller.dart';
import 'package:crayon/editor/node/rich_text/rich_text_span.dart';
import 'package:crayon/editor/node/rich_text/unordered.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../config/const_texts.dart';

void main() {
  test('from', () {
    UnorderedNode node = UnorderedNode.from(
        constTexts.map((e) => RichTextSpan(text: e)).toList());
    assert(node.spans.length == constTexts.length);
    for (var i = 0; i < node.spans.length; ++i) {
      final span = node.spans[i];
      final text = constTexts[i];
      assert(span.text == text);
    }

    final newNode = node.from([]);
    assert(newNode.isEmpty);
    assert(newNode.spans.length == 1);
  });

  test('toJson', () {
    UnorderedNode node = UnorderedNode.from(
        constTexts.map((e) => RichTextSpan(text: e)).toList());
    final json = node.toJson();
    assert(json['type'] == 'UnorderedNode');
  });

  testWidgets('build', (tester) async {
    UnorderedNode node = UnorderedNode.from(
        constTexts.map((e) => RichTextSpan(text: e)).toList());

    var widget =
        node.from(node.spans, depth: 1).build(NodeController.empty, null, 0);
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: widget,
    ));

    widget =
        node.from(node.spans, depth: 2).build(NodeController.empty, null, null);
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: widget,
    ));

    widget =
        node.from(node.spans, depth: 3).build(NodeController.empty, null, null);
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: widget,
    ));

    widget =
        node.from(node.spans, depth: 4).build(NodeController.empty, null, null);
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: widget,
    ));
  });
}