import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Promemoria giornaliero: suona all'ora scelta, ma non nei giorni in cui ci si è già allenati.
class Reminder {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  static const _id = 1;

  bool get supported => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  Future<bool> _init() async {
    if (_ready) return true;
    if (!supported) return false;
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation((await FlutterTimezone.getLocalTimezone()).identifier));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false),
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('promemoria: $e');
    }
    return _ready;
  }

  /// Chiede il permesso per le notifiche; true se concesso.
  Future<bool> askPermission() async {
    if (!await _init()) return false;
    final a = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final i = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    return (await a?.requestNotificationsPermission() ?? await i?.requestPermissions(alert: true, sound: true)) ?? false;
  }

  /// Il prossimo avviso: oggi all'ora scelta, oppure domani se ci si è già allenati o l'ora è passata.
  static DateTime nextAt(DateTime now, String at, bool trainedToday) {
    final p = at.split(':'), today = DateTime(now.year, now.month, now.day, int.parse(p[0]), int.parse(p[1]));
    return trainedToday || !today.isAfter(now) ? today.add(const Duration(days: 1)) : today;
  }

  Future<void> sync({required bool on, required String at, required bool trainedToday, String body = 'Pochi minuti di kihon e la tua serie continua.'}) async {
    if (!await _init()) return;
    try {
      await _plugin.cancel(id: _id);
      if (!on) return;
      final n = nextAt(DateTime.now(), at, trainedToday);
      await _plugin.zonedSchedule(
        id: _id,
        scheduledDate: tz.TZDateTime(tz.local, n.year, n.month, n.day, n.hour, n.minute),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails('promemoria', 'Promemoria', channelDescription: 'Un avviso al giorno per allenarsi'),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: 'Oggi al dojo',
        body: body,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('promemoria: $e');
    }
  }
}
