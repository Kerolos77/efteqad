import 'package:flutter/widgets.dart';
import '../localization/app_localizations.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../router/notification_intent_coordinator.dart';
import 'device_registration_service.dart';
import 'trusted_mutations.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // يمكن معالجة الرسائل الخلفية هنا عند الحاجة
  if (kDebugMode) {
    print('FCM background message: ${message.messageId}');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService({
    TrustedMutations? mutations,
    DeviceRegistrationService? devices,
  }) => mutations == null && devices == null
      ? _instance
      : NotificationService._internal(mutations: mutations, devices: devices);
  NotificationService._internal({
    TrustedMutations? mutations,
    DeviceRegistrationService? devices,
  }) : _mutations = mutations ?? TrustedMutations(),
       _providedDevices = devices;
  final TrustedMutations _mutations;
  final DeviceRegistrationService? _providedDevices;
  final Map<String, String> _alertOperations = {};

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  DeviceRegistrationService get _devices =>
      _providedDevices ?? DeviceRegistrationService.shared;

  static const channelId = 'efteqad_high_importance_channel';
  Locale _locale = const Locale('ar');
  GeneratedAppLocalizations get _tr => lookupGeneratedAppLocalizations(_locale);
  AndroidNotificationChannel get _channel => channelForLocale(_locale);
  static AndroidNotificationChannel channelForLocale(Locale locale) {
    final tr = lookupGeneratedAppLocalizations(locale);
    return AndroidNotificationChannel(
      channelId,
      tr.channelName,
      description: tr.channelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
  }

  bool _isInitialized = false;
  NotificationIntentCoordinator? _intentCoordinator;

  NotificationIntentCoordinator? get intentCoordinator => _intentCoordinator;

  void setIntentCoordinator(NotificationIntentCoordinator coordinator) {
    _intentCoordinator = coordinator;
  }

  void _handlePayloadString(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        final intent = NotificationIntent.fromPayload(decoded);
        _intentCoordinator?.enqueue(intent);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  /// تهيئة خدمات الإشعارات (FCM والإشعارات المحلية)
  Future<void> initialize({
    NotificationIntentCoordinator? intentCoordinator,
    Locale locale = const Locale('ar'),
  }) async {
    _locale = locale;
    if (intentCoordinator != null) {
      _intentCoordinator = intentCoordinator;
    }

    if (_isInitialized) return;

    try {
      // 1. طلب الصلاحيات من المستخدم
      await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // 2. إعداد الإشعارات المحلية
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings darwinSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (kDebugMode) {
            print('Notification tapped: ${response.payload}');
          }
          _handlePayloadString(response.payload);
        },
      );

      // Check cold launch via local notification
      final launchDetails = await _localNotifications
          .getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true &&
          launchDetails?.notificationResponse?.payload != null) {
        _handlePayloadString(launchDetails!.notificationResponse!.payload);
      }

      // إنشاء القناة في نظام أندرويد
      final androidPlatform = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlatform != null) {
        await androidPlatform.createNotificationChannel(_channel);
      }

      // 3. ضبط سلوك الإشعارات في المقدمة (Foreground)
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 4. تسجيل معالج الخلفية
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 5. الاستماع لرسائل المقدمة
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final title =
            message.notification?.title ??
            message.data['title'] ??
            _tr.newNotification;
        final body = message.notification?.body ?? message.data['body'] ?? '';

        showLocalNotification(
          id: message.hashCode,
          title: title,
          body: body,
          payload: jsonEncode(message.data),
        );
      });

      // 6. الاستماع لنقر الإشعارات عند فتح التطبيق من الخلفية (Background)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (message.data.isNotEmpty) {
          final intent = NotificationIntent.fromPayload(message.data);
          _intentCoordinator?.enqueue(intent);
        }
      });

      // 7. التحقق من الرسالة التي فتحت التطبيق من حالة الإغلاق التام (Terminated)
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null && initialMessage.data.isNotEmpty) {
        final intent = NotificationIntent.fromPayload(initialMessage.data);
        _intentCoordinator?.enqueue(intent);
      }

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing NotificationService: $e');
      }
    }
  }

  Future<void> updateLocale(Locale locale) async {
    _locale = locale;
    if (!_isInitialized) return;
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }

  /// مزامنة وحفظ توكن FCM الخاص بالمستخدم في قاعدة البيانات تحت أجهزته المسجلة
  Future<void> syncUserToken(String userId, {String? locale}) async {
    if (userId.isEmpty) return;
    await _devices.bindUser(userId, locale: locale);
  }

  /// إظهار إشعار محلي فوري (Heads-up Notification)
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  /// إرسال إشعار لخادم معين (تسجيله في فايرستور + تشغيل الإشعار)
  Future<Map<String, dynamic>> notifyKhadem({
    required String recipientId,
    required String recipientName,
    required String title,
    required String body,
    required String type, // 'task', 'absence_alert', 'general'
    Map<String, dynamic> data = const {},
    String? operationId,
  }) async {
    final childId = data['makhdomId'];
    if (type != 'absence_alert' || childId is! String || childId.isEmpty) {
      throw ArgumentError('An absence alert requires makhdomId.');
    }
    final op =
        operationId ??
        _alertOperations.putIfAbsent(
          childId,
          () => newOperationId('child_alert'),
        );
    final result = await _mutations.call('sendChildAlert', {
      'makhdomId': childId,
      'kind': 'absence',
      'operationId': op,
    });
    _alertOperations.remove(childId);
    return result;
  }
}
