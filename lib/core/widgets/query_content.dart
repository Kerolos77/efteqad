import 'package:flutter/material.dart';
import 'async_content.dart';

/// Owns a stable subscription and recreates it on a new scope or explicit retry.
class QueryContent<T> extends StatefulWidget {
  final Object queryKey;
  final Stream<T> Function() query;
  final Widget Function(BuildContext, T) builder;
  final bool Function(T)? isEmpty;
  final Widget? emptyWidget;
  const QueryContent({
    super.key,
    required this.queryKey,
    required this.query,
    required this.builder,
    this.isEmpty,
    this.emptyWidget,
  });
  @override
  State<QueryContent<T>> createState() => _QueryContentState<T>();
}

class _QueryContentState<T> extends State<QueryContent<T>> {
  late Stream<T> _stream;
  int _revision = 0;
  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  void _subscribe() {
    _stream = widget.query();
    _revision++;
  }

  @override
  void didUpdateWidget(covariant QueryContent<T> old) {
    super.didUpdateWidget(old);
    if (widget.queryKey != old.queryKey) _subscribe();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<T>(
    key: ValueKey(_revision),
    stream: _stream,
    builder: (context, snapshot) => AsyncContent<T>.fromSnapshot(
      snapshot: snapshot,
      isEmpty: widget.isEmpty,
      emptyWidget: widget.emptyWidget,
      onRetry: () => setState(_subscribe),
      builder: widget.builder,
    ),
  );
}
