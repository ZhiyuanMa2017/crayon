import 'package:crayon/editor/node/rich_text_node/rich_text_node.dart';

import '../../../../editor/extension/string_extension.dart';
import '../../../../editor/extension/unmodifiable_extension.dart';

import '../../../cursor/code_block_cursor.dart';
import '../../basic_node.dart';
import '../../position_data.dart';
import '../code_block_node.dart';

NodeWithPosition deleteWhileEditing(
    EditingData<CodeBlockPosition> data, CodeBlockNode node) {
  final p = data.position;
  if (p == node.beginPosition.copy(inEdge: false) || p == node.beginPosition) {
    return NodeWithPosition(node, SelectingPosition(node.beginPosition, node.endPosition));
  }
  final index = p.index;
  final lastIndex = index - 1;
  final codes = node.codes;
  if (p.offset == 0) {
    final code = codes[lastIndex] + codes[index];
    final newPosition = CodeBlockPosition(lastIndex, codes[lastIndex].length);
    return NodeWithPosition(
        node.from(codes.replaceMore(lastIndex, lastIndex + 2, [code])),
        EditingPosition(newPosition));
  } else {
    final codeWithOffset = codes[index].removeAt(p.offset);
    final newPosition =
        EditingPosition(CodeBlockPosition(index, codeWithOffset.offset));
    return NodeWithPosition(
        node.from(codes.replaceOne(index, [codeWithOffset.text])), newPosition);
  }
}

NodeWithPosition deleteWhileSelecting(
    SelectingData<CodeBlockPosition> data, CodeBlockNode node) {
  if (data.left == node.beginPosition && data.right == node.endPosition) {
    final newNode = RichTextNode.from([]);
    return NodeWithPosition(newNode, EditingPosition(newNode.beginPosition));
  }
  final newLeft = node.frontPartNode(data.left);
  final newRight = node.rearPartNode(data.right);
  final newNode = newLeft.merge(newRight);
  return NodeWithPosition(newNode, EditingPosition(newLeft.endPosition));
}