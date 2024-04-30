import 'package:flutter/material.dart';

import '../core/context.dart';
import '../core/logger.dart';
import '../exception/command.dart';

class UndoIntent extends Intent {
  const UndoIntent();
}

class UndoAction extends ContextAction<UndoIntent> {
  final EditorContext editorContext;

  UndoAction(this.editorContext);

  @override
  void invoke(Intent intent, [BuildContext? context]) {
    logger.i('$runtimeType is invoking!');
    try {
      editorContext.undo();
    } on NoCommandException catch (e) {
      logger.e('$e');
    } on PerformCommandException catch (e) {
      logger.e('undo error: $e');
    }
  }
}
