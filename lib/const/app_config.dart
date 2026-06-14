import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static bool get allowRepetitivePersonScan {
    try {
      final value = dotenv.env['ALLOW_REPETITIVE_PERSON_SCAN'];
      return value?.toLowerCase() == 'true';
    } catch (_) {
      return false;
    }
  }
  
  static bool get allowSameUserScan {
    try {
      final value = dotenv.env['ALLOW_SAME_USER_SCAN'];
      return value?.toLowerCase() == 'true';
    } catch (_) {
      return false;
    }
  }
}