import 'package:flutter/material.dart';

import '../command/basic_command.dart';
import '../cursor/basic_cursor.dart';
import '../exception/command_exception.dart';
import 'command_invoker.dart';
import 'controller.dart';
import 'input_manager.dart';
import 'logger.dart';

class EditorContext {
  final RichEditorController controller;
  final CommandInvoker invoker;
  final InputManager inputManager;
  final FocusNode focusNode;

  EditorContext(
      this.controller, this.inputManager, this.invoker, this.focusNode);

  void execute(
    BasicCommand command, {
    bool record = true,
  }) {
    try {
      invoker.execute(command, controller, record: record);
    } on PerformCommandException catch (e) {
      logger.e('$e');
    }
  }

  void undo() {
    try {
      invoker.undo(controller);
    } on PerformCommandException catch (e) {
      logger.e('undo $e');
    }
  }

  void redo() {
    try {
      invoker.redo(controller);
    } on PerformCommandException catch (e) {
      logger.e('redo $e');
    }
  }

  BasicCursor get cursor => controller.cursor;

  bool get typing => inputManager.typing;

  void restartInput() => inputManager.restartInput();

  void requestFocus() {
    if (!focusNode.hasFocus) focusNode.requestFocus();
  }
}