/// إعدادات الاتصال بـ Odoo.
/// عدّل القيم هنا حسب بيئة العميل (Odoo.sh / on-premise).
class OdooConfig {
  /// رابط قاعدة Odoo (بدون شرطة مائلة في النهاية)
  static const String baseUrl = 'https://mustafa86er-hr-alijtehad-app-main-38291258.dev.odoo.com';

  /// اسم قاعدة البيانات
  static const String database = 'mustafa86er-hr-alijtehad-app-main-38291258';

  /// مهلة الاتصال بالثواني
  static const int timeoutSeconds = 30;

  /// اسم فئة "تصحيح حضور" في تطبيق الموافقات (Approvals) على Odoo
  static const String attendanceCorrectionCategoryName = 'تصحيح حضور';

  /// تفعيل استخدام الموقع الجغرافي عند تسجيل الحضور
  static const bool requireGeoLocation = true;

  /// نصف قطر الموقع المسموح به بالأمتار (اختياري - جيوفنس)
  static const double? officeGeofenceRadiusMeters = null; // null = بدون تقييد
  static const double? officeLat = null;
  static const double? officeLng = null;
}
