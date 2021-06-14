import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:downloader_manager/downloader_manager.dart';

void main() {
  const MethodChannel channel = MethodChannel('downloader_manager');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    // expect(await DownloaderManager.platformVersion, '42');
  });
}
