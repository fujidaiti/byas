package dev.norelease.paperdoll

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.first
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Native-side backing store for the app's secure key-value storage.
 *
 * Values are encrypted with an Android Keystore key and stored as Base64 in a Preferences
 * DataStore. Key names are stored as-is.
 */
object SecureStorage {
    private const val AUTH_TOKEN_KEY = "auth_token"

    private val Context.secureKvStore: DataStore<Preferences> by preferencesDataStore(name = "secure_kv_store")

    suspend fun readAuthToken(context: Context): String? =
        context.secureKvStore.data.first()[stringPreferencesKey(AUTH_TOKEN_KEY)]?.let { encrypted ->
            runCatching { Crypto.decrypt(encrypted) }.getOrNull()
        }

    /** Writes [value], or removes the token when it is null. */
    suspend fun writeAuthToken(context: Context, value: String?) {
        context.secureKvStore.edit { prefs ->
            val prefKey = stringPreferencesKey(AUTH_TOKEN_KEY)
            if (value == null) prefs.remove(prefKey) else prefs[prefKey] = Crypto.encrypt(value)
        }
    }
}

private object Crypto {
    private const val KEY_ALIAS = "auth_token_key"
    private const val ANDROID_KEYSTORE = "AndroidKeyStore"
    private const val TRANSFORMATION = "AES/GCM/NoPadding"
    private const val IV_SIZE = 12
    private const val TAG_SIZE_BITS = 128

    /** The key material never leaves the Keystore; only handles to it are returned. */
    private fun getOrCreateKey(): SecretKey {
        val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
        (keyStore.getKey(KEY_ALIAS, null) as? SecretKey)?.let { return it }

        val spec = KeyGenParameterSpec.Builder(
            KEY_ALIAS,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
        ).setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE).build()

        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEYSTORE)
            .apply { init(spec) }.generateKey()
    }

    /** Returns the IV prefixed to the ciphertext, Base64-encoded. */
    fun encrypt(plain: String): String {
        // A fresh Cipher every time: reusing one would repeat the IV, which breaks GCM.
        val cipher = Cipher.getInstance(TRANSFORMATION).apply {
            init(Cipher.ENCRYPT_MODE, getOrCreateKey())
        }
        val cipherText = cipher.doFinal(plain.toByteArray(Charsets.UTF_8))
        return Base64.encodeToString(cipher.iv + cipherText, Base64.NO_WRAP)
    }

    fun decrypt(encoded: String): String {
        val data = Base64.decode(encoded, Base64.NO_WRAP)
        val iv = data.copyOfRange(0, IV_SIZE)
        val cipherText = data.copyOfRange(IV_SIZE, data.size)
        val cipher = Cipher.getInstance(TRANSFORMATION).apply {
            init(Cipher.DECRYPT_MODE, getOrCreateKey(), GCMParameterSpec(TAG_SIZE_BITS, iv))
        }
        return String(cipher.doFinal(cipherText), Charsets.UTF_8)
    }
}
