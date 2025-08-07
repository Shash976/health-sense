import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class NetworkUtils {
  static Future<String?> getWifiIp() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        if (interface.name.contains('wlan') || interface.name.contains('wifi')) {
          for (var addr in interface.addresses) {
            if (addr.type == InternetAddressType.IPv4) {
              return addr.address;
            }
          }
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  static String getHotspotSubnet(String ip) {
    // Most Android hotspots use 192.168.43.x, but fallback to current IP subnet
    if (ip.startsWith('192.168.43.')) {
      return '192.168.43.';
    }
    return ip.substring(0, ip.lastIndexOf('.') + 1);
  }
}

