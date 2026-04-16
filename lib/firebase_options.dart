import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCZSEfZ5BvE774IJARx9Kyhp4Xpd6kIfUI',
    appId: '1:835320418280:android:3c50bae385ee935a435e5d',
    messagingSenderId: '835320418280',
    projectId: 'academic-ally-app',
    storageBucket: 'academic-ally-app.appspot.com',
  );

  // iOS config placeholder — fill when you have a Mac to build iOS
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: '',
    appId: '',
    messagingSenderId: '835320418280',
    projectId: 'academic-ally-app',
    storageBucket: 'academic-ally-app.appspot.com',
    iosBundleId: 'com.academically',
  );
}
