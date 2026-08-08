package dev.norelease.paperdoll

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey

/**
 * Native-side backing store for the app's secure key-value storage (currently just the auth
 * token). Reachable both from the Flutter engine (via a MethodChannel in [MainActivity]) and
 * directly from [SaveWebClipActivity], which runs outside the Flutter engine and otherwise has
 * no way to read what Dart's `flutter_secure_storage`-backed [SecureStorage] wrote.
 */
object TokenStore {
    private const val PREFS_FILE_NAME = "secure_kv_store"

    private fun prefs(context: Context): SharedPreferences =
        EncryptedSharedPreferences.create(
            context,
            PREFS_FILE_NAME,
            MasterKey.Builder(context).setKeyScheme(MasterKey.KeyScheme.AES256_GCM).build(),
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
        )

    fun read(context: Context, key: String): String? = prefs(context).getString(key, null)

    fun write(context: Context, key: String, value: String?) {
        prefs(context).edit().apply {
            if (value == null) remove(key) else putString(key, value)
        }.apply()
    }
}
