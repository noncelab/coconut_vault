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
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

import android.util.Log

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
        flutterEngine.plugins.add(StrongBoxKeystorePlugin())

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
                "isJailbroken" -> {
                    result.success(isDeviceRooted())
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
        return Settings.Global.getInt(
            contentResolver,
            Settings.Global.DEVELOPMENT_SETTINGS_ENABLED, 0
        ) != 0
    }

    private fun isDeviceSecure(): Boolean {
        val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        return keyguardManager.isDeviceSecure
    }

    private fun isDeviceRooted(): Boolean {

        if (canExecuteSuCommand()) {
             Log.w("canExecuteSuCommand", "Root check: canExecuteSuCommand")
            return true
        }

        val buildTags = android.os.Build.TAGS
        if (buildTags != null && buildTags.contains("test-keys")) {
            return true
        }

        if (isSystemPropertyIndicatingRoot()) {
            return true
        }

        if (hasRootPaths()) {
            return true
        }

        if (isSELinuxPermissive()) {
            return true
        }
    
        return false
    }

    private fun canExecuteSuCommand(): Boolean {
        return try {
            val process = Runtime.getRuntime().exec(arrayOf("su", "-c", "id"))
            val reader = process.inputStream.bufferedReader()
            val result = reader.readLine()
            
            result?.contains("uid=0") == true
        } catch (e: Exception) {
            false
        }
    }

    private fun isSystemPropertyIndicatingRoot(): Boolean {
        try {
            val process = Runtime.getRuntime().exec("getprop ro.debuggable")
            val reader = process.inputStream.bufferedReader()
            val debuggable = reader.readLine()
            if (debuggable == "1") return true
        } catch (e: Exception) {
        }
        
        try {
            val process = Runtime.getRuntime().exec("getprop ro.secure")
            val reader = process.inputStream.bufferedReader()
            val secure = reader.readLine()
            if (secure == "0") return true
        } catch (e: Exception) {
        }
        
        return false
    }

    private fun hasRootPaths(): Boolean {
        val paths = arrayOf(
            "/system/app/Superuser.apk",
            "/sbin/su",
            "/system/bin/su",
            "/system/xbin/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
            "/data/local/su",
            // Magisk 관련 (일반적인 경로)
            "/data/adb/magisk",
            "/sbin/.magisk",
            "/dev/.magisk",
            // BusyBox (일반적인 루팅 도구)
            "/system/xbin/busybox",
            "/system/bin/busybox",
            "/data/local/busybox"
        )
        return paths.any { File(it).exists() }
    }

    private fun isSELinuxPermissive(): Boolean {
        return try {
            val process = Runtime.getRuntime().exec("getenforce")
            val reader = process.inputStream.bufferedReader()
            val selinux = reader.readLine()
            selinux?.contains("Permissive", ignoreCase = true) == true
        } catch (e: Exception) {
            false
        }
    }
}