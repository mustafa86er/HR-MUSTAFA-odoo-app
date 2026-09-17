import 'package:geolocator/geolocator.dart';
import '../config/odoo_config.dart';
import 'odoo_client.dart';

class AttendanceRecord {
  final int id;
  final DateTime checkIn;
  final DateTime? checkOut;
  final double? workedHours;

  AttendanceRecord({
    required this.id,
    required this.checkIn,
    this.checkOut,
    this.workedHours,
  });

  factory AttendanceRecord.fromOdoo(Map<String, dynamic> row) {
    return AttendanceRecord(
      id: row['id'] as int,
      checkIn: DateTime.parse((row['check_in'] as String).replaceFirst(' ', 'T')),
      checkOut: row['check_out'] == false
          ? null
          : DateTime.parse((row['check_out'] as String).replaceFirst(' ', 'T')),
      workedHours: (row['worked_hours'] as num?)?.toDouble(),
    );
  }
}

/// خدمة الحضور والانصراف - تعمل مباشرة على موديل hr.attendance في Odoo
class AttendanceService {
  final OdooClient _client = OdooClient.instance;

  Future<Position?> _getLocationIfRequired() async {
    if (!OdooConfig.requireGeoLocation) return null;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw OdooException('خدمة تحديد الموقع غير مفعّلة على الجهاز');
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw OdooException('تم رفض إذن الموقع، لا يمكن تسجيل الحضور');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw OdooException('إذن الموقع مرفوض بشكل دائم، فعّله من إعدادات الجهاز');
    }
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (OdooConfig.officeLat != null &&
        OdooConfig.officeLng != null &&
        OdooConfig.officeGeofenceRadiusMeters != null) {
      final distance = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        OdooConfig.officeLat!,
        OdooConfig.officeLng!,
      );
      if (distance > OdooConfig.officeGeofenceRadiusMeters!) {
        throw OdooException(
          'أنت خارج نطاق الموقع المسموح به (${distance.toStringAsFixed(0)} م)',
        );
      }
    }
    return pos;
  }

  /// آخر سجل حضور مفتوح (بدون check_out) إن وجد
  Future<AttendanceRecord?> getOpenAttendance(int employeeId) async {
    final rows = await _client.searchRead(
      'hr.attendance',
      domain: [
        ['employee_id', '=', employeeId],
        ['check_out', '=', false],
      ],
      fields: ['id', 'check_in', 'check_out', 'worked_hours'],
      order: 'check_in desc',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AttendanceRecord.fromOdoo(rows.first);
  }

  Future<List<AttendanceRecord>> getHistory(
    int employeeId, {
    int limit = 30,
  }) async {
    final rows = await _client.searchRead(
      'hr.attendance',
      domain: [
        ['employee_id', '=', employeeId],
      ],
      fields: ['id', 'check_in', 'check_out', 'worked_hours'],
      order: 'check_in desc',
      limit: limit,
    );
    return rows.map((r) => AttendanceRecord.fromOdoo(r)).toList();
  }

  Future<void> checkIn(int employeeId) async {
    final pos = await _getLocationIfRequired();
    final values = <String, dynamic>{
      'employee_id': employeeId,
      'check_in': _nowAsOdooString(),
    };
    if (pos != null) {
      values['in_latitude'] = pos.latitude;
      values['in_longitude'] = pos.longitude;
    }
    await _client.create('hr.attendance', values);
  }

  Future<void> checkOut(int attendanceId) async {
    final pos = await _getLocationIfRequired();
    final values = <String, dynamic>{
      'check_out': _nowAsOdooString(),
    };
    if (pos != null) {
      values['out_latitude'] = pos.latitude;
      values['out_longitude'] = pos.longitude;
    }
    await _client.write('hr.attendance', [attendanceId], values);
  }

  String _nowAsOdooString() {
    final now = DateTime.now().toUtc();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
  }
}
