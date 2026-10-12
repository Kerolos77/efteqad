import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/app_routes.dart';

enum RouteErrorType { forbidden, notFound, general }

class RouteErrorScreen extends StatelessWidget {
  final RouteErrorType type;
  final String? message;
  final VoidCallback? onRetry;

  const RouteErrorScreen({
    super.key,
    this.type = RouteErrorType.notFound,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;

    final String title;
    final String description;
    final IconData icon;

    switch (type) {
      case RouteErrorType.forbidden:
        title = context.tr.messageAccessDenied;
        description =
            message ?? (context.tr.messageYouDoNotHavePermissionToAccess);
        icon = Icons.lock_outline_rounded;
        break;
      case RouteErrorType.notFound:
        title = context.tr.messagePageNotFound;
        description =
            message ?? (context.tr.messageThePageYouAreLookingForDoes);
        icon = Icons.search_off_rounded;
        break;
      case RouteErrorType.general:
        title = context.tr.messageAnErrorOccurred;
        description = message ?? (tr.dataUnavailable);
        icon = Icons.error_outline_rounded;
        break;
    }

    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppConstants.sacredGold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: AppConstants.sacredGold),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: const TextStyle(fontSize: 15, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (onRetry != null) ...[
                    OutlinedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(context.tr.messageRetry),
                    ),
                    const SizedBox(width: 16),
                  ],
                  FilledButton.icon(
                    onPressed: () {
                      context.go(AppRoutes.bootstrapPath);
                    },
                    icon: const Icon(Icons.home_rounded),
                    label: Text(context.tr.messageGoHome),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
