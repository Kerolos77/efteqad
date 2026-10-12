import 'package:cloud_firestore/cloud_firestore.dart';

/// Generic model representing a paginated query result page with cursor and metadata.
class PageResult<T> {
  final List<T> items;
  final DocumentSnapshot? cursor;
  final bool hasMore;
  final int? totalCount;

  const PageResult({
    required this.items,
    this.cursor,
    required this.hasMore,
    this.totalCount,
  });

  factory PageResult.empty() {
    return const PageResult(
      items: [],
      cursor: null,
      hasMore: false,
      totalCount: 0,
    );
  }

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  int get length => items.length;

  PageResult<T> copyWith({
    List<T>? items,
    DocumentSnapshot? cursor,
    bool? hasMore,
    int? totalCount,
  }) {
    return PageResult<T>(
      items: items ?? this.items,
      cursor: cursor ?? this.cursor,
      hasMore: hasMore ?? this.hasMore,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}
