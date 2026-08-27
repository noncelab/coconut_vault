import 'package:coconut_vault/providers/auth_provider.dart';
import 'package:coconut_vault/providers/preference_provider.dart';
import 'package:coconut_vault/providers/wallet_provider.dart';
import 'package:coconut_vault/repository/wallet_storage_cleaner.dart';

/// 사용자 신원(PIN/biometric)과 모든 vault 데이터를 초기화하는 usecase.
///
/// 정리 대상:
/// - 모든 vault 데이터: SecureZone alias, FlutterSecureStorage, SharedPrefs vault 메타
///   (`kVaultListField`, `vaultListLength`, `kNextIdField`)
/// - 인증 상태: PIN, biometric 토글, lockout 기록
/// - vault 정렬 정보: vault 순서, 즐겨찾기
///
/// 보존 항목 (사용자 UX 설정):
/// - 패스프레이즈 사용 여부 (`kPassphraseUseEnabled`)
/// - 계정 변경 사용 여부 (`kChangeAccountEnabled`)
/// - 언어, BTC 단위, vault 모드, edge panel 위치 등
///
/// 사용처 예시:
/// - 비밀번호 분실 후 초기화 (PinCheckScreen)
/// - PIN 시도 횟수 초과 (PinCheckScreen)
/// - 보안 영역 접근 불가 -> 데이터 삭제 (precheck 화면들)
class ResetCredentialsAndWalletsUsecase {
  ResetCredentialsAndWalletsUsecase._();

  /// 화면 reload(`reloadRelatedToVault` 등)가 필요하면 호출 측에서 별도로 수행하세요.
  static Future<void> execute({
    WalletProvider? walletProvider,
    required AuthProvider authProvider,
    required PreferenceProvider preferenceProvider,
    bool preservePermanentLock = false,
  }) async {
    if (walletProvider != null) {
      await walletProvider.reset();
    } else {
      await WalletStorageCleaner.clearAll();
    }
    await preferenceProvider.resetVaultOrderAndFavorites();
    await authProvider.resetCredentials(preservePermanentLock: preservePermanentLock);
  }
}
