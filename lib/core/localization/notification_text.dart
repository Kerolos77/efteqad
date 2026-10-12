import '../models/notification_model.dart';
import 'app_localizations.dart';

extension NotificationText on NotificationModel {
  bool get _knownTask =>
      const [
        'task_assigned',
        'attendance_khedma',
        'attendance_qoddas',
      ].contains(templateKey) &&
      templateArgs['title'] is String;
  String readerTitle(AppLocalizations tr) {
    if (_knownTask) {
      return tr.messageNewTask(templateArgs['title']?.toString() ?? title);
    }
    if (templateKey == 'child_absence_alert') {
      return tr.followupNotificationTitle;
    }
    return title;
  }

  String readerBody(AppLocalizations tr) {
    if (templateKey == 'child_absence_alert') {
      return tr.followupNotificationBody;
    }
    if (!_knownTask) return body;
    final author = templateArgs['createdByName']?.toString() ?? '';
    // Before description metadata was introduced, the producer stored either
    // the user's description or this exact system sentence.
    final description = templateArgs.containsKey('description')
        ? templateArgs['description']?.toString() ?? ''
        : (body == 'قام $author بتكليفك بمهمة جديدة' ? '' : body);
    if (description.isNotEmpty) return description;
    if (templateKey == 'attendance_khedma') {
      return tr.messageYouAreAssignedToTakeServiceAttendance;
    }
    if (templateKey == 'attendance_qoddas') {
      return tr.messageYouAreAssignedToTakeMassAttendance;
    }
    return tr.messageAssignedYouANewTask(
      author.isEmpty ? tr.messageAdmin : author,
    );
  }
}
