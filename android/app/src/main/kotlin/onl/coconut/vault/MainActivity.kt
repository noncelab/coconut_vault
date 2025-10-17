package onl.coconut.vault

import android.database.ContentObserver
import android.os.Handler
import android.os.Looper
import android.os.Build
import android.os.Bundle // FLAG_SECURE에 필요
import android.view.WindowManager   // FLAG_SECURE에 필요
import android.provider.Settings
import android.provider.Settings.Global.DEVELOPMENT_SETTINGS_ENABLED
import androidx.annotation.NonNull
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "onl.coconut.vault/os"
    private val SYSTEM_SETTINGS_CHANNEL = "system_settings"
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // 🔒 앱 화면 스크린샷/최근앱 썸네일 차단
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPlatformVersion" -> {
                    result.success(Build.VERSION.RELEASE)
                }
                "getSdkVersion" -> {
                    result.success(Build.VERSION.SDK_INT)
                }
                "isDeveloperModeEnabled" -> {
                    result.success(isDeveloperModeEnabled())
                }
                // 런타임 토글이 필요하면 아래 메서드를 Dart에서 호출하세요.
                // ex) 
                // static const _ch = MethodChannel('onl.coconut.vault/os');
                // Future<void> enablePrivacyOverlay() async {
                //   await _ch.invokeMethod('setFlagSecure', {'enable': true});
                // }
                // Future<void> disablePrivacyOverlay() async {
                //   await _ch.invokeMethod('setFlagSecure', {'enable': false});
                // }
                "setFlagSecure" -> {
                    val enable = call.argument<Boolean>("enable") ?: true
                    if (enable) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(null)
                }
                "isDeviceSecure" -> { 
                    result.success(isDeviceSecure())
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SYSTEM_SETTINGS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openSecuritySettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_SECURITY_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("OPEN_SECURITY_SETTINGS_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        contentResolver.registerContentObserver(
            Settings.Global.getUriFor(DEVELOPMENT_SETTINGS_ENABLED),
            false,
            object : ContentObserver(Handler(Looper.getMainLooper())) {
                override fun onChange(selfChange: Boolean) {
                    val isEnabled = isDeveloperModeEnabled()
                    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).invokeMethod("onDeveloperModeChanged", isEnabled)
                }
            }
        )
    }

    private fun isDeveloperModeEnabled(): Boolean {
        return Settings.Secure.getInt(
            contentResolver,
            Settings.Global.DEVELOPMENT_SETTINGS_ENABLED, 0
        ) != 0
    }

    private fun isDeviceSecure(): Boolean {
        val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        return keyguardManager.isDeviceSecure
    }
}