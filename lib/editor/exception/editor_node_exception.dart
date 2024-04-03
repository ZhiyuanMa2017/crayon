import 'dart:ui';

import '../cursor/basic_cursor.dart';
import '../shortcuts/arrows/arrows.dart';
import 'basic_exception.dart';

class UnableToMergeException implements EditorNodeException {
  final String origin;
  final String other;

  UnableToMergeException(this.origin, this.other);

  String get message => 'origin:$origin cannot match other:$other!';

  @override
  String toString() {
    return 'UnableToMergeException{origin: $origin, other: $other}';
  }
}

class DeleteRequiresNewLineException implements EditorNodeException {
  final Type type;

  DeleteRequiresNewLineException(this.type);

  String get message => 'the $type is requiring a new line';

  @override
  String toString() {
    return 'DeleteRequiresNewLineException{type: $type}';
  }
}

class NewlineRequiresNewNode implements EditorNodeException {
  final Type type;

  NewlineRequiresNewNode(this.type);

  String get message => 'the $type is requiring insert a new node';

  @override
  String toString() {
    return 'NewlineRequiresNewNode{type: $type}';
  }
}

class DeleteNotAllowedException implements EditorNodeException {
  final Type type;

  DeleteNotAllowedException(this.type);

  String get message => 'the $type node cannot be deleted anymore!';

  @override
  String toString() {
    return 'DeleteNotAllowedException{type: $type}';
  }
}

class NodePositionDifferentException implements EditorNodeException {
  final Type origin;
  final Type other;

  NodePositionDifferentException(this.origin, this.other);

  String get message => 'the origin:$origin is not same as other:$other';

  @override
  String toString() {
    return 'NodePositionDifferentException{origin: $origin, other: $other}';
  }
}

class NodePositionInvalidException implements EditorNodeException {
  final String reason;

  NodePositionInvalidException(this.reason);

  String get message => 'the node position is invalid, $reason';

  @override
  String toString() {
    return 'NodePositionInvalidException{reason: $reason}';
  }
}

class ArrowIsEndException implements EditorNodeException {
  final ArrowType type;
  final NodePosition position;

  ArrowIsEndException(this.type, this.position);

  String get message =>
      'the position $position with arrow $type is end in current node!';

  @override
  String toString() {
    return 'ArrowIsEndException{type: $type, position: $position}';
  }
}

class ArrowLeftBeginException implements EditorNodeException {
  final NodePosition position;

  ArrowLeftBeginException(this.position);

  String get message =>
      'the position $position is in begin, cannot move to left any more!';
}

class ArrowRightEndException implements EditorNodeException {
  final NodePosition position;

  ArrowRightEndException(this.position);

  String get message =>
      'the position $position is in end, cannot move to right any more!';
}

class ArrowUpTopException implements EditorNodeException {
  final NodePosition position;
  final Offset offset;

  ArrowUpTopException(this.position, this.offset);

  String get message =>
      'the position $position with $offset is in top, cannot move up any more!';
}

class ArrowDownBottomException implements EditorNodeException {
  final NodePosition position;
  final Offset offset;

  ArrowDownBottomException(this.position, this.offset);

  String get message =>
      'the position $position with $offset is in bottom, cannot move down any more!';
}