import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../session/session_cubit.dart';

class RouterServices extends InheritedWidget {
  final FirestoreService firestore;
  final SessionCubit session;
  const RouterServices({
    super.key,
    required this.firestore,
    required this.session,
    required super.child,
  });
  static RouterServices? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RouterServices>();
  static RouterServices of(BuildContext context) => maybeOf(context)!;
  @override
  bool updateShouldNotify(RouterServices oldWidget) =>
      firestore != oldWidget.firestore ||
      session.state.scopeKey != oldWidget.session.state.scopeKey;
}
