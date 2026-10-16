package onl.coconut.vault

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Wait for flutter_secure_storage 9.x apply() writes. No values cross this channel. */
class PinAuthStorageHandler(private val context: Context) : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "flush") {
            result.notImplemented()
            return
        }
        try {
            val keySaved = context.getSharedPreferences("FlutterSecureKeyStorage", Context.MODE_PRIVATE)
                .edit().commit()
            // Must match SecureStorageRepository.androidOptions.sharedPreferencesName.
            val dataSaved = context.getSharedPreferences("SecureStorage_v2", Context.MODE_PRIVATE)
                .edit().commit()
            if (keySaved && dataSaved) result.success(true)
            else result.error("PIN_STORAGE_UNAVAILABLE", "Authentication storage unavailable", null)
        } catch (_: Exception) {
            result.error("PIN_STORAGE_UNAVAILABLE", "Authentication storage unavailable", null)
        }
    }
}
