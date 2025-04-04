import 'package:flutter/material.dart';

class PrepareUpdateViewModel extends ChangeNotifier {
  late bool _hasBackupFile;

  PrepareUpdateViewModel() {
    _hasBackupFile = false;
  }

  void setHasBackupFile(bool value) {
    _hasBackupFile = value;
    notifyListeners();
  }
}
