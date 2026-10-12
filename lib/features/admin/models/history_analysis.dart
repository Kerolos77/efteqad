import '../../../../core/models/makhdom_model.dart';
import '../../../../core/models/visit_model.dart';

enum VisitFridayOutcome {
  both, // حضر القداس والخدمة
  serviceOnly, // حضر الخدمة فقط
  massOnly, // حضر القداس فقط
  missed, // غائب
  pending, // الجمعة القادمة لم تأتِ بعد
  noData, // لم يتم تسجيل جلسات في هذه الجمعة
}

class VisitWithImpact {
  final VisitModel visit;
  final DateTime nextFriday;
  final String nextFridayFormatted;
  final VisitFridayOutcome outcome;
  final bool? attendedMass;
  final bool? attendedService;

  const VisitWithImpact({
    required this.visit,
    required this.nextFriday,
    required this.nextFridayFormatted,
    required this.outcome,
    this.attendedMass,
    this.attendedService,
  });
}

class FridayAttendanceRecord {
  final String dateString;
  final DateTime date;
  final bool attendedMass;
  final bool attendedService;
  final bool hasMassSession;
  final bool hasServiceSession;
  final VisitModel? precedingVisit;

  const FridayAttendanceRecord({
    required this.dateString,
    required this.date,
    required this.attendedMass,
    required this.attendedService,
    required this.hasMassSession,
    required this.hasServiceSession,
    this.precedingVisit,
  });

  bool get isAbsent => hasServiceSession && !attendedService;
  bool get isAttendedAny => (attendedMass || attendedService);
  bool get isAttendedBoth => (attendedMass && attendedService);
}

class HistoryAnalysis {
  final MakhdomModel makhdom;
  final DateTime asOf;
  final bool hasSufficientData;
  final int totalEligibleSessions;
  final int totalAttendedSessions;
  final double? overallAttendanceRate;
  final double? massAttendanceRate;
  final double? serviceAttendanceRate;
  final int consecutiveAbsences;
  final bool isAtRisk;
  final bool isCriticalRisk;
  final VisitModel? lastVisit;
  final int totalVisitsCount;
  final int? daysSinceLastVisit;
  final int? daysSinceLastAttendance;
  final List<FridayAttendanceRecord> fridayRecords;
  final List<VisitWithImpact> visitsWithImpact;
  final double? postVisitAttendanceRate;
  final double? nonPostVisitAttendanceRate;
  final double? correlationDifference;

  const HistoryAnalysis({
    required this.makhdom,
    required this.asOf,
    required this.hasSufficientData,
    required this.totalEligibleSessions,
    required this.totalAttendedSessions,
    required this.overallAttendanceRate,
    required this.massAttendanceRate,
    required this.serviceAttendanceRate,
    required this.consecutiveAbsences,
    required this.isAtRisk,
    required this.isCriticalRisk,
    this.lastVisit,
    required this.totalVisitsCount,
    this.daysSinceLastVisit,
    this.daysSinceLastAttendance,
    required this.fridayRecords,
    required this.visitsWithImpact,
    this.postVisitAttendanceRate,
    this.nonPostVisitAttendanceRate,
    this.correlationDifference,
  });

  static final HistoryAnalysis empty = HistoryAnalysis(
    makhdom: MakhdomModel(
      id: '',
      fullName: '',
      phone: '',
      grade: '',
      createdAt: DateTime(2026, 1, 1),
    ),
    asOf: DateTime(2026, 1, 1),
    hasSufficientData: false,
    totalEligibleSessions: 0,
    totalAttendedSessions: 0,
    overallAttendanceRate: null,
    massAttendanceRate: null,
    serviceAttendanceRate: null,
    consecutiveAbsences: 0,
    isAtRisk: false,
    isCriticalRisk: false,
    totalVisitsCount: 0,
    fridayRecords: const [],
    visitsWithImpact: const [],
  );
}
