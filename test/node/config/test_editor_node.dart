import 'package:crayon/editor/core/node_controller.dart';
import 'package:crayon/editor/cursor/node_position.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:crayon/editor/cursor/basic.dart';
import 'package:crayon/editor/node/basic.dart';

class TestEditorNode extends EditorNode {
  @override
  // TODO: implement beginPosition
  NodePosition get beginPosition => throw UnimplementedError();

  @override
  Widget build(
      NodeController controller, SingleNodePosition? position, dynamic extras) {
    // TODO: implement build
    throw UnimplementedError();
  }

  @override
  // TODO: implement endPosition
  NodePosition get endPosition => throw UnimplementedError();

  @override
  EditorNode frontPartNode(NodePosition end, {String? newId}) {
    // TODO: implement frontPartNode
    throw UnimplementedError();
  }

  @override
  EditorNode getFromPosition(NodePosition begin, NodePosition end,
      {String? newId}) {
    // TODO: implement getFromPosition
    throw UnimplementedError();
  }

  @override
  EditorNode merge(EditorNode other, {String? newId}) {
    // TODO: implement merge
    throw UnimplementedError();
  }

  @override
  EditorNode newNode({String? id, int? depth}) {
    // TODO: implement newIdNode
    throw UnimplementedError();
  }

  @override
  NodeWithPosition<NodePosition> onEdit(EditingData<NodePosition> data) {
    // TODO: implement onEdit
    throw UnimplementedError();
  }

  @override
  NodeWithPosition<NodePosition> onSelect(SelectingData<NodePosition> data) {
    // TODO: implement onSelect
    throw UnimplementedError();
  }

  @override
  EditorNode rearPartNode(NodePosition begin, {String? newId}) {
    // TODO: implement rearPartNode
    throw UnimplementedError();
  }

  @override
  // TODO: implement text
  String get text => throw UnimplementedError();

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }

  @override
  List<EditorNode> getInlineNodesFromPosition(
      NodePosition begin, NodePosition end) {
    // TODO: implement getInlineNodesFromPosition
    throw UnimplementedError();
  }
}
