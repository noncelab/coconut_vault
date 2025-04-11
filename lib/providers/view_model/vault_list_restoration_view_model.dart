import 'package:coconut_vault/model/common/vault_list_item_base.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/utils/coconut/update_preparation.dart';
import 'package:flutter/material.dart';

class VaultListRestorationViewModel extends ChangeNotifier {
  late bool _isVaultListRestored;
  late bool _isRestoreProcessing;
  late int _restoreProgress;
  late final WalletProvider _walletProvider;

  VaultListRestorationViewModel(this._walletProvider) {
    _isVaultListRestored = false;
    _isRestoreProcessing = false;
    _restoreProgress = 0;
  }

  bool get isVaultListRestored => _isVaultListRestored;
  bool get isRestoreProcessing => _isRestoreProcessing;
  int get restoreProgress => _restoreProgress;
  List<VaultListItemBase> get vaultList => _walletProvider.vaultList;

  void setRestoreProgress(int progress) {
    _restoreProgress = progress;
    notifyListeners();
  }

  void setIsVaultListRestored(bool isRestored) {
    _isVaultListRestored = isRestored;
    _isRestoreProcessing = !isRestored;
    notifyListeners();
  }

  void restoreVaultList() async {
    _isRestoreProcessing = true;
    notifyListeners();
    try {
      debugPrint('[restoreVaultList] 복구 가능 상태인지 확인');
      // 복구 가능 상태인지 확인
      await UpdatePreparation.validatePreparationState();
    } catch (e) {
      // 복구 불가능 상태
      debugPrint('[Error] 복구 불가능 상태: $e');

      _isRestoreProcessing = false;
      notifyListeners();
      return;
    }

    debugPrint('[restoreVaultList] 복호화 작업 시작');
    setRestoreProgress(5);
    var backupData = await UpdatePreparation.readAndDecrypt();

    debugPrint('[restoreVaultList] 복호화 작업 종료, 복원 시작 (50%)');
    setRestoreProgress(50);

    await _walletProvider.restoreFromBackupData(backupData);

    debugPrint('[restoreVaultList] 복원 작업 종료, 백업 파일 삭제 중.. (90%)');
    setRestoreProgress(90);

    await UpdatePreparation.clearUpdatePreparationStorage();

    debugPrint('[restoreVaultList] 백업 파일 삭제 완료, 프로세스 종료 대기(100%, 3초)');
    setRestoreProgress(100);
  }
}
