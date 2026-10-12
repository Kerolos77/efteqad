import 'package:flutter/material.dart';

class AppConstants {
  // اسم التطبيق
  static const String appName = 'الراعي';
  static const String appTagline = '«أَنَا هُوَ الرَّاعِي الصَّالِحُ»';
  static const String appVersion = '1.0.0';

  // مسار شعار التطبيق وخلفية الاسبلاش
  static const String appLogoPath = 'assets/images/logo.png';
  static const String splashScreenBgPath = 'assets/images/splash_screen_bg.png';
  static const Color splashBgColor = Color(0xFF071931);

  // إيميل الأدمن المعتمد (يمكن تغييره من هنا في أي وقت)
  static const String constAdminEmail = 'admin@efteqad.com';

  // مجموعات فايرستور (Firestore Collections)
  static const String colMakhdomeen = 'makhdomeen';
  static const String colKhodam = 'khodam';
  static const String colVisits = 'visits';
  static const String colSettings = 'settings';
  static const String colTasks = 'tasks';
  static const String colAttendance = 'attendance';
  static const String colNotifications = 'notifications';

  // المراحل الدراسية (Grades)
  static const String grade1st = '1st'; // أولى ثانوي
  static const String grade2nd = '2nd'; // ثانية ثانوي
  static const String grade3rd = '3rd'; // ثالثة ثانوي
  static const String gradeAll = 'all'; // مرحلة ثانوي كاملة

  // أنواع المهام (Task Types)
  static const String taskTypeGeneral = 'general';
  static const String taskTypeVisitation = 'visitation';
  static const String taskTypeAttendanceKhedma = 'attendance_khedma'; // حضور الخدمة
  static const String taskTypeAttendanceQoddas = 'attendance_qoddas'; // حضور القداس

  // الأدوار (Roles)
  static const String roleStageAdmin = 'stageAdmin'; // أمين مرحلة ثانوي
  static const String roleGradeAdmin = 'gradeAdmin'; // أمين سنة (1 أو 2 أو 3 ثانوي)
  static const String roleServant = 'servant';       // خادم مسكن في سنة
  static const String rolePending = 'pending';       // خادم جديد في الانتظار

  // ألوان هوية «الراعي» - الكحلي الملكي العميق والذهبي النوراني المقدس
  static const Color sacredGold = Color(0xFFE2B542);       // الذهبي النوراني المقدس
  static const Color royalGold = Color(0xFFC9A84C);        // الذهبي الملكي الدافئ
  static const Color accentGold = Color(0xFFE2B542);       // الذهبي الرئيسي لعناصر التمييز
  static const Color primaryColor = Color(0xFF0D1B2A);     // الكحلي الملكي العميق (Midnight Royal Navy)
  static const Color primaryNavy = Color(0xFF132238);      // كحلي أغمق للأسطح والبطاقات
  static const Color primaryLight = Color(0xFF1E3A8A);     // أزرق ملكي كنسي متناسق
  static const Color accentIndigo = Color(0xFF4F46E5);     // بنفسجي كنسي رقيق

  // ألوان الخلفيات والأسطح
  static const Color backgroundLight = Color(0xFFF8FAFC);  // عاجي ناعم جداً
  static const Color surfaceLight = Colors.white;
  static const Color cardBorderLight = Color(0xFFE2E8F0);
  static const Color textDark = Color(0xFF0D1B2A);
  static const Color textMuted = Color(0xFF64748B);

  // ألوان Dark Mode (الهوية الليلية الملكية)
  static const Color backgroundDark = Color(0xFF070E17);   // سواد كحلي فاخر
  static const Color surfaceDark = Color(0xFF0D1B2A);      // كحلي ملكي عميق
  static const Color cardBorderDark = Color(0xFF1E334D);   // حدود كحلية مائلة للذهبي الخفيف
  static const Color textLight = Color(0xFFF8FAFC);
  static const Color textMutedDark = Color(0xFF94A3B8);

  // ألوان الحالات والافتفاد
  static const Color successColor = Color(0xFF10B981);     // Emerald للزيارات المكتملة
  static const Color warningColor = Color(0xFFF59E0B);     // Amber للاهتمام
  static const Color errorColor = Color(0xFFEF4444);       // Rose للمتأخرين
  static const Color infoColor = Color(0xFF0284C7);        // Sky blue للاتصالات

  // Aliases for modern layout components
  static const Color cardLight = surfaceLight;
  static const Color cardDark = surfaceDark;
  static const Color borderLight = cardBorderLight;
  static const Color borderDark = cardBorderDark;
  static const Color textPrimary = textDark;
  static const Color textSecondary = textMuted;
  static const Color textSecondaryDark = textMutedDark;
  static const Color accentBlue = primaryLight;
}
