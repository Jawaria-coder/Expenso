import 'dart:io';

class AddHelper{
  static String get bannerAdUnitId{
    if(Platform.isAndroid){
      return 'ca-app-pub-3940256099942544/6300978111';
    }
    else{
      throw UnsupportedError('Unsupported Platform');
    }
  }
}