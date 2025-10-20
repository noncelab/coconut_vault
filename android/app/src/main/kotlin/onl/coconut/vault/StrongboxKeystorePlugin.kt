package onl.coconut.vault

import android.content.Context
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.security.keystore.StrongBoxUnavailableException
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.spec.GCMParameterSpec
import kotlin.random.Random
import android.security.keystore.UserNotAuthenticatedException
import android.security.keystore.KeyPermanentlyInvalidatedException
import java.security.UnrecoverableKeyException
import java.security.InvalidKeyException

import android.util.Log

class StrongBoxKeystorePlugin: FlutterPlugin, MethodChannel.MethodCallHandler {
  private lateinit var channel: MethodChannel
  private val ANDROID_KEYSTORE = "AndroidKeyStore"
  private var lastUsedStrongBox = false
  companion object {
    private const val TAG = "StrongboxKeystore"
    private const val ANDROID_KEYSTORE = "AndroidKeyStore"
  }

  private lateinit var appContext: Context

  override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(binding.binaryMessenger, "onl.coconut.vault/secure_module")
    channel.setMethodCallHandler(this)
    appContext = binding.applicationContext
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
    when (call.method) {
      "isStrongBoxSupported" -> {
        result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) // API 28+
      }
      "generateKey" -> {
        val alias = call.argument<String>("alias")!!
        val userAuthRequired = call.argument<Boolean>("userAuthRequired") ?: false
        val perUseAuth = call.argument<Boolean>("perUseAuth") ?: false

        try {
          generateAesKey(alias, userAuthRequired, perUseAuth)
          result.success(null)
        } catch (e: Exception) {
          result.error("GEN_FAIL", e.message, null)
        }
      }
      "deleteKey" -> {
        val alias = call.argument<String>("alias")!!
        try {
          deleteAesKey(alias)
          result.success(null)
        } catch (e: Exception) {
          result.error("DEL_FAIL", e.message, null)
        }
      }
      "encrypt" -> {
        val alias = call.argument<String>("alias")!!
        val plaintext = readBytesArg(call, "plaintext")
        val aad = readBytesArg(call, "aad").takeIf { it.isNotEmpty() }

        try {
          val ks = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
          val key = ks.getKey(alias, null)
          val cipher = Cipher.getInstance("AES/GCM/NoPadding")
          cipher.init(Cipher.ENCRYPT_MODE, key)
          aad?.let { cipher.updateAAD(it) }
          val ciphertext = cipher.doFinal(plaintext)
          val iv = cipher.iv
          result.success(mapOf(
            "ciphertext" to ciphertext,
            "iv" to iv,
            "usedStrongBox" to lastUsedStrongBox
          ))
        } catch (e: UserNotAuthenticatedException) {
          result.error("AUTH_NEEDED", "User authentication required", null)
        } catch (e: UnrecoverableKeyException) {
          // 일부 기기에서 '인증 필요'가 여기서 던져짐
          if (e.message?.contains("User not authenticated", ignoreCase = true) == true) {
            result.error("AUTH_NEEDED", "User authentication required", null)
          } else {
            result.error("KEY_ERROR", e.message, null)
          }
        } catch (e: KeyPermanentlyInvalidatedException) {
          // 생체/잠금 변경 등 → 키 재생성 필요
          result.error("KEY_INVALIDATED", "Key permanently invalidated", null)
        } catch (e: InvalidKeyException) {
          // cause가 영구 무효화인 경우가 많음
          if (e.cause is KeyPermanentlyInvalidatedException) {
            result.error("KEY_INVALIDATED", "Key permanently invalidated", null)
          } else {
            result.error("INVALID_KEY", e.message, null)
          }
        } catch (e: Exception) {
          // 디버깅 편하게 예외 클래스도 함께 전달(개발 중)
          result.error("ENC_FAIL", "${e::class.java.simpleName}: ${e.message}", null)
        }
      }
      "decrypt" -> {
        val alias = call.argument<String>("alias")!!
        val ciphertext = readBytesArg(call, "ciphertext")
        val iv = readBytesArg(call, "iv")
        val aad = readBytesArg(call, "aad").takeIf { it.isNotEmpty() }

        try {
          val ks = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
          val key = ks.getKey(alias, null)
          val cipher = Cipher.getInstance("AES/GCM/NoPadding")
          val spec = GCMParameterSpec(128, iv)
          cipher.init(Cipher.DECRYPT_MODE, key, spec)
          aad?.let { cipher.updateAAD(it) }
          val plain = cipher.doFinal(ciphertext)
          result.success(plain)
        } catch (e: UserNotAuthenticatedException) {
          result.error("AUTH_NEEDED", "User authentication required", null)
        } catch (e: UnrecoverableKeyException) {
          // 일부 기기에서 '인증 필요'가 여기서 던져짐
          if (e.message?.contains("User not authenticated", ignoreCase = true) == true) {
            result.error("AUTH_NEEDED", "User authentication required", null)
          } else {
            result.error("KEY_ERROR", e.message, null)
          }
        } catch (e: KeyPermanentlyInvalidatedException) {
          // 생체/잠금 변경 등 → 키 재생성 필요
          result.error("KEY_INVALIDATED", "Key permanently invalidated", null)
        } catch (e: InvalidKeyException) {
          // cause가 영구 무효화인 경우가 많음
          if (e.cause is KeyPermanentlyInvalidatedException) {
            result.error("KEY_INVALIDATED", "Key permanently invalidated", null)
          } else {
            result.error("INVALID_KEY", e.message, null)
          }
        } catch (e: Exception) {
          // 디버깅 편하게 예외 클래스도 함께 전달(개발 중)
          result.error("ENC_FAIL", "${e::class.java.simpleName}: ${e.message}", null)
        }
      }
      "deleteAllKeys" -> {
        try {
          deleteAllKeys()
          result.success(null)
        } catch (e: Exception) {
          result.error("DEL_ALL_FAIL", e.message, null)
        }
      }
      else -> result.notImplemented()
    }
  }

  private fun readBytesArg(call: MethodCall, key: String): ByteArray {
    val any = call.argument<Any?>(key)
    return when (any) {
      is ByteArray -> any                     // Dart Uint8List → byte[] 그대로 (복사 없음)
      is List<*> -> {                         // Dart List<int> → ArrayList<Integer>
        val size = any.size
        val out = ByteArray(size)
        for (i in 0 until size) {
          val n = any[i] as Number
          out[i] = n.toByte()
        }
        out
      }
      null -> ByteArray(0)
      else -> throw IllegalArgumentException("Unsupported type for $key: ${any::class.java}")
    }
  }
  
  /**
   * If a key only supports biometric credentials, the key is invalidated by default whenever new biometric enrollments are added.
   * You can configure the key to remain valid when new biometric enrollments are added by passing false into setInvalidatedByBiometricEnrollment()
   * 
   * Android Keystore 내부 키는 다음 조건 중 하나라도 바뀌면 KeyPermanentlyInvalidatedException 이 발생합니다 👇
   * 잠금화면이 아예 없어지거나(None/Swipe) 기존 인증 방식(패턴 → PIN, PIN → 패턴, 또는 비밀번호 변경)이 바뀐 경우
   */
  private fun generateAesKey(alias: String, userAuthRequired: Boolean, perUseAuth: Boolean) {
    Log.d(TAG, "generateAesKey() start alias=$alias, userAuthRequired=$userAuthRequired, perUseAuth=$perUseAuth, sdk=${Build.VERSION.SDK_INT}")

    val ks = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
    // 이미 존재하면 삭제 후 재생성(필요 시 정책 변경 반영)
    if (ks.containsAlias(alias)) {
      try {
        ks.deleteEntry(alias)
      } catch (e: Exception) {
        Log.e(TAG, "deleteEntry($alias) failed", e)
      }
      
    }
   
    val builder = KeyGenParameterSpec.Builder(
      alias,
      KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
    ).setBlockModes(KeyProperties.BLOCK_MODE_GCM)
     .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
     .setKeySize(256)
     
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) { // 24+
      // 생체등록 추가로 키 무효화 방지
      builder.setInvalidatedByBiometricEnrollment(false)
      Log.d(TAG, "setInvalidatedByBiometricEnrollment(false) applied (API>=24)")
    } else {
      Log.d(TAG, "skip setInvalidatedByBiometricEnrollment (API<24)")
    }

    if (userAuthRequired) {
      builder.setUserAuthenticationRequired(true)
      // perUseAuth == true 면 매사용 인증(-1), 아니면 예: 300초 유예
      builder.setUserAuthenticationValidityDurationSeconds(if (perUseAuth) -1 else 300)
      Log.d(TAG, "setUserAuthenticationRequired(true), validity=${if (perUseAuth) -1 else 300}s")
    } else {
      Log.d(TAG, "userAuthRequired=false (no auth required)")
    }

    val keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEYSTORE)

    lastUsedStrongBox = false

    // 1) StrongBox가 있으면 먼저 StrongBox로 시도
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
      val hasStrongBox = try {
        // 일부 기기는 이 feature flag가 가장 신뢰할 수 있음
        val pm = appContext.packageManager
        pm.hasSystemFeature("android.hardware.strongbox_keystore")
      } catch (e: Exception) {
        Log.w(TAG, "hasSystemFeature(STRONGBOX) check failed, will still try StrongBox", e)
        true // 체크 실패 시 일단 시도해보고 예외로 판단
      }

      if (hasStrongBox) {
        try {
          Log.d(TAG, "Trying StrongBox-backed key generation")
          keyGenerator.init(builder.setIsStrongBoxBacked(true).build())
          keyGenerator.generateKey()
          lastUsedStrongBox = true
          Log.d(TAG, "StrongBox key generated")
          return
        } catch (e: StrongBoxUnavailableException) {
          Log.w(TAG, "StrongBoxUnavailableException → fallback to TEE", e)
        } catch (e: Exception) {
          // 일부 기기/펌웨어는 다른 예외를 던짐 → 폴백
          Log.w(TAG, "StrongBox failed → fallback to TEE", e)
        }
      } else {
        Log.d(TAG, "Device reports no StrongBox; skip StrongBox init")
      }
    } else {
      Log.d(TAG, "API < 28 → StrongBox not supported; use TEE")
    }

    // 2) 확실한 TEE 폴백
    try {
      Log.d(TAG, "Generating TEE-backed key")
      keyGenerator.init(
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P)
          builder.setIsStrongBoxBacked(false).build()
        else
          builder.build()
      )
      keyGenerator.generateKey()
      lastUsedStrongBox = false
      Log.d(TAG, "TEE key generated")
    } catch (e: Exception) {
      Log.e(TAG, "TEE key generation failed", e)
      throw e
    }
   
  }
  
  private fun deleteAesKey(alias: String) {
    val ks = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
    // 존재하지 않으면 no-op
    ks.deleteEntry(alias)
  }

  private fun deleteAllKeys() {
    val ks = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
    val aliases = ks.aliases()
    while (aliases.hasMoreElements()) {
      val alias = aliases.nextElement()
      try {
        ks.deleteEntry(alias)
      } catch (e: Exception) {
        // no-op: continue deleting others
      }
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}