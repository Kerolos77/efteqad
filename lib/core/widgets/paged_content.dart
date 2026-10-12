import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/page_result.dart';
import '../models/snapshot_list.dart';
import '../localization/app_localizations.dart';
import 'async_content.dart';

class PagedContent<T> extends StatefulWidget {
  final Object queryKey;
  final Future<PageResult<T>> Function(DocumentSnapshot? cursor) fetch;
  final Widget Function(BuildContext, List<T>, Widget? more) builder;
  final Widget? emptyWidget;
  final bool showEmptyAsContent;
  const PagedContent({
    super.key,
    required this.queryKey,
    required this.fetch,
    required this.builder,
    this.emptyWidget,
    this.showEmptyAsContent = false,
  });
  @override
  State<PagedContent<T>> createState() => _PagedContentState<T>();
}

class _PagedContentState<T> extends State<PagedContent<T>> {
  List<T>? _items;
  DocumentSnapshot? _cursor;
  bool _loading = true, _more = false, _cached = false, _pending = false;
  Object? _error;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void didUpdateWidget(covariant PagedContent<T> old) {
    super.didUpdateWidget(old);
    if (old.queryKey != widget.queryKey) _reset();
  }

  void _reset() {
    _generation++;
    _cached = false;
    _pending = false;
    _items = null;
    _cursor = null;
    _error = null;
    _loading = true;
    _load();
  }

  Future<void> _load() async {
    final generation = _generation;
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final page = await widget.fetch(_cursor);
      if (!mounted || generation != _generation) return;
      final metadata = page.items is ReadMetadata
          ? page.items as ReadMetadata
          : null;
      setState(() {
        _items = [...?_items, ...page.items];
        _cursor = page.cursor;
        _more = page.hasMore;
        _cached = _cached || (metadata?.isFromCache ?? false);
        _pending = _pending || (metadata?.hasPendingWrites ?? false);
        _loading = false;
      });
    } catch (e) {
      if (mounted && generation == _generation) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AsyncContent<List<T>>(
    isLoading: _loading && _items == null,
    error: _error,
    data: _items == null
        ? null
        : SnapshotList(
            _items!,
            isFromCache: _cached,
            hasPendingWrites: _pending,
          ),
    isEmpty: (items) => !widget.showEmptyAsContent && items.isEmpty,
    emptyWidget: widget.emptyWidget,
    onRetry: _load,
    builder: (context, items) => widget.builder(
      context,
      items,
      _more
          ? Padding(
              padding: const EdgeInsets.all(12),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : TextButton(
                      onPressed: _load,
                      child: Text(context.tr.loadMore),
                    ),
            )
          : null,
    ),
  );
}
