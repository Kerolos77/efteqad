import '../../../../core/utils/calendar_dates.dart';
import '../../../../core/models/attendance_session_model.dart';
import '../../../../core/models/makhdom_model.dart';
import '../../../../core/models/visit_model.dart';
import '../../../../core/services/attendance_analytics_service.dart';
import '../models/history_analysis.dart';

class MakhdomHistoryService {
  const MakhdomHistoryService();
  HistoryAnalysis analyzeHistory({
    required MakhdomModel makhdom,
    required List<VisitModel> visits,
    required List<AttendanceSessionModel> sessions,
    required DateTime asOf,
    DateTime? from,
  }) {
    final start = from == null ? null : AttendanceAnalyticsService.day(from);
    final end = calendarDay(asOf, 1);
    final ops = AttendanceAnalyticsService.opportunities(
      makhdomeen: [makhdom],
      sessions: sessions,
      asOf: asOf,
      from: from,
    );
    final validVisits =
        visits
            .where(
              (v) =>
                  v.makhdomId == makhdom.id &&
                  v.visitDate.isBefore(end) &&
                  (start == null || !v.visitDate.isBefore(start)),
            )
            .toList()
          ..sort((a, b) {
            final d = b.visitDate.compareTo(a.visitDate);
            if (d != 0) return d;
            final c = b.createdAt.compareTo(a.createdAt);
            return c != 0 ? c : b.id.compareTo(a.id);
          });
    final dates = ops.map((o) => o.date).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    final records = <FridayAttendanceRecord>[];
    var streak = 0;
    var broken = false;
    DateTime? lastAttendance;
    for (final date in dates) {
      final day = AttendanceAnalyticsService.parseSessionDate(date)!;
      final daily = ops.where((o) => o.date == date);
      final mass = daily.where((o) => o.type == 'qoddas').firstOrNull;
      final service = daily.where((o) => o.type == 'khedma').firstOrNull;
      final attendedMass = mass?.attendedIds.contains(makhdom.id) ?? false;
      final attendedService =
          service?.attendedIds.contains(makhdom.id) ?? false;
      if (attendedService && lastAttendance == null) lastAttendance = day;
      if (!broken && service != null) {
        if (attendedService) {
          broken = true;
        } else {
          streak++;
        }
      }
      records.add(
        FridayAttendanceRecord(
          dateString: date,
          date: day,
          attendedMass: attendedMass,
          attendedService: attendedService,
          hasMassSession: mass != null,
          hasServiceSession: service != null,
          precedingVisit: validVisits
              .where(
                (v) =>
                    !v.visitDate.isAfter(day) &&
                    day.difference(v.visitDate).inDays <= 7,
              )
              .firstOrNull,
        ),
      );
    }
    final relations = <VisitWithImpact>[];
    final postDates = <String>{};
    for (final visit in validVisits) {
      final day = AttendanceAnalyticsService.day(visit.visitDate);
      var days = (DateTime.friday - day.weekday) % 7;
      if (days == 0) days = 7;
      final friday = calendarDay(day, days);
      final key = AttendanceAnalyticsService.dateKey(friday);
      final record = records.where((r) => r.dateString == key).firstOrNull;
      VisitFridayOutcome outcome;
      bool? mass, service;
      if (!friday.isBefore(end)) {
        outcome = VisitFridayOutcome.pending;
      } else if (record == null || !record.hasServiceSession) {
        outcome = VisitFridayOutcome.noData;
        mass = record?.hasMassSession == true ? record!.attendedMass : null;
      } else {
        service = record.attendedService;
        mass = record.hasMassSession ? record.attendedMass : null;
        postDates.add(key);
        outcome = service
            ? (mass == true
                  ? VisitFridayOutcome.both
                  : VisitFridayOutcome.serviceOnly)
            : (mass == true
                  ? VisitFridayOutcome.massOnly
                  : VisitFridayOutcome.missed);
      }
      relations.add(
        VisitWithImpact(
          visit: visit,
          nextFriday: friday,
          nextFridayFormatted: key,
          outcome: outcome,
          attendedMass: mass,
          attendedService: service,
        ),
      );
    }
    final serviceOps = ops.where((o) => o.type == 'khedma').toList();
    double? rate(Iterable<AttendanceOpportunity> list) {
      final items = list.toList();
      return items.isEmpty
          ? null
          : items.where((o) => o.attendedIds.contains(makhdom.id)).length *
                100 /
                items.length;
    }

    final serviceRate = rate(serviceOps),
        massRate = rate(ops.where((o) => o.type == 'qoddas'));
    final post = rate(serviceOps.where((o) => postDates.contains(o.date))),
        nonPost = rate(serviceOps.where((o) => !postDates.contains(o.date)));
    final lastVisit = validVisits.firstOrNull;
    return HistoryAnalysis(
      makhdom: makhdom,
      asOf: asOf,
      hasSufficientData: serviceOps.isNotEmpty,
      totalEligibleSessions: serviceOps.length,
      totalAttendedSessions: serviceOps
          .where((o) => o.attendedIds.contains(makhdom.id))
          .length,
      overallAttendanceRate: serviceRate,
      massAttendanceRate: massRate,
      serviceAttendanceRate: serviceRate,
      consecutiveAbsences: streak,
      isAtRisk: streak >= 2,
      isCriticalRisk: streak >= 3,
      lastVisit: lastVisit,
      totalVisitsCount: validVisits.length,
      daysSinceLastVisit: lastVisit == null
          ? null
          : AttendanceAnalyticsService.day(asOf)
                .difference(AttendanceAnalyticsService.day(lastVisit.visitDate))
                .inDays,
      daysSinceLastAttendance: lastAttendance == null
          ? null
          : AttendanceAnalyticsService.day(
              asOf,
            ).difference(lastAttendance).inDays,
      fridayRecords: records,
      visitsWithImpact: relations,
      postVisitAttendanceRate: post,
      nonPostVisitAttendanceRate: nonPost,
      correlationDifference: post != null && nonPost != null
          ? post - nonPost
          : null,
    );
  }
}
