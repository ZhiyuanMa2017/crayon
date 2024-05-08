import 'dart:math';

import 'package:crayon/editor/core/listener_collection.dart';
import 'package:crayon/editor/core/node_controller.dart';
import 'package:crayon/editor/cursor/rich_text.dart';
import 'package:crayon/editor/node/rich_text/rich_text.dart';
import 'package:crayon/editor/node/rich_text/rich_text_span.dart';
import 'package:crayon/editor/widget/nodes/rich_text.dart';
import 'package:flutter/cupertino.dart' hide RichText;
import 'package:flutter_test/flutter_test.dart';
import 'package:crayon/editor/exception/editor_node.dart';
import 'package:crayon/editor/node/basic.dart';
import 'package:crayon/editor/cursor/node_position.dart';

import '../config/const_texts.dart';
import '../config/test_editor_node.dart';

typedef SpanGenerator = RichTextSpan Function(String text, int offset);

void main() {
  RichTextNode basicNode({List<String>? texts, SpanGenerator? generator}) {
    final spans = <RichTextSpan>[];
    for (var text in (texts ?? constTexts)) {
      final isFirst = spans.isEmpty;
      final offset = isFirst ? 0 : spans.last.endOffset;
      spans.add(generator?.call(text, offset) ??
          RichTextSpan(text: text, offset: offset));
    }

    return RichTextNode.from(spans);
  }

  test('frontPartNode', () {
    final newNode = basicNode();
    final node1 = newNode.frontPartNode(RichTextNodePosition(4, 5));
    assert(node1.spans.length == 1);
    final realText =
        constTexts.sublist(0, 4).join() + constTexts[4].substring(0, 5);
    assert(node1.text == realText);
    assert(node1.spans.first.offset == newNode.spans.first.offset);
    assert(node1.spans.first.endOffset ==
        node1.spans.first.offset + realText.length);
  });

  test('rearPartNode', () {
    int i = 0;
    final newNode = basicNode(
        generator: (text, offset) =>
            RichTextSpan(text: text, offset: offset, tags: {'${i++}'}));
    final node1 = newNode.rearPartNode(RichTextNodePosition(4, 5));
    assert(node1.getSpan(0).text == constTexts[4].substring(5));
    assert(node1.getSpan(0).text != constTexts[4]);
    assert(node1.getSpan(1).text == constTexts[5]);
    assert(node1.getSpan(2).text == constTexts[6]);
    assert(node1.getSpan(3).text == constTexts[7]);
    assert(node1.getSpan(4).text == constTexts[8]);
    assert(node1.getSpan(5).text == constTexts[9]);
    for (var i = 1; i < node1.spans.length; ++i) {
      var currentSpan = node1.getSpan(i);
      assert(currentSpan.offset == node1.getSpan(i - 1).endOffset);
    }

    assert(newNode.rearPartNode(newNode.endPosition).spans.length == 1);

    final node2 =
        node1.rearPartNode(RichTextNodePosition(node1.spans.length - 1, 0));
    assert(node2.spans.length == 1);
    assert(node2.spans.last.text == node1.spans.last.text);

    final node3 = node1.rearPartNode(RichTextNodePosition(
        node1.spans.length - 2,
        node1.getSpan(node1.spans.length - 2).textLength));
    assert(node3.spans.length == 1);
  });

  test('locateSpanIndex', () {
    final newNode = basicNode();
    int i = 0;
    for (var span in newNode.spans) {
      final startOff = span.offset;
      final startOffIndex = newNode.locateSpanIndex(startOff);
      final startOffIndex1 = newNode.locateSpanIndex(startOff - 1);
      final startOffIndex2 = newNode.locateSpanIndex(startOff + 1);

      assert(startOffIndex == i || startOffIndex == i - 1);
      assert(startOffIndex1 == i || startOffIndex1 == i - 1);
      assert(startOffIndex2 == i);

      final endOff = span.endOffset;
      final endOffIndex = newNode.locateSpanIndex(endOff);
      final endOffIndex1 = newNode.locateSpanIndex(endOff - 1);
      final endOffIndex2 = newNode.locateSpanIndex(endOff + 1);

      assert(endOffIndex == i || endOffIndex == i + 1);
      assert(endOffIndex1 == i);
      assert(endOffIndex2 == i || endOffIndex2 == i + 1);
      i++;
    }
  });

  test('insert', () {
    final newNode = basicNode();
    final node1 = newNode.insert(0, RichTextSpan(text: 'a' * 5));
    assert(node1.spans.length == 1);
    int offset = 0;
    for (var span in node1.spans) {
      assert(span.offset == offset);
      offset += span.textLength;
    }

    final node2 = newNode.insert(5, RichTextSpan(text: 'a' * 5));
    assert(node2.spans.length == 1);

    offset = 0;
    for (var span in node2.spans) {
      assert(span.offset == offset);
      offset += span.textLength;
    }
  });

  test('merge', () {
    final newNode = basicNode();
    final node1 = newNode.merge(basicNode());
    assert(node1.spans.length == 1);
    int offset = 0;
    for (var span in node1.spans) {
      assert(span.offset == offset);
      offset += span.textLength;
    }

    final node2 = node1.merge(newNode);
    assert(node2.spans.length == 1);
    offset = 0;
    for (var span in node1.spans) {
      assert(span.offset == offset);
      offset += span.textLength;
    }

    expect(() => newNode.merge(TestEditorNode()),
        throwsA(const TypeMatcher<UnableToMergeException>()));
  });

  test('update', () {
    int i = 0;
    final newNode = basicNode(
        generator: (text, offset) =>
            RichTextSpan(text: text, offset: offset, tags: {'${i++}'}));
    final node1 = newNode.update(0, RichTextSpan(text: 'a' * 5));
    assert(node1.spans.length == constTexts.length);
    assert(node1.spans.first.textLength == 5);
    var offset = 0;
    for (var span in node1.spans) {
      assert(span.offset == offset);
      offset += span.textLength;
    }

    final node2 = newNode.update(5, RichTextSpan(text: 'a' * 5));
    assert(node2.spans.length == constTexts.length);
    assert(node2.spans[5].textLength == 5);
    offset = 0;
    for (var span in node2.spans) {
      assert(span.offset == offset);
      offset += span.textLength;
    }

    final node3 =
        newNode.update(newNode.spans.length - 1, RichTextSpan(text: 'a' * 5));
    assert(node3.spans.length == constTexts.length);
    assert(node3.spans.last.textLength == 5);
    offset = 0;
    for (var span in node3.spans) {
      assert(span.offset == offset);
      offset += span.textLength;
    }
  });

  test('replace', () {
    final newNode = basicNode();
    const newId = '111';
    final node1 = newNode
        .replace(newNode.beginPosition, newNode.endPosition, [], newId: newId);
    assert(node1.id == newId);
    assert(newNode.id != newId);
    var offset = 0;
    for (var span in node1.spans) {
      assert(span.offset == offset);
      offset += span.textLength;
    }

    final node2 = node1.replace(RichTextNodePosition.zero(),
        RichTextNodePosition.zero(), [RichTextSpan(text: 'abc')]);
    assert(node2.spans.length == 1);
    offset = 0;
    for (var span in node2.spans) {
      assert(span.offset == offset);
      offset += span.textLength;
    }

    final node3 = newNode
        .replace(RichTextNodePosition(3, 0), RichTextNodePosition(5, 0), []);
    assert(node3.spans.length == 1);
    offset = 0;
    for (var span in node3.spans) {
      assert(span.offset == offset);
      offset += span.textLength;
    }

    final node4 = newNode.replace(RichTextNodePosition(3, 0),
        RichTextNodePosition(5, 0), [RichTextSpan(text: 'x')]);
    assert(node4.spans.length == 1);
    offset = 0;
    for (var span in node4.spans) {
      assert(span.offset == offset);
      offset += span.textLength;
    }

    final node5 = newNode
        .replace(RichTextNodePosition(3, 5), RichTextNodePosition(7, 9), [
      RichTextSpan(text: 'abc', tags: {'a'}),
      RichTextSpan(text: '123', tags: {'b'}),
      RichTextSpan(text: 'xyz'),
    ]);
    assert(node5.spans.length == 4);
    offset = 0;
    for (var span in node5.spans) {
      assert(span.offset == offset);
      offset += span.textLength;
    }

    final node6 = newNode
        .replace(RichTextNodePosition(2, 1), RichTextNodePosition(2, 13), [
      RichTextSpan(text: 'abc'),
      RichTextSpan(text: '123'),
      RichTextSpan(text: 'xyz'),
    ]);
    assert(node6.spans.length == 1);
    offset = 0;
    for (var span in node6.spans) {
      assert(span.offset == offset);
      offset += span.textLength;
    }

    final node7 = RichTextNode.from([])
        .replace(RichTextNodePosition.zero(), RichTextNodePosition.zero(), []);
    assert(node7.spans.length == 1);
  });

  test('delete', () {
    int i = 0;
    final newNode = basicNode(
        texts: ['abc', 'xyz', 'l'],
        generator: (text, offset) =>
            RichTextSpan(text: text, offset: offset, tags: {'${i++}'}));
    final np1 =
        newNode.delete(RichTextNodePosition(0, newNode.spans.first.textLength));
    assert((np1.position as EditingPosition).position is RichTextNodePosition);
    assert(((np1.position as EditingPosition).position as RichTextNodePosition)
            .offset ==
        newNode.spans.first.textLength - 1);
    final node1 = np1.node as RichTextNode;
    assert(node1.spans.first.text == 'ab');
    expect(() => newNode.delete(RichTextNodePosition(0, 0)),
        throwsA(const TypeMatcher<DeleteRequiresNewLineException>()));

    final np2 = newNode.delete(RichTextNodePosition(0, 1));
    final node2 = np2.node as RichTextNode;
    assert(node2.spans.first.text == 'bc');
    assert(np2.position is EditingPosition);

    final np3 = newNode.delete(RichTextNodePosition(1, 0));
    assert(np3.position is EditingPosition);
    final node3 = np3.node as RichTextNode;
    assert(node3.spans.first.text == 'ab');

    final np4 = newNode.delete(RichTextNodePosition(2, 1));
    assert(np4.position is EditingPosition);
    assert(((np4.position as EditingPosition).position as RichTextNodePosition)
            .offset ==
        newNode.spans[1].textLength);
    final node4 = np4.node as RichTextNode;
    assert(node4.spans.length == 2);
  });

  test('buildTextSpan', () {
    final newNode = basicNode(texts: ['aaaaaa', 'bbbbbb', 'cccccc']);
    final span1 = newNode.buildTextSpan();
    assert(span1.children != null);
    assert(span1.children!.length == newNode.spans.length);

    final styleNode = basicNode(
        generator: (text, offset) => RichTextSpan(
                text: text,
                offset: offset,
                tags: {
                  RichTextTag
                      .values[Random().nextInt(RichTextTag.values.length)].name
                }));
    final span2 = styleNode.buildTextSpan();
    for (var i = 0; i < styleNode.spans.length; ++i) {
      var richTextSpan = styleNode.spans[i];
      var inlineSpan = span2.children![i] as TextSpan;
      var style = inlineSpan.style!;
      final tag = richTextSpan.tags.first;
      if (tag != RichTextTag.link.name) {
        var mergeStyle = style.merge(tag2Style[tag]);
        assert(style == mergeStyle);
      }
    }
  });

  test('merge', () {
    final node1 = basicNode(texts: ['aaa', 'bbb']);
    final node2 = basicNode(texts: ['ccc', 'ddd']);
    final node3 = basicNode(
        texts: ['mmm', 'nnn'],
        generator: (text, offset) => RichTextSpan(
            text: text, offset: offset, tags: {RichTextTag.bold.name}));
    final node4 = basicNode(
        texts: ['xxx', 'yyy'],
        generator: (text, offset) => RichTextSpan(
            text: text, offset: offset, tags: {RichTextTag.bold.name}));
    final node5 = basicNode(
        texts: ['zzz', 'ZZZ'],
        generator: (text, offset) => RichTextSpan(
            text: text, offset: offset, tags: {RichTextTag.italic.name}));
    final mergeNode1 = node1.merge(node2);
    assert(mergeNode1.text == node1.text + node2.text);
    assert(mergeNode1.spans.length == 1);

    final mergeNode2 = node2.merge(node3);
    assert(mergeNode2.text == node2.text + node3.text);
    assert(mergeNode2.spans.length == 2);

    final mergeNode3 = node3.merge(node4);
    assert(mergeNode3.text == node3.text + node4.text);
    assert(mergeNode3.spans.length == 1);

    final mergeNode4 = node4.merge(node5);
    assert(mergeNode4.text == node4.text + node5.text);
    assert(mergeNode4.spans.length == 2);

    final mergeNode6 = node1.merge(node3).merge(node5);
    assert(mergeNode6.text == node1.text + node3.text + node5.text);
    assert(mergeNode6.spans.length == 3);
  });

  test('toJson', () {
    final newNode = basicNode(texts: ['aaa', 'bbb']);
    final json = newNode.toJson();
    final nodes = json['nodes'] as List<Map<String, dynamic>>;
    for (var n in nodes) {
      assert(n.keys.contains('attributes'));
      assert(n.keys.contains('text'));
      assert(!n.keys.contains('tags'));
    }
  });

  test('build', () {
    final newNode = basicNode(texts: ['aaa', 'bbb']);
    final widget = newNode.build(NodeController.empty,
        EditingPosition(RichTextNodePosition(0, 0)), null);
    assert(widget is RichTextWidget);
  });

  test('insertByPosition', () {
    final newNode = basicNode(texts: ['aaa', 'bbb']);
    final node1 = newNode.insertByPosition(
        RichTextNodePosition(0, 1), RichTextSpan(text: 'AA'));
    assert(node1.text == 'aAAaabbb');
    assert(node1.spans.length == 1);

    final node2 = newNode.insertByPosition(
        RichTextNodePosition(0, 1), RichTextSpan(text: 'AA', tags: {'a'}));
    assert(node2.text == 'aAAaabbb');
    assert(node2.spans.length == 3);

    final node3 = newNode.insertByPosition(
        RichTextNodePosition(0, 1), RichTextSpan(text: '', tags: {'a'}));
    assert(node3.text == 'aaabbb');
    assert(node3.spans.length == 1);

    final node4 = newNode.insertByPosition(
        RichTextNodePosition(0, 1), RichTextSpan(text: '', tags: {'a'}));
    assert(node4.text == 'aaabbb');
    assert(node4.spans.length == 1);

    final node5 = newNode.insertByPosition(
        RichTextNodePosition(0, 1), RichTextSpan(text: 'AA', tags: {'a'}));
    assert(node5.text == 'aAAaabbb');
    assert(node5.spans.length == 3);
  });

  test('remove', () {
    final newNode = basicNode();
    final node1 =
        newNode.remove(RichTextNodePosition(0, 0), RichTextNodePosition(1, 0));
    assert(node1.spans.length == 1);
    assert(node1.text == constTexts.join().replaceFirst(constTexts[0], ''));

    final node2 =
        newNode.remove(RichTextNodePosition(1, 0), RichTextNodePosition(0, 0));
    assert(node2.text == node1.text);

    final node3 = newNode.remove(RichTextNodePosition(0, 0),
        RichTextNodePosition(constTexts.length - 1, 0));
    assert(node3.text == constTexts.last);

    final node4 = newNode.remove(RichTextNodePosition(0, 0),
        RichTextNodePosition(constTexts.length - 1, constTexts.last.length));
    assert(node4.text.isEmpty);

    final node5 =
        newNode.remove(RichTextNodePosition(3, 0), RichTextNodePosition(5, 0));
    final guessText =
        constTexts.sublist(0, 3).join() + constTexts.skip(5).join();
    assert(node5.text == guessText);
  });

  test('getPositionByOffset', () {
    int i = 0;
    final newNode = basicNode(
        generator: (text, offset) =>
            RichTextSpan(text: text, offset: offset, tags: {'${i++}'}));
    i = 0;
    int offset = 0;
    for (var text in constTexts) {
      final p1 = newNode.getPositionByOffset(offset);
      offset += text.length;
      assert(p1.index == i ||
          (p1.index == i - 1 && p1.offset == constTexts[i - 1].length));
      i++;
    }
  });

  test('buildSpansByAddingTag', () {
    final newNode = basicNode();
    for (var span in newNode.spans) {
      assert(span.tags.isEmpty);
    }

    final spanList1 = newNode.buildSpansByAddingTag('tag');
    for (var span in spanList1) {
      assert(span.tags.length == 1);
      assert(span.tags.contains('tag'));
    }
  });

  test('buildSpansByAddingTag', () {
    final newNode = basicNode(
        generator: (text, offset) =>
            RichTextSpan(text: text, offset: offset, tags: {'tag'}));

    for (var span in newNode.spans) {
      assert(span.tags.length == 1);
      assert(span.tags.first == 'tag');
    }

    final spanList1 = newNode.buildSpansByRemovingTag('tag');
    for (var span in spanList1) {
      assert(span.tags.isEmpty);
    }

    final spanList2 = newNode.buildSpansByRemovingTag('xxx');
    for (var span in spanList2) {
      assert(span.tags.isNotEmpty);
    }
  });

  test('lastPosition', () {
    final newNode = basicNode(texts: ['', '', 'aaa', 'bbb']);
    expect(() => newNode.lastPosition(RichTextNodePosition(0, 0)),
        throwsA(const TypeMatcher<ArrowLeftBeginException>()));
    expect(() => newNode.lastPosition(RichTextNodePosition(0, 1)),
        throwsA(const TypeMatcher<ArrowLeftBeginException>()));
    expect(() => newNode.lastPosition(RichTextNodePosition(1, 0)),
        throwsA(const TypeMatcher<ArrowLeftBeginException>()));
    expect(() => newNode.lastPosition(RichTextNodePosition(2, 0)),
        throwsA(const TypeMatcher<ArrowLeftBeginException>()));

    final p1 = newNode.lastPosition(RichTextNodePosition(2, 1));
    assert(p1 == RichTextNodePosition(2, 0));

    final p2 = newNode.lastPosition(RichTextNodePosition(2, 2));
    assert(p2 == RichTextNodePosition(2, 1));

    final p3 = newNode.lastPosition(RichTextNodePosition(3, 0));
    assert(p3 == RichTextNodePosition(2, 2));

    final p4 = newNode.lastPosition(RichTextNodePosition(3, 3));
    assert(p4 == RichTextNodePosition(3, 2));
  });

  test('nextPositionByLength', () {
    final newNode = basicNode(texts: ['aaa', 'bbb', '', '']);
    expect(() => newNode.nextPositionByLength(RichTextNodePosition(1, 3), 1),
        throwsA(const TypeMatcher<ArrowRightEndException>()));
    expect(() => newNode.nextPositionByLength(RichTextNodePosition(2, 0), 1),
        throwsA(const TypeMatcher<ArrowRightEndException>()));
    expect(() => newNode.nextPositionByLength(RichTextNodePosition(0, 0), 6),
        throwsA(const TypeMatcher<ArrowRightEndException>()));
    expect(() => newNode.nextPositionByLength(RichTextNodePosition(0, 3), 3),
        throwsA(const TypeMatcher<ArrowRightEndException>()));
    expect(() => newNode.nextPositionByLength(RichTextNodePosition(1, 0), 3),
        throwsA(const TypeMatcher<ArrowRightEndException>()));
    expect(() => newNode.nextPositionByLength(RichTextNodePosition(1, 1), 2),
        throwsA(const TypeMatcher<ArrowRightEndException>()));

    final p1 = newNode.nextPosition(RichTextNodePosition(0, 0));
    assert(p1 == RichTextNodePosition(0, 1));

    final p2 = newNode.nextPosition(RichTextNodePosition(0, 3));
    assert(p2 == RichTextNodePosition(1, 1));

    final p3 = newNode.nextPosition(RichTextNodePosition(1, 1));
    assert(p3 == RichTextNodePosition(1, 2));
  });

  test('nextPosition', () {
    final newNode = basicNode(texts: ['aaa', 'bbb', '', '']);
    expect(() => newNode.nextPosition(RichTextNodePosition(1, 3)),
        throwsA(const TypeMatcher<ArrowRightEndException>()));
    expect(() => newNode.nextPosition(RichTextNodePosition(2, 0)),
        throwsA(const TypeMatcher<ArrowRightEndException>()));
    expect(() => newNode.nextPosition(RichTextNodePosition(3, 0)),
        throwsA(const TypeMatcher<ArrowRightEndException>()));

    final p1 = newNode.nextPosition(RichTextNodePosition(0, 0));
    assert(p1 == RichTextNodePosition(0, 1));

    final p2 = newNode.nextPosition(RichTextNodePosition(0, 3));
    assert(p2 == RichTextNodePosition(1, 1));

    final p3 = newNode.nextPosition(RichTextNodePosition(1, 1));
    assert(p3 == RichTextNodePosition(1, 2));
  });

  test('newIdNode', () {
    final newNode = basicNode();
    final node1 = newNode.newNode(id: 'aaa') as RichTextNode;
    assert(node1.id == 'aaa');
    assert(newNode.id != node1.id);
    assert(newNode.text == node1.text);
    assert(newNode.spans.length == node1.spans.length);
  });

  test('onEdit', () {
    ///TODO:complete the test logic in other places
    final newNode = basicNode();
    for (var t in EventType.values) {
      try {
        newNode.onEdit(
            EditingData(RichTextNodePosition.zero(), t, ListenerCollection()));
      } catch (e) {
        print('e:$e');
      }
    }
  });

  test('onSelect', () {
    ///TODO:complete the test logic in other places
    final newNode = basicNode();
    for (var t in EventType.values) {
      try {
        newNode.onSelect(SelectingData(
            SelectingPosition(
                RichTextNodePosition.zero(), RichTextNodePosition(1, 1)),
            t,
            ListenerCollection()));
      } catch (e) {
        print('e:$e');
      }
    }
  });
}