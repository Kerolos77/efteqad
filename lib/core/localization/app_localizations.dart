import 'package:flutter/widgets.dart';
import '../../l10n/generated/app_localizations.dart';
export '../../l10n/generated/app_localizations.dart';

/// Compatibility type; all messages and the runtime delegate are generated.
typedef AppLocalizations = GeneratedAppLocalizations;

extension GeneratedLocale on GeneratedAppLocalizations {
  bool get isArabic => localeName.startsWith('ar');
}

extension LocalizationExtension on BuildContext {
  GeneratedAppLocalizations get tr => GeneratedAppLocalizations.of(this)!;
  bool get isArabic => Localizations.localeOf(this).languageCode == 'ar';
}
