import 'package:flutter/material.dart';

import '../command/modification.dart';
import '../command/replacement.dart';
import '../command/selecting/deletion.dart';
import '../command/selecting/depth.dart';
import '../core/context.dart';
import '../core/editor_controller.dart';
import '../core/logger.dart';
import '../cursor/basic.dart';
import '../exception/editor_node.dart';
import '../node/basic.dart';
import '../../../editor/extension/node_context.dart';

class DeleteIntent extends Intent {
  const DeleteIntent();
}

class DeleteAction extends ContextAction<DeleteIntent> {
  final ActionOperator ac;

  NodesOperator get operator => ac.operator;

  BasicCursor get cursor => operator.cursor;

  DeleteAction(this.ac);

  @override
  void invoke(Intent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    final cursor = this.cursor;
    if (cursor is EditingCursor) {
      final index = cursor.index;
      final node = operator.getNode(index);
      try {
        final r = node.onEdit(EditingData(cursor, EventType.delete, operator));
        operator.execute(ModifyNode(r));
      } on DeleteRequiresNewLineException catch (e) {
        logger.e('$runtimeType, ${e.message}');
        if (index == 0) return;
        final lastNode = operator.getNode(index - 1);
        try {
          final newNode = lastNode.merge(node);
          final newNodes = [newNode];
          correctDepth(operator.nodeLength, (i) => operator.getNode(i),
              index + 1, newNode.depth, newNodes,
              limitChildren: false);
          operator.execute(ReplaceNode(Replace(
              index - 1,
              index + newNodes.length,
              newNodes,
              EditingCursor(index - 1, lastNode.endPosition))));
        } on UnableToMergeException catch (e) {
          logger.e('$runtimeType, ${e.message}');
          operator.onCursor(SelectingNodeCursor(
              index - 1, lastNode.beginPosition, lastNode.endPosition));
        }
      } on DeleteToChangeNodeException catch (e) {
        logger.e('$runtimeType, ${e.message}');
        operator.execute(ReplaceNode(Replace(
            index, index + 1, [e.node], EditingCursor(index, e.position))));
      } on NodeUnsupportedException catch (e) {
        logger.e('$runtimeType, ${e.message}');
      }
    } else if (cursor is SelectingNodeCursor) {
      try {
        final r = operator
            .getNode(cursor.index)
            .onSelect(SelectingData(cursor, EventType.delete, operator));
        operator.execute(ModifyNode(r));
      } on NodeUnsupportedException catch (e) {
        logger.e('$runtimeType, ${e.message}');
      }
    } else if (cursor is SelectingNodesCursor) {
      operator.execute(DeletionWhileSelectingNodes(cursor));
    }
  }
}
