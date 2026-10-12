import 'dart:async';
import 'package:flutter/foundation.dart';
import '../session/session_cubit.dart';
import '../session/session_state.dart';
import 'notification_intent_coordinator.dart';

class RouterRefreshNotifier extends ChangeNotifier {
  final SessionCubit sessionCubit;
  final NotificationIntentCoordinator? coordinator;
  late final StreamSubscription<SessionState> _subscription;
  final VoidCallback? onScopeChange;
  final VoidCallback? onDispose;
  late String _scope;
  bool _disposed = false;

  RouterRefreshNotifier(
    this.sessionCubit, {
    this.coordinator,
    this.onScopeChange,
    this.onDispose,
  }) {
    _scope = sessionCubit.state.scopeKey;
    _subscription = sessionCubit.stream.listen((state) {
      if (state.scopeKey != _scope && onScopeChange != null) {
        _scope = state.scopeKey;
        // Updating RoutingConfig reparses the current URI itself.
        onScopeChange!();
      } else {
        notifyListeners();
      }
    });
    coordinator?.addListener(notifyListeners);
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners) dispose();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _subscription.cancel();
    coordinator?.removeListener(notifyListeners);
    onDispose?.call();
    super.dispose();
  }
}
