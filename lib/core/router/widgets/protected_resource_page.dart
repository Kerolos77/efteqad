import 'dart:async';
import 'package:flutter/material.dart';
import '../../errors/app_failure.dart';
import '../../../features/common/presentation/screens/route_error_screen.dart';

/// A server lookup is authoritative; an extra never grants permission.
class ProtectedResourcePage<T> extends StatefulWidget {
  final Future<T?> Function() loadResource;
  final Stream<T?> Function()? watchResource;
  final void Function(T)? authorize;
  final Widget Function(BuildContext context, T data) builder;
  final T? initialData;
  const ProtectedResourcePage({
    super.key,
    required this.loadResource,
    required this.builder,
    this.initialData,
    this.watchResource,
    this.authorize,
  });
  @override
  State<ProtectedResourcePage<T>> createState() =>
      _ProtectedResourcePageState<T>();
}

class _ProtectedResourcePageState<T> extends State<ProtectedResourcePage<T>> {
  StreamSubscription<T?>? _subscription;
  T? _data;
  Object? _error;
  bool _loading = true;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _accept(T? value) {
    try {
      if (value != null) widget.authorize?.call(value);
      setState(() {
        _loading = false;
        _data = value;
        _error = null;
      });
    } catch (error) {
      _fail(error);
    }
  }

  void _fail(Object error) {
    setState(() {
      _loading = false;
      _data = null;
      _error = error;
    });
  }

  Future<void> _load() async {
    final generation = ++_generation;
    await _subscription?.cancel();
    _subscription = null;
    try {
      final data = await widget.loadResource();
      if (!mounted || generation != _generation) return;
      _accept(data);
      _subscription = widget.watchResource?.call().listen(
        (value) {
          if (mounted && generation == _generation) _accept(value);
        },
        onError: (Object error) {
          if (mounted && generation == _generation) _fail(error);
        },
      );
    } catch (error) {
      if (mounted && generation == _generation) _fail(error);
    }
  }

  @override
  void dispose() {
    _generation++;
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      final failure = AppFailure.fromException(_error!);
      return RouteErrorScreen(
        type: failure.code == 'permission-denied'
            ? RouteErrorType.forbidden
            : failure.code == 'not-found'
            ? RouteErrorType.notFound
            : RouteErrorType.general,
        onRetry:
            failure.code == 'permission-denied' || failure.code == 'not-found'
            ? null
            : () {
                setState(() {
                  _loading = true;
                  _data = null;
                  _error = null;
                });
                _load();
              },
      );
    }
    if (_data == null) {
      return const RouteErrorScreen(type: RouteErrorType.notFound);
    }
    return widget.builder(context, _data as T);
  }
}
