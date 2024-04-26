import 'dart:io';

class AdHelper {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-9922819544973761/3118792741';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-9922819544973761/3118792741';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-9922819544973761/7987976049';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-9922819544973761/7987976049';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

// static String get rewardedAdUnitId {
//   if (Platform.isAndroid) {
//     return '<YOUR_ANDROID_REWARDED_AD_UNIT_ID>';
//   } else if (Platform.isIOS) {
//     return '<YOUR_IOS_REWARDED_AD_UNIT_ID>';
//   } else {
//     throw UnsupportedError('Unsupported platform');
//   }
// }
}

class AdHelperTest {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    } else {
      throw new UnsupportedError('Unsupported platform');
    }
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-3940256099942544/1033173712";
    } else if (Platform.isIOS) {
      return "ca-app-pub-3940256099942544/4411468910";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-3940256099942544/5224354917";
    } else if (Platform.isIOS) {
      return "ca-app-pub-3940256099942544/1712485313";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }
}
