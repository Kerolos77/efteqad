import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'app_localizations.dart';

class AppFormatters {
  final Locale locale;
  const AppFormatters(this.locale);
  String get localeName => locale.languageCode == 'ar' ? 'ar' : 'en';
  String formatDate(DateTime? date, {String format = 'yyyy-MM-dd'}) =>
      date == null ? '' : DateFormat(format, localeName).format(date);
  String formatDayAndDate(DateTime? date) =>
      formatDate(date, format: 'EEEE yyyy-MM-dd');
  String ltr(String value) => '\u2066$value\u2069';
  String formatWeekday(DateTime date) =>
      DateFormat.EEEE(localeName).format(date);
  String formatNumber(num value, {int decimalDigits = 0}) =>
      NumberFormat.decimalPatternDigits(
        locale: localeName,
        decimalDigits: decimalDigits,
      ).format(value);
  String formatPercentage(double value) =>
      '${formatNumber(value, decimalDigits: 1)}%';
  String pluralizeVisits(int count) =>
      lookupGeneratedAppLocalizations(locale).visitsCount(count);
  String pluralizeStudents(int count) =>
      lookupGeneratedAppLocalizations(locale).studentsCount(count);
  String pluralizeServants(int count) =>
      lookupGeneratedAppLocalizations(locale).servantsCount(count);
}
