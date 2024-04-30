import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_highlight/themes/atelier-heath-dark.dart';
import 'package:flutter_highlight/themes/atelier-heath-light.dart';
import 'package:highlight/highlight.dart' show Node, highlight;

import '../../../../editor/extension/render_box.dart';
import '../../../../editor/extension/painter.dart';
import '../../core/input_manager.dart';
import '../../core/listener_collection.dart';
import '../../core/logger.dart';
import '../editing_cursor.dart';
import '../painter.dart';

class CodeBlockLine extends StatefulWidget {
  final String code;
  final String language;
  final CodeNodeController controller;
  final int? editingOffset;
  final TextRange? selectingOffset;
  final TextStyle? style;
  final bool dark;

  const CodeBlockLine(
      {super.key,
      required this.code,
      required this.language,
      required this.controller,
      this.editingOffset,
      this.style,
      required this.dark,
      this.selectingOffset});

  @override
  State<CodeBlockLine> createState() => _CodeBlockLineState();
}

class _CodeBlockLineState extends State<CodeBlockLine> {
  late ValueNotifier<int?> editingCursorNotifier;
  late ValueNotifier<TextRange?> selectingCursorNotifier;
  late ValueNotifier<String> codeNotifier;
  late TextPainter painter;

  final key = GlobalKey();

  String get code => widget.code;

  String get language => widget.language;

  int? get editingOffset => widget.editingOffset;

  TextRange? get selectingOffset => widget.selectingOffset;

  CodeNodeController get controller => widget.controller;

  ListenerCollection get listeners => controller.listeners;

  RenderBox? get renderBox {
    if (!mounted) return null;
    return key.currentContext?.findRenderObject() as RenderBox?;
  }

  double? get y => renderBox?.localToGlobal(Offset.zero).dy;

  @override
  void initState() {
    super.initState();
    editingCursorNotifier = ValueNotifier(editingOffset);
    selectingCursorNotifier = ValueNotifier(selectingOffset);
    codeNotifier = ValueNotifier(code);
    painter = TextPainter(
        textAlign: TextAlign.justify,
        textDirection: TextDirection.ltr,
        maxLines: 1,
        text: span);
    painter.layout();
    listeners.addGestureListener(onGesture);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      tryToUpdateInputAttribute();
      notifyEditingOffset(editingOffset);
    });
  }

  @override
  void didUpdateWidget(covariant CodeBlockLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool needRefresh = false;
    if (codeNotifier.value != code) {
      codeNotifier.value = code;
      needRefresh = true;
    }
    if (editingCursorNotifier.value != editingOffset) {
      editingCursorNotifier.value = editingOffset;
      tryToUpdateInputAttribute();
    }
    if (selectingCursorNotifier.value != selectingOffset) {
      selectingCursorNotifier.value = selectingOffset;
      tryToUpdateInputAttribute();
    }
    if (oldWidget.dark != widget.dark) needRefresh = true;
    if (oldWidget.language != language) needRefresh = true;
    if (needRefresh) {
      painter.text = span;
      painter.layout();
    }
  }

  @override
  void dispose() {
    painter.dispose();
    listeners.removeGestureListener(onGesture);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    return SizedBox(
      key: key,
      height: painter.height,
      width: max(size.width, painter.width),
      child: Stack(
        children: [
          ValueListenableBuilder(
              valueListenable: codeNotifier,
              builder: (ctx, v, c) {
                return CustomPaint(
                  painter: RichTextPainter(painter),
                  child: SizedBox(height: painter.height, width: painter.width),
                );
              }),
          ValueListenableBuilder(
              valueListenable: editingCursorNotifier,
              builder: (ctx, v, c) {
                if (v == null) return Container();
                final offset = painter.getOffsetFromTextOffset(v);
                return Positioned(
                  left: offset.dx,
                  top: 0,
                  child: EditingCursorWidget(
                    cursorColor:
                        theme.textTheme.bodyMedium?.color ?? Colors.black,
                    cursorHeight: painter.height,
                  ),
                );
              }),
          ValueListenableBuilder(
              valueListenable: selectingCursorNotifier,
              builder: (ctx, v, c) {
                if (v == null) return Container();
                return Stack(
                    children: painter.buildSelectedAreas(v.start, v.end));
              }),
        ],
      ),
    );
  }

  InlineSpan get span => TextSpan(
      children: convert(highlight.parse(code, language: language).nodes ?? [],
          widget.dark ? atelierHeathDarkTheme : atelierHeathLightTheme),
      style: widget.style);

  List<TextSpan> convert(List<Node> nodes, Map<String, TextStyle> theme) {
    List<TextSpan> spans = [];
    var currentSpans = spans;
    List<List<TextSpan>> stack = [];

    traverse(Node node) {
      if (node.value != null) {
        currentSpans.add(node.className == null
            ? TextSpan(text: node.value)
            : TextSpan(text: node.value, style: theme[node.className!]));
      } else if (node.children != null) {
        List<TextSpan> tmp = [];
        currentSpans
            .add(TextSpan(children: tmp, style: theme[node.className!]));
        stack.add(currentSpans);
        currentSpans = tmp;

        for (var n in node.children!) {
          traverse(n);
          if (n == node.children!.last) {
            currentSpans = stack.isEmpty ? spans : stack.removeLast();
          }
        }
      }
    }

    for (var node in nodes) {
      traverse(node);
    }
    return spans;
  }

  void onGesture(GestureState s) {
    switch (s.type) {
      case GestureType.tap:
        onTapped(s.globalOffset);
        break;
      case GestureType.panUpdate:
        onPanUpdate(s.globalOffset);
        break;
      case GestureType.hover:
        break;
    }
  }

  void onTapped(Offset globalOffset) {
    if (!containsY(globalOffset)) return;
    final off = buildTextPosition(globalOffset).offset;
    controller.onEditingPosition.call(off);
    controller.onEditingOffsetChanged.call(globalOffset);
    updateInputAttribute(off);
  }

  void onPanUpdate(Offset global) {
    if (!containsY(global)) return;
    final box = renderBox;
    if (box == null) return;
    logger.i('code_block_inline,  onPanUpdate:$global');
    final widgetPosition = box.localToGlobal(Offset.zero);
    final localPosition =
        global.translate(-widgetPosition.dx, -widgetPosition.dy);
    final textPosition = painter.getPositionForOffset(localPosition);
    controller.onPanUpdatePosition.call(textPosition.offset);
  }

  bool containsY(Offset global) => renderBox?.containsY(global.dy) ?? false;

  TextPosition buildTextPosition(Offset p) =>
      painter.buildTextPosition(p, renderBox);

  void tryToUpdateInputAttribute() {
    if (editingOffset != null) {
      updateInputAttribute(editingOffset!);
    }
  }

  void updateInputAttribute(int off) {
    final box = renderBox;
    if (box == null) return;
    final offset = painter.getOffsetFromTextOffset(off);
    final height = painter.height;
    controller.onInputConnectionAttribute.call(InputConnectionAttribute(
        Rect.fromPoints(offset, offset.translate(0, height)),
        box.getTransformTo(null),
        box.size));
  }

  void notifyEditingOffset(int? offset) {
    final o = offset;
    if (o != null && y != null) {
      final cursorY = painter.height;
      final offset = painter.getOffsetFromTextOffset(o);
      controller.onEditingOffsetChanged.call(Offset(offset.dx, cursorY + y!));
    }
  }
}

class CodeNodeController {
  final ValueChanged<int> onEditingPosition;
  final ValueChanged<InputConnectionAttribute> onInputConnectionAttribute;
  final ValueChanged<int> onPanUpdatePosition;
  final ValueChanged<Offset> onEditingOffsetChanged;
  final ListenerCollection listeners;

  CodeNodeController({
    required this.onEditingPosition,
    required this.onInputConnectionAttribute,
    required this.onPanUpdatePosition,
    required this.listeners,
    required this.onEditingOffsetChanged,
  });
}
