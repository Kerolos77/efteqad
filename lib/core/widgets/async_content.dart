import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../errors/app_failure.dart';
import '../models/snapshot_list.dart';
import '../localization/app_localizations.dart';

/// Reusable widget for safe asynchronous state presentation:
/// loading -> error (with retry) -> empty (without false negatives) -> content.
class AsyncContent<T> extends StatelessWidget {
  final bool isLoading;
  final Object? error;
  final T? data;
  final bool Function(T data)? isEmpty;
  final bool isOffline;
  final bool hasPendingWrites;
  final VoidCallback? onRetry;
  final Widget? loadingWidget;
  final Widget? emptyWidget;
  final Widget Function(BuildContext context, AppFailure failure)? errorBuilder;
  final Widget Function(BuildContext context, T data) builder;

  const AsyncContent({
    super.key,
    required this.isLoading,
    this.error,
    this.data,
    this.isEmpty,
    this.isOffline = false,
    this.hasPendingWrites = false,
    this.onRetry,
    this.loadingWidget,
    this.emptyWidget,
    this.errorBuilder,
    required this.builder,
  });

  /// Factory constructor to directly consume an [AsyncSnapshot].
  factory AsyncContent.fromSnapshot({
    Key? key,
    required AsyncSnapshot<T> snapshot,
    bool Function(T data)? isEmpty,
    bool isOffline = false,
    bool hasPendingWrites = false,
    VoidCallback? onRetry,
    Widget? loadingWidget,
    Widget? emptyWidget,
    Widget Function(BuildContext context, AppFailure failure)? errorBuilder,
    required Widget Function(BuildContext context, T data) builder,
  }) {
    return AsyncContent<T>(
      key: key,
      isLoading:
          snapshot.connectionState == ConnectionState.waiting &&
          !snapshot.hasData,
      error: snapshot.hasError ? snapshot.error : null,
      data: snapshot.data,
      isEmpty: isEmpty,
      isOffline: isOffline,
      hasPendingWrites: hasPendingWrites,
      onRetry: onRetry,
      loadingWidget: loadingWidget,
      emptyWidget: emptyWidget,
      errorBuilder: errorBuilder,
      builder: builder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final metadata = data is ReadMetadata ? data as ReadMetadata : null;
    final offline = isOffline || (metadata?.isFromCache ?? false);
    final pending = hasPendingWrites || (metadata?.hasPendingWrites ?? false);

    // 1. Loading State
    if (isLoading && data == null) {
      return loadingWidget ??
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          );
    }

    // 2. Error State (Never mask errors as empty!)
    if (error != null) {
      final failure = error is AppFailure
          ? (error as AppFailure)
          : AppFailure.fromException(error!);

      if (errorBuilder != null) {
        return errorBuilder!(context, failure);
      }

      return _buildDefaultError(context, failure, isDark);
    }

    // 3. Empty State Check
    if (data == null || (isEmpty != null && isEmpty!(data as T))) {
      final empty = emptyWidget ?? _buildDefaultEmpty(context, isDark);
      if (offline || pending) {
        return Column(
          children: [
            _buildStatusBanner(
              context,
              offline: offline,
              cached: !isOffline && (metadata?.isFromCache ?? false),
            ),
            Expanded(child: empty),
          ],
        );
      }
      return empty;
    }

    // 4. Content with Optional Offline/Pending Banner
    final content = builder(context, data as T);

    if (offline || pending) {
      return Column(
        children: [
          _buildStatusBanner(
            context,
            offline: offline,
            cached: !isOffline && (metadata?.isFromCache ?? false),
          ),
          Expanded(child: content),
        ],
      );
    }

    return content;
  }

  Widget _buildDefaultError(
    BuildContext context,
    AppFailure failure,
    bool isDark,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.errorColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppConstants.errorColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              failure.localizedMessage(context.tr),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            if (failure.retryable && onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(context.tr.retryAction),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryLight,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultEmpty(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_rounded,
                size: 40,
                color: isDark ? Colors.white30 : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              context.tr.noEventsMatchingFilter,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppConstants.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(
    BuildContext context, {
    required bool offline,
    bool cached = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      color: offline ? Colors.orange.shade800 : Colors.blue.shade700,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            offline ? Icons.wifi_off_rounded : Icons.sync_rounded,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              cached
                  ? context.tr.cachedDataHint
                  : offline
                  ? context.tr.messageYouAreOffline
                  : context.tr.messageSyncingPendingChanges,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
