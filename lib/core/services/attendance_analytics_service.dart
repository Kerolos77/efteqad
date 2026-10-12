import '../utils/calendar_dates.dart';
import '../models/attendance_session_model.dart';
import '../models/makhdom_model.dart';
import '../models/visit_model.dart';

class AtRiskStudentInfo {
  final MakhdomModel makhdom;
  final int consecutiveAbsences;
  final bool isCritical;
  final List<String> missedDates;
  const AtRiskStudentInfo({
    required this.makhdom,
    required this.consecutiveAbsences,
    required this.isCritical,
    required this.missedDates,
  });
}

class VisitationImpactInfo {
  final double? visitedAttendanceRate,
      unvisitedAttendanceRate,
      impactPercentage;
  final int visitedStudentsCount, unvisitedStudentsCount;
  const VisitationImpactInfo({
    required this.visitedAttendanceRate,
    required this.unvisitedAttendanceRate,
    required this.impactPercentage,
    required this.visitedStudentsCount,
    required this.unvisitedStudentsCount,
  });
  double? get correlationDifference => impactPercentage;
  bool get hasSufficientData => impactPercentage != null;
}

class BehavioralSegmentation {
  final List<MakhdomModel> consistent, irregular, atRisk, insufficient;
  const BehavioralSegmentation({
    required this.consistent,
    required this.irregular,
    required this.atRisk,
    this.insufficient = const [],
  });
}

class WeeklyTrendPoint {
  final String date, type;
  final int attendedCount, totalEligible;
  final double percentage;
  const WeeklyTrendPoint({
    required this.date,
    required this.type,
    required this.attendedCount,
    required this.totalEligible,
    required this.percentage,
  });
}

/// One opportunity per child, local date and type, regardless of root/grade parts.
class AttendanceOpportunity {
  final String date, type;
  final Set<String> eligibleIds, attendedIds;
  const AttendanceOpportunity({
    required this.date,
    required this.type,
    required this.eligibleIds,
    required this.attendedIds,
  });
}

class AttendanceAnalyticsService {
  static DateTime day(DateTime date) => calendarDay(date);
  static String dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  static DateTime? parseSessionDate(String value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return null;
    final date = DateTime.tryParse(value);
    return date != null && dateKey(date) == value ? date : null;
  }

  static List<AttendanceSessionModel> filterValidSessions(
    List<AttendanceSessionModel> sessions, {
    DateTime? asOf,
    DateTime? from,
  }) {
    final end = day(asOf ?? DateTime.now());
    return sessions.where((s) {
      final d = parseSessionDate(s.date);
      return s.isFinalized &&
          (s.isMass || s.isService) &&
          d != null &&
          !d.isAfter(end) &&
          (from == null || !d.isBefore(day(from)));
    }).toList();
  }

  static bool isEligible(MakhdomModel child, AttendanceSessionModel session) {
    final date = parseSessionDate(session.date);
    return child.active &&
        child.hasKnownTrackingOrigin &&
        date != null &&
        (session.grade == 'all' || session.grade == child.grade) &&
        !date.isBefore(day(child.effectiveTrackingStartDate));
  }

  static List<AttendanceOpportunity> opportunities({
    required List<MakhdomModel> makhdomeen,
    required List<AttendanceSessionModel> sessions,
    DateTime? asOf,
    DateTime? from,
    String? type,
  }) {
    final eligible = <String, Set<String>>{},
        attended = <String, Set<String>>{};
    for (final s in filterValidSessions(sessions, asOf: asOf, from: from)) {
      if (type != null && s.type != type) continue;
      final key = '${s.date}/${s.type}';
      for (final m in makhdomeen.where((m) => isEligible(m, s))) {
        eligible.putIfAbsent(key, () => {}).add(m.id);
        if (s.isAttended(m.id)) attended.putIfAbsent(key, () => {}).add(m.id);
      }
    }
    final keys = eligible.keys.toList()..sort();
    return keys
        .map(
          (key) => AttendanceOpportunity(
            date: key.split('/')[0],
            type: key.split('/')[1],
            eligibleIds: eligible[key]!,
            attendedIds: attended[key] ?? {},
          ),
        )
        .toList();
  }

  static List<AtRiskStudentInfo> getAtRiskStudents({
    required List<MakhdomModel> makhdomeen,
    required List<AttendanceSessionModel> sessions,
    int minConsecutiveAbsences = 2,
    DateTime? asOf,
    DateTime? from,
  }) {
    final service = opportunities(
      makhdomeen: makhdomeen,
      sessions: sessions,
      type: 'khedma',
      asOf: asOf,
      from: from,
    ).reversed;
    final results = <AtRiskStudentInfo>[];
    for (final m in makhdomeen) {
      final missed = <String>[];
      for (final o in service.where((o) => o.eligibleIds.contains(m.id))) {
        if (o.attendedIds.contains(m.id)) break;
        missed.add(o.date);
      }
      if (missed.length >= minConsecutiveAbsences) {
        results.add(
          AtRiskStudentInfo(
            makhdom: m,
            consecutiveAbsences: missed.length,
            isCritical: missed.length >= 3,
            missedDates: missed,
          ),
        );
      }
    }
    results.sort((a, b) {
      final n = b.consecutiveAbsences.compareTo(a.consecutiveAbsences);
      return n != 0 ? n : a.makhdom.fullName.compareTo(b.makhdom.fullName);
    });
    return results;
  }

  static double? calculateOverallAttendanceRate({
    required List<MakhdomModel> makhdomeen,
    required List<AttendanceSessionModel> sessions,
    DateTime? asOf,
    DateTime? from,
    String type = 'khedma',
  }) {
    final ops = opportunities(
      makhdomeen: makhdomeen,
      sessions: sessions,
      asOf: asOf,
      from: from,
      type: type,
    );
    final total = ops.fold<int>(0, (n, o) => n + o.eligibleIds.length);
    return total == 0
        ? null
        : ops.fold<int>(0, (n, o) => n + o.attendedIds.length) * 100 / total;
  }

  static VisitationImpactInfo calculateVisitationImpact({
    required List<MakhdomModel> makhdomeen,
    required List<AttendanceSessionModel> sessions,
    List<VisitModel> visits = const [],
    DateTime? asOf,
    DateTime? from,
  }) {
    final end = calendarDay(asOf ?? DateTime.now(), 1);
    final visitedIds = visits
        .where(
          (v) =>
              v.visitDate.isBefore(end) &&
              (from == null || !v.visitDate.isBefore(day(from))),
        )
        .map((v) => v.makhdomId)
        .toSet();
    final population = makhdomeen.where((m) => m.active).toList();
    final visited = population.where((m) => visitedIds.contains(m.id)).toList();
    final unvisited = population
        .where((m) => !visitedIds.contains(m.id))
        .toList();
    final a = calculateOverallAttendanceRate(
      makhdomeen: visited,
      sessions: sessions,
      asOf: asOf,
      from: from,
    );
    final b = calculateOverallAttendanceRate(
      makhdomeen: unvisited,
      sessions: sessions,
      asOf: asOf,
      from: from,
    );
    return VisitationImpactInfo(
      visitedAttendanceRate: a,
      unvisitedAttendanceRate: b,
      impactPercentage: a != null && b != null ? a - b : null,
      visitedStudentsCount: visited.length,
      unvisitedStudentsCount: unvisited.length,
    );
  }

  static BehavioralSegmentation segmentStudents({
    required List<MakhdomModel> makhdomeen,
    required List<AttendanceSessionModel> sessions,
    DateTime? asOf,
    DateTime? from,
  }) {
    final consistent = <MakhdomModel>[],
        irregular = <MakhdomModel>[],
        atRisk = <MakhdomModel>[],
        insufficient = <MakhdomModel>[];
    final risk = getAtRiskStudents(
      makhdomeen: makhdomeen,
      sessions: sessions,
      asOf: asOf,
      from: from,
    ).map((i) => i.makhdom.id).toSet();
    for (final m in makhdomeen.where((m) => m.active)) {
      final rate = calculateOverallAttendanceRate(
        makhdomeen: [m],
        sessions: sessions,
        asOf: asOf,
        from: from,
      );
      if (rate == null) {
        insufficient.add(m);
      } else if (risk.contains(m.id) || rate < 40) {
        atRisk.add(m);
      } else if (rate >= 75) {
        consistent.add(m);
      } else {
        irregular.add(m);
      }
    }
    return BehavioralSegmentation(
      consistent: consistent,
      irregular: irregular,
      atRisk: atRisk,
      insufficient: insufficient,
    );
  }

  static List<WeeklyTrendPoint> getWeeklyTrend({
    required List<MakhdomModel> makhdomeen,
    required List<AttendanceSessionModel> sessions,
    int maxWeeks = 8,
    DateTime? asOf,
    DateTime? from,
  }) {
    if (maxWeeks <= 0) return [];
    final ops = opportunities(
      makhdomeen: makhdomeen,
      sessions: sessions,
      type: 'khedma',
      asOf: asOf,
      from: from,
    );
    return ops
        .skip(ops.length > maxWeeks ? ops.length - maxWeeks : 0)
        .map(
          (o) => WeeklyTrendPoint(
            date: o.date,
            type: o.type,
            attendedCount: o.attendedIds.length,
            totalEligible: o.eligibleIds.length,
            percentage: o.attendedIds.length * 100 / o.eligibleIds.length,
          ),
        )
        .toList();
  }
}
