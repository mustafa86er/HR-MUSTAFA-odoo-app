/// إعدادات الاتصال بـ Odoo.
/// عدّل القيم هنا حسب بيئة العميل (Odoo.sh / on-premise).
class OdooConfig {
  /// رابط قاعدة Odoo (بدون شرطة مائلة في النهاية)
  /// مثال: https://asasaletehad2026.odoo.com
  static const String baseUrl = 'https://asasaletehad2026.odoo.com';

  /// اسم قاعدة البيانات في Odoo.sh
  static const String database = 'asasaletehad2026';

  /// مهلة الاتصال بالثواني
  static const int timeoutSeconds = 30;

  /// تفعيل استخدام الموقع الجغرافي عند تسجيل الحضور
  static const bool requireGeoLocation = true;

  /// نصف قطر الموقع المسموح به بالأمتار (اختياري - جيوفنس)
  static const double? officeGeofenceRadiusMeters = null; // null = بدون تقييد
  static const double? officeLat = null;
  static const double? officeLng = null;
}
