import 'dart:io';

import 'package:path_provider/path_provider.dart';

class AppDirGetter {
  static Future<Directory> getAppDir() async {
    if (Platform.isIOS || Platform.isMacOS) {
      return getLibraryDirectory();
    }

    if (Platform.isAndroid) {
      return getApplicationSupportDirectory();
    }

    return getApplicationDocumentsDirectory();
  }
}
