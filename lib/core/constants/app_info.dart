import 'package:package_info_plus/package_info_plus.dart';

class AppInfo {
  static PackageInfo? _packageInfo;

  static Future<void> initialize() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  static String get version => _packageInfo?.version ?? '1.0.0';
  static String get buildNumber => _packageInfo?.buildNumber ?? '1';
  static String get fullVersion => '$version+$buildNumber';
  static String get appName => _packageInfo?.appName ?? 'InsideX';
}
