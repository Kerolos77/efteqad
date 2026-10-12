import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'core/constants/constants.dart';
import 'core/localization/app_localizations.dart';
import 'core/repositories/auth_repository.dart';
import 'core/repositories/profile_repository.dart';
import 'core/router/app_router.dart';
import 'core/session/session_cubit.dart';
import 'core/session/session_state.dart';
import 'core/settings/settings_cubit.dart';
import 'core/settings/settings_repository.dart';
import 'core/theme/app_theme.dart';
import 'core/router/notification_intent_coordinator.dart';
import 'core/services/notification_service.dart';
import 'core/services/device_registration_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة فايربيس
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // تفعيل التخزين المؤقت في وضع عدم الاتصال (Offline Persistence) بحجم محدد ومضبوط (100 MB)
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: 104857600, // 100 MB bounded cache
  );

  final authRepository = FirebaseAuthRepository();
  final profileRepository = FirestoreProfileRepository();
  final sessionCubit = SessionCubit(
    authRepository: authRepository,
    profileRepository: profileRepository,
  );
  final settingsRepository = SharedPrefsSettingsRepository();
  final accountLocales = AccountLocaleRepository();
  final settingsCubit = SettingsCubit(
    repository: settingsRepository,
    saveAccountLocale: accountLocales.saveLocale,
    syncDeviceLocale: (uid, locale) async {
      final session = sessionCubit.state;
      if (session.userId != uid ||
          session.profile == null ||
          !(session.isActive || session.isPending) ||
          session.isDeleting) {
        return;
      }
      await NotificationService().syncUserToken(uid, locale: locale);
    },
    updateNotificationLocale: NotificationService().updateLocale,
  );
  await settingsCubit.ready;

  // تهيئة الإشعارات و FCM مع منسق نوايا الإشعارات
  final coordinator = NotificationIntentCoordinator();
  await NotificationService().initialize(
    intentCoordinator: coordinator,
    locale: settingsCubit.state.locale,
  );

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<SettingsCubit>(create: (_) => settingsCubit),
        BlocProvider<SessionCubit>(create: (_) => sessionCubit),
      ],
      child: const EfteqadApp(),
    ),
  );
}

final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(
  ThemeMode.light,
);
final ValueNotifier<Locale> localeNotifier = ValueNotifier<Locale>(
  const Locale('ar', 'EG'),
);

class EfteqadApp extends StatefulWidget {
  final GoRouter? router;
  final DeviceRegistrationService? devices;
  final Future<void> Function(Locale)? updateNotificationLocale;
  const EfteqadApp({
    super.key,
    this.router,
    this.devices,
    this.updateNotificationLocale,
  });

  @override
  State<EfteqadApp> createState() => _EfteqadAppState();
}

class _EfteqadAppState extends State<EfteqadApp> {
  late GoRouter _router;
  int _sessionGeneration = 0;
  DeviceRegistrationService get _devices =>
      widget.devices ?? DeviceRegistrationService.shared;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsCubit>().state;
    themeModeNotifier.value = settings.themeMode;
    localeNotifier.value = settings.locale;
    _router =
        widget.router ??
        createAppRouter(
          sessionCubit: context.read<SessionCubit>(),
          notificationIntentCoordinator:
              NotificationService().intentCoordinator,
        );
    unawaited(_syncSessionPreferences(context.read<SessionCubit>().state));
  }

  Future<void> _syncSessionPreferences(SessionState session) async {
    final generation = ++_sessionGeneration;
    _devices.invalidatePendingOperations();
    final settings = context.read<SettingsCubit>();
    final eligible =
        session.profile != null &&
        (session.isActive || session.isPending) &&
        !session.isDeleting;
    try {
      if (!eligible) await _devices.unbindUser();
      if (!mounted || generation != _sessionGeneration) return;
      await settings.reconcileAccount(
        uid: session.userId,
        locale: session.profile?.locale,
        canAttach: eligible,
      );
      if (!mounted ||
          generation != _sessionGeneration ||
          !eligible ||
          context.read<SessionCubit>().state.scopeKey != session.scopeKey) {
        return;
      }
      await (widget.updateNotificationLocale ??
          NotificationService().updateLocale)(settings.state.locale);
      if (!mounted ||
          generation != _sessionGeneration ||
          context.read<SessionCubit>().state.scopeKey != session.scopeKey) {
        return;
      }
      await _devices.bindUser(
        session.userId!,
        locale: settings.state.locale.languageCode,
      );
    } catch (error, stack) {
      debugPrint('Preference/device synchronization failed: $error\n$stack');
    }
  }

  @override
  void dispose() {
    _sessionGeneration++;
    _devices.invalidatePendingOperations();
    if (widget.router == null) _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SessionCubit, SessionState>(
          listenWhen: (prev, current) =>
              prev.scopeKey != current.scopeKey ||
              prev.profile?.locale != current.profile?.locale ||
              (context.read<SettingsCubit>().hasPendingAccountLocale &&
                  prev.profile != current.profile),
          listener: (context, state) async {
            await _syncSessionPreferences(state);
          },
        ),
        BlocListener<SettingsCubit, SettingsState>(
          listener: (context, settingsState) {
            themeModeNotifier.value = settingsState.themeMode;
            localeNotifier.value = settingsState.locale;
          },
        ),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          if (!settingsState.isLoaded) return const SizedBox.shrink();
          return MaterialApp.router(
            title: AppConstants.appName,
            onGenerateTitle: (ctx) => ctx.tr.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settingsState.themeMode,
            themeAnimationDuration: Duration.zero,
            locale: settingsState.locale,
            supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
            localizationsDelegates: const [
              GeneratedAppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
