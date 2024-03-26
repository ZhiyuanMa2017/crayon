import 'package:pre_editor/editor/extension/collection_extension.dart';

import '../../../core/logger.dart';
import '../../../cursor/rich_text_cursor.dart';
import '../../basic_node.dart';
import '../../position_data.dart';
import '../rich_text_node.dart';
import '../rich_text_span.dart';

NodeWithPosition styleRichTextNodeWhileEditing(
    EditingData<RichTextNodePosition> data, RichTextNode node, String tag) {
  final position = data.position;
  final offset = node.getOffset(position);
  final currentSpan = node.getSpan(position.index);
  bool needAddTag = !currentSpan.tags.contains(tag);
  logger.i("styles,needAddTag:$needAddTag span:$currentSpan");
  RichTextNode newNode;
  RichTextNodePosition newPosition;
  if (needAddTag) {
    newNode = node.insertByPosition(position, RichTextSpan(tags: {tag}));
  } else {
    if (currentSpan.isEmpty) {
      newNode = node.update(position.index,
          currentSpan.copy(tags: (tags) => tags.removeOne(tag)));
    } else {
      newNode = node.insertByPosition(position, RichTextSpan());
    }
  }
  newPosition = newNode.getPositionByOffset(offset);
  var span = newNode.getSpan(newPosition.index);
  logger.i("styles,newPosition:$newPosition span:$span");

  ///FIXME: the code is too ugly, try to fix it!!!
  if ((needAddTag && !span.tags.contains(tag)) ||
      (!needAddTag && span.tags.contains(tag))) {
    try {
      span = newNode.getSpan(newPosition.index + 1);
      logger.i('new new span:$span');
      if ((span.tags.contains(tag) && needAddTag) ||
          (!span.tags.contains(tag) && !needAddTag)) {
        newPosition =
            RichTextNodePosition(newPosition.index + 1, span.textLength);
      }
    } on RangeError catch (e) {
      logger.e('style error $newPosition,  span:$span, error:$e');
    }
  }
  return NodeWithPosition(newNode, EditingPosition(newPosition));
}

NodeWithPosition styleRichTextNodeWhileSelecting(
    SelectingData<RichTextNodePosition> data, RichTextNode node, String tag) {
  final left = data.left;
  final right = data.right;
  final leftOffset = node.getOffset(left);
  final rightOffset = node.getOffset(right);
  final selectingNode = node.getFromPosition(left, right, trim: true);
  bool needAddTag = false;
  for (var span in selectingNode.spans) {
    if (!span.tags.contains(tag)) {
      needAddTag = true;
      break;
    }
  }
  final newSpans = needAddTag
      ? selectingNode.buildSpansByAddingTag(tag)
      : selectingNode.buildSpansByRemovingTag(tag);
  final newNode = node.replace(left, right, newSpans);
  return NodeWithPosition(
      newNode,
      SelectingPosition(newNode.getPositionByOffset(leftOffset),
          newNode.getPositionByOffset(rightOffset)));
}