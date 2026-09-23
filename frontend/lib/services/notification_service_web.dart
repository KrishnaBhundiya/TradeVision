import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  Future<void> init() async {
    debugPrint('[NotificationService] Web environment active: in-app notifications enabled.');
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    debugPrint('[NotificationService] [Web] $title: $body');
  }
}
