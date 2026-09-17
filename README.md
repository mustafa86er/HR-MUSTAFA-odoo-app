# تطبيق HR متكامل مرتبط بـ Odoo (Flutter + JSON-RPC)

تطبيق موبايل (Flutter) يوسّع مشروع الحضور الحالي ليصبح تطبيق موارد بشرية متكامل، بدون أي موديول مخصص داخل Odoo — كل الاتصال يتم عبر JSON-RPC القياسي (`/jsonrpc`) الموجود افتراضيًا في أي Odoo Enterprise/Community.

## المزايا المطبَّقة

1. **تسجيل الدخول** بحساب Odoo نفسه (نفس المستخدم وكلمة المرور)، مع حفظ الجلسة محليًا بشكل مشفّر (`flutter_secure_storage`) وتسجيل دخول تلقائي.
2. **الحضور والانصراف** — موديل `hr.attendance`: تسجيل حضور/انصراف بضغطة واحدة، مع إرفاق الموقع الجغرافي (اختياري + قابل لتحديد نطاق مكتب/جيوفنس)، وعرض سجل آخر 30 حركة.
3. **الإجازات** — موديل `hr.leave` و `hr.leave.type`: عرض طلبات الموظف، إنشاء طلب جديد (نوع + تاريخ من/إلى + سبب)، ومتابعة الحالة (مسودة/بانتظار/مقبولة/مرفوضة).
4. **الرواتب** — موديل `hr.payslip` (+ `hr.payslip.line` لجلب صافي الراتب `NET`): عرض كشوف الرواتب وحالتها وصافي الأجر، إن كان تطبيق Payroll مفعّلاً في قاعدة Odoo.
5. **شاشة موافقات المدير** — تظهر تلقائيًا فقط للمستخدم الذي لديه مرؤوسون (`parent_id` في `hr.employee`): تعرض طلبات إجازة فريقه المنتظرة وتسمح بالقبول/الرفض مباشرة عبر استدعاء `action_approve` / `action_refuse` على `hr.leave` (نفس منطق الموافقة في Odoo تمامًا).

## متطلبات جهة Odoo (لا حاجة لأي كود Python جديد)

- المستخدم الذي سيسجّل الدخول من التطبيق يجب أن يكون له **سجل موظف (hr.employee)** مرتبط بحقل `user_id` بنفس حسابه، وإلا سيظهر خطأ واضح عند الدخول.
- صلاحيات Odoo القياسية لـ HR/Employee, Time Off, Payroll يجب أن تكون مفعّلة لمجموعة المستخدم (نفس الصلاحيات المستخدمة في الواجهة الويب تُطبَّق تلقائيًا هنا لأن الاتصال يمر بنفس محرك الصلاحيات).
- **XML-RPC/JSON-RPC** مفعّل افتراضيًا في Odoo — لا حاجة لأي إعداد إضافي على السيرفر (يعمل على Odoo.sh كما هو).
- لتفعيل قسم الرواتب، تطبيق **Payroll** يجب أن يكون مثبّتًا في القاعدة.

## الإعداد قبل البناء

عدّل الملف `lib/config/odoo_config.dart`:

```dart
static const String baseUrl = 'https://asasaletehad2026.odoo.com'; // رابط قاعدة Odoo.sh
static const String database = 'asasaletehad2026';
static const bool requireGeoLocation = true; // false لتعطيل طلب الموقع
```

إن أردت تقييد تسجيل الحضور بنطاق جغرافي للمكتب (جيوفنس)، عبّئ:

```dart
static const double? officeGeofenceRadiusMeters = 150;
static const double? officeLat = 32.8872;
static const double? officeLng = 13.1913;
```

## التشغيل والبناء

```bash
flutter pub get
flutter run                 # تشغيل على جهاز/محاكي متصل
flutter build apk --release # بناء APK لأندرويد
flutter build ios --release # بناء لـ iOS (يتطلب macOS + Xcode)
```

> ملاحظة iOS: أضف في `ios/Runner/Info.plist` مفتاحي
> `NSLocationWhenInUseUsageDescription` بنص يوضح سبب استخدام الموقع عند تسجيل الحضور.

## بنية المشروع

```
lib/
  config/odoo_config.dart       إعدادات الاتصال بـ Odoo
  services/
    odoo_client.dart            طبقة JSON-RPC عامة (login, search_read, create, write, execute_kw)
    employee_service.dart       جلب بيانات الموظف الحالي + هل هو مدير
    attendance_service.dart     حضور/انصراف + الموقع الجغرافي
    leave_service.dart          الإجازات (طلب/عرض/موافقة/رفض)
    payslip_service.dart        كشوف الرواتب
    app_state.dart              حالة الجلسة العامة (Provider)
  screens/
    login_screen.dart
    home_screen.dart            التنقّل السفلي (يظهر تبويب "الموافقات" للمدراء فقط)
    attendance_screen.dart
    leave_screen.dart           + شاشة طلب إجازة جديد
    payslip_screen.dart
    approvals_screen.dart       شاشة موافقة المدير
```

## أمان

- كلمة المرور تُخزَّن محليًا فقط عبر `flutter_secure_storage` (Keystore/Keychain)، ولا تُرسَل لأي طرف ثالث — فقط لخادم Odoo نفسه عبر HTTPS في كل طلب (نفس آلية عمل XML-RPC القياسية في Odoo).
- يُنصح باستخدام مستخدم Odoo عادي (وليس Admin) لكل موظف، بحيث تُطبَّق صلاحيات الوصول القياسية لكل شخص (كل موظف يرى بياناته فقط، والمدير يرى فريقه فقط) — وهذا مضمون تلقائيًا لأن كل الطلبات تمر بمحرك صلاحيات Odoo نفسه.

## التوزيع الداخلي عبر Firebase App Distribution

مشروع أندرويد مُجهّز مسبقًا بإضافة Firebase App Distribution (`android/app/build.gradle`)، ومعرّف التطبيق (`applicationId`) هو:
```
com.alejtehad.hr_odoo_app
```
استخدم نفس هذا المعرّف بالضبط عند إضافة تطبيق أندرويد في Firebase Console حتى يتطابق `google-services.json` مع المشروع.

خطوات التفعيل:

1. أنشئ مشروعًا في [console.firebase.google.com](https://console.firebase.google.com) (مجاني).
2. أضف تطبيق أندرويد بنفس المعرّف أعلاه، وحمّل ملف `google-services.json` وضعه في:
   ```
   android/app/google-services.json
   ```
3. من داخل مجلد المشروع:
   ```
   npm install -g firebase-tools
   firebase login
   ```
4. أنشئ مجموعة مختبِرين باسم `employees` من قسم App Distribution في Firebase، وأضف إيميلات الموظفين إليها (الاسم مضبوط مسبقًا في `build.gradle`، غيّره هناك إن أردت اسمًا آخر).
5. ابنِ وانشر مباشرة بأمر واحد:
   ```
   flutter build apk --release
   firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
     --app <APP_ID_من_Firebase> \
     --groups "employees"
   ```
   أو، بما أن `firebaseAppDistribution` مفعّل داخل Gradle، يمكن أيضًا تشغيل:
   ```
   ./gradlew assembleRelease appDistributionUploadRelease
   ```
6. كل موظف مضاف للمجموعة يستلم إيميل دعوة لتثبيت "Firebase App Tester" ثم تحميل نسخة HR منه مباشرة، وأي تحديث لاحق يصله تلقائيًا.

> ملاحظة: التوقيع حاليًا بمفتاح debug المؤقت لتسهيل الاختبار الداخلي. قبل أي نشر رسمي على متجر Google Play، يجب إنشاء مفتاح توقيع release خاص واستبداله في `signingConfigs`.

## للتوسّع لاحقًا

- إشعارات Push عند اعتماد/رفض إجازة (يتطلب دمج FCM + دالة صغيرة على السيرفر أو Webhook).
- عرض هيكل الفريق (Org Chart) من `hr.employee`.
- تسجيل حضور عبر QR Code بدلاً من/بالإضافة إلى GPS.
- تصدير كشف الراتب كـ PDF مباشرة من `report.action` الخاص بـ Odoo.
