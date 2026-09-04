import 'dart:async';
import 'dart:convert';

import 'package:academically/features/snap_doubt/services/doubt_capture_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Picker extends ImagePicker {
  final pending = Completer<XFile?>();
  LostDataResponse lost = LostDataResponse.empty();

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) => pending.future;

  @override
  Future<LostDataResponse> retrieveLostData() async => lost;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('restart recovers camera result and subject exactly once', () async {
    final picker = _Picker();
    final service = DoubtCaptureService(picker: picker);
    final pending = service.pick(
      uid: 'owner',
      subject: 'Math',
      source: ImageSource.camera,
    );
    await Future<void>.delayed(Duration.zero);
    expect(await service.hasPending('owner'), isTrue);
    picker.lost = LostDataResponse(
      files: [XFile('/tmp/question.jpg')],
      type: RetrieveType.image,
    );
    final restarted = DoubtCaptureService(picker: picker);
    expect(await restarted.recover('owner'), (
      imagePath: '/tmp/question.jpg',
      subject: 'Math',
    ));
    expect(await restarted.recover('owner'), isNull);
    picker.pending.complete(null);
    await pending;
  });

  test('cancel clears pending capture', () async {
    final picker = _Picker()..pending.complete(null);
    final service = DoubtCaptureService(picker: picker);
    expect(
      await service.pick(
        uid: 'owner',
        subject: 'Math',
        source: ImageSource.gallery,
      ),
      isNull,
    );
    expect(await service.hasPending('owner'), isFalse);
  });

  test('recovered photo is never returned to a different account', () async {
    SharedPreferences.setMockInitialValues({
      'pending_doubt_capture': jsonEncode({'uid': 'owner', 'subject': 'Math'}),
    });
    final picker = _Picker()
      ..lost = LostDataResponse(
        files: [XFile('/tmp/private.jpg')],
        type: RetrieveType.image,
      );
    final service = DoubtCaptureService(picker: picker);
    expect(await service.hasPending('different'), isFalse);
    expect(await service.recover('different'), isNull);
    expect(await service.hasPending('owner'), isFalse);
  });

  test('picker failure clears pending capture and surfaces error', () async {
    final picker = _Picker();
    final service = DoubtCaptureService(picker: picker);
    final future = service.pick(
      uid: 'owner',
      subject: 'Math',
      source: ImageSource.camera,
    );
    final assertion = expectLater(future, throwsA(isA<PlatformException>()));
    await Future<void>.delayed(Duration.zero);
    picker.pending.completeError(
      PlatformException(code: 'camera_access_denied'),
    );
    await assertion;
    expect(await service.hasPending('owner'), isFalse);
  });

  test('malformed pending state cannot strand startup on splash', () async {
    SharedPreferences.setMockInitialValues({'pending_doubt_capture': '{bad'});
    expect(await DoubtCaptureService().hasPending('owner'), isFalse);
  });
}
