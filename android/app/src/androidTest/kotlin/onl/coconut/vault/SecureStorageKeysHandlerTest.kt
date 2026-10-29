package onl.coconut.vault

import android.content.Context
import android.util.Base64
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import androidx.test.platform.app.InstrumentationRegistry
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.junit.Assert.*
import org.junit.Test

class SecureStorageKeysHandlerTest {
    // Use a separate file: these tests never touch installed wallet/auth records.
    private val file = "test_only_secure_storage_keys"
    private val context get() = InstrumentationRegistry.getInstrumentation().targetContext

    private class Reply : MethodChannel.Result {
        var keys: Any? = null
        var error: String? = null
        override fun success(result: Any?) { keys = result }
        override fun error(code: String, message: String?, details: Any?) { error = code }
        override fun notImplemented() { error = "notImplemented" }
    }

    @Test
    fun corruptedEncryptedValueDoesNotPreventEnumerationOrDeletion() {
        context.deleteSharedPreferences(file)
        try {
            val master = MasterKey.Builder(context).setKeyScheme(MasterKey.KeyScheme.AES256_GCM).build()
            val encrypted = EncryptedSharedPreferences.create(
                context, file, master,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
            encrypted.edit().putString("v2__wallet", "wallet")
                .putString("v2__vault_pin_lock_v1", "lock").commit()
            val raw = context.getSharedPreferences(file, Context.MODE_PRIVATE)
            // Find the encrypted wallet key without depending on its ciphertext.
            val before = raw.all.keys.toSet()
            encrypted.edit().remove("v2__wallet").commit()
            val walletKey = (before - raw.all.keys).single()
            raw.edit().putString(walletKey, Base64.encodeToString(ByteArray(40), Base64.NO_WRAP)).commit()
            try {
                encrypted.all
                fail("readAll must fail for the damaged wallet value")
            } catch (_: SecurityException) { }

            val reply = Reply()
            val handler = SecureStorageKeysHandler(context, file)
            handler.onMethodCall(MethodCall("getAllKeys", null), reply)
            assertNull(reply.error)
            assertEquals(setOf("wallet", "vault_pin_lock_v1"), (reply.keys as List<*>).toSet())
            assertTrue(encrypted.edit().remove("v2__wallet").commit())
            assertEquals("lock", encrypted.getString("v2__vault_pin_lock_v1", null))
            val after = Reply()
            handler.onMethodCall(MethodCall("getAllKeys", null), after)
            assertNull(after.error)
            assertEquals(listOf("vault_pin_lock_v1"), after.keys)
        } finally {
            context.deleteSharedPreferences(file)
        }
    }

    @Test
    fun legacyCiphertextValuesAreNeverDecrypted() {
        context.deleteSharedPreferences(file)
        try {
            val raw = context.getSharedPreferences(file, Context.MODE_PRIVATE)
            raw.edit().putString("v2__wallet", "invalid legacy ciphertext")
                .putString("unrelated-setting", "ignored").commit()
            val reply = Reply()
            SecureStorageKeysHandler(context, file).onMethodCall(MethodCall("getAllKeys", null), reply)
            assertNull(reply.error)
            assertEquals(listOf("wallet"), reply.keys)
        } finally {
            context.deleteSharedPreferences(file)
        }
    }
}
