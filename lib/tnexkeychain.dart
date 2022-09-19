
import 'dart:async';

import 'package:flutter/services.dart';

class Tnexkeychain {
  static const MethodChannel _channel = MethodChannel('tnexkeychain');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<bool?> authenticate() async {
    final bool? au = await _channel.invokeMethod('authenticate');
    return au;
  }

  static Future<bool?> createEntry() async {
    final bool? cr = await _channel.invokeMethod('createEntry');
    return cr;
  }
}
