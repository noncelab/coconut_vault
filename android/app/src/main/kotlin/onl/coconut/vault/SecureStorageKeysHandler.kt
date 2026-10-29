package onl.coconut.vault

import android.content.Context
import android.util.Base64
import com.google.crypto.tink.DeterministicAead
import com.google.crypto.tink.daead.DeterministicAeadConfig
import com.google.crypto.tink.integration.android.AndroidKeysetManager
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Names only; never decrypt wallet values while preparing a full reset.
 * These constants must match flutter_secure_storage 9.2.2 / security-crypto.
 */
class SecureStorageKeysHandler(
    private val context: Context,
    private val file: String = "SecureStorage_v2"
) : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "getAllKeys") {
            result.notImplemented()
            return
        }
        try {
            val prefix = "v2__"
            val keyset = "__androidx_security_crypto_encrypted_prefs_key_keyset__"
            val valueKeyset = "__androidx_security_crypto_encrypted_prefs_value_keyset__"
            val prefs = context.getSharedPreferences(file, Context.MODE_PRIVATE)
            // Wait for flutter_secure_storage's earlier apply() deletions to reach disk.
            check(prefs.edit().commit())
            val rawKeys = prefs.all.keys
            val encrypted = rawKeys.contains(keyset)
            // A missing keyset must never be regenerated during cleanup.
            check(encrypted == rawKeys.contains(valueKeyset))
            val cipher = if (encrypted) {
                DeterministicAeadConfig.register()
                AndroidKeysetManager.Builder()
                    .withSharedPref(context, keyset, file)
                    .withMasterKeyUri("android-keystore://_androidx_security_master_key_")
                    .build().keysetHandle.getPrimitive(DeterministicAead::class.java)
            } else null
            val keys = rawKeys.filter { it != keyset && it != valueKeyset }.map { raw ->
                if (cipher == null || raw.startsWith(prefix)) raw
                else String(cipher.decryptDeterministically(Base64.decode(raw, Base64.DEFAULT), file.toByteArray(Charsets.UTF_8)), Charsets.UTF_8)
            }.filter { it.startsWith(prefix) }.map { it.removePrefix(prefix) }
            result.success(keys)
        } catch (_: Exception) {
            result.error("SECURE_STORAGE_KEYS_UNAVAILABLE", "Secure storage key enumeration failed", null)
        }
    }
}
