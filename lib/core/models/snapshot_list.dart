import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract interface class ReadMetadata {
  bool get isFromCache;
  bool get hasPendingWrites;
}

/// Retains SDK read provenance without changing existing List consumers.
class SnapshotList<T> extends ListBase<T> implements ReadMetadata {
  final List<T> _items;
  @override
  final bool isFromCache;
  @override
  final bool hasPendingWrites;
  SnapshotList(
    Iterable<T> items, {
    required this.isFromCache,
    required this.hasPendingWrites,
  }) : _items = items.toList();
  factory SnapshotList.fromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    T Function(QueryDocumentSnapshot<Map<String, dynamic>>) decode,
  ) => SnapshotList(
    snapshot.docs.map(decode),
    isFromCache: snapshot.metadata.isFromCache,
    hasPendingWrites: snapshot.metadata.hasPendingWrites,
  );
  @override
  int get length => _items.length;
  @override
  set length(int value) => _items.length = value;
  @override
  T operator [](int index) => _items[index];
  @override
  void operator []=(int index, T value) => _items[index] = value;
}
