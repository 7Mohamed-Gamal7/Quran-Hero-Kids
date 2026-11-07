enum ApiFailureType { configuration, authentication, http, network, decoding }

class ApiException implements Exception {
  const ApiException({
    required this.type,
    required this.message,
    this.statusCode,
  });

  final ApiFailureType type;
  final String message;
  final int? statusCode;

  String get userMessage => switch (type) {
        ApiFailureType.configuration =>
          'الخدمة غير مهيأة حاليًا. يرجى المحاولة لاحقًا.',
        ApiFailureType.authentication =>
          'تعذر التحقق من الجلسة. يرجى تسجيل الدخول مجددًا.',
        ApiFailureType.http => userMessageForHttpStatus(statusCode),
        ApiFailureType.network =>
          'تعذر الاتصال بالخادم. تحقق من اتصال الإنترنت وحاول مرة أخرى.',
        ApiFailureType.decoding =>
          'تعذر قراءة استجابة الخادم. حاول مرة أخرى لاحقًا.',
      };

  static String userMessageForHttpStatus(int? statusCode) {
    switch (statusCode) {
      case 400:
      case 422:
        return 'تعذر إكمال الطلب. راجع المعلومات وحاول مرة أخرى.';
      case 401:
        return 'تعذر التحقق من الجلسة. يرجى المحاولة مجددًا.';
      case 403:
        return 'لا تملك صلاحية تنفيذ هذا الطلب.';
      case 404:
        return 'لم يتم العثور على البيانات المطلوبة.';
      case 409:
        return 'تعارضت البيانات الحالية مع الطلب. حدّث البيانات ثم حاول مجددًا.';
      default:
        if (statusCode != null && statusCode >= 500) {
          return 'الخادم غير متاح حاليًا. حاول مرة أخرى لاحقًا.';
        }
        return 'تعذر إكمال الطلب. حاول مرة أخرى لاحقًا.';
    }
  }

  @override
  String toString() => 'ApiException(${type.name}, $statusCode): $message';
}
