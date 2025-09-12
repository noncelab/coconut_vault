package onl.coconut.vault

import android.database.ContentObserver
import android.os.Handler
import android.os.Looper
import android.os.Build
import android.provider.Settings
import android.provider.Settings.Global.DEVELOPMENT_SETTINGS_ENABLED
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Arrays

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "onl.coconut.vault/os"
    private val SECURE_MEMORY_CHANNEL = "onl.coconut.vault/secure_memory"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getPlatformVersion") {
                val version = Build.VERSION.RELEASE
                result.success(version)
            } else if(call.method == "getSdkVersion"){
                result.success(Build.VERSION.SDK_INT)
            }
            else if (call.method == "isDeveloperModeEnabled") {
                    result.success(isDeveloperModeEnabled())
            }
            else {
                result.notImplemented()
            }
        }

        // 보안 메모리 채널
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SECURE_MEMORY_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "wipe") {
                val args = call.arguments as? Map<String, Any>
                val data = args?.get("data") as? ByteArray
                
                if (data != null) {
                    // debugMemory(data, "삭제 전")
                    
                    Arrays.fill(data, 0.toByte())
                    
                    //debugMemory(data, "삭제 후")
                }
                result.success(null)
            } else {
                result.notImplemented()
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

    // 메모리 디버깅 함수
    private fun debugMemory(data: ByteArray, label: String) {
        val firstBytes = data.take(8).toByteArray()
        val lastBytes = data.takeLast(8).toByteArray()
        
        println("""
            🔍 $label
            �� 주소: ${data.hashCode()}
            📏 크기: ${data.size} bytes
            🔢 첫 8바이트: ${formatBytes(firstBytes)}
            🔢 마지막 8바이트: ${formatBytes(lastBytes)}
        """.trimIndent())
    }
    
    // 바이트 배열을 16진수 문자열로 포맷팅
    private fun formatBytes(bytes: ByteArray): String {
        return bytes.joinToString(" ") { "0x${it.toUByte().toString(16).padStart(2, '0').uppercase()}" }
    }
}