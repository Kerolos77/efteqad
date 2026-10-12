import 'package:cloud_functions/cloud_functions.dart';

class PrivilegedOperationsService {
  final FirebaseFunctions? _providedFunctions;
  FirebaseFunctions get _functions =>
      _providedFunctions ?? FirebaseFunctions.instance;

  PrivilegedOperationsService({FirebaseFunctions? functions})
    : _providedFunctions = functions;

  /// تسكين خادم في سنة دراسية معينة (بواسطة أمين المرحلة)
  Future<void> setKhademGrade({
    required String khademId,
    required String grade,
  }) async {
    final callable = _functions.httpsCallable('setKhademGrade');
    await callable.call<Map<String, dynamic>>({
      'khademId': khademId,
      'grade': grade,
    });
  }

  /// تعيين خادم كأمين لسنة دراسية معينة (بواسطة أمين المرحلة)
  Future<void> setGradeAdmin({
    required String khademId,
    required String grade,
  }) async {
    final callable = _functions.httpsCallable('setGradeAdmin');
    await callable.call<Map<String, dynamic>>({
      'khademId': khademId,
      'grade': grade,
    });
  }
}
