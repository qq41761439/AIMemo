package com.aimemo.app.data

import android.content.Context
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import com.aimemo.app.domain.SessionTokens
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

interface SessionStore {
    suspend fun readTokens(): SessionTokens?
    suspend fun saveTokens(tokens: SessionTokens)
    suspend fun clearTokens()
}

class EncryptedSessionStore(context: Context) : SessionStore {
    private val prefs by lazy {
        val masterKey = MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()
        EncryptedSharedPreferences.create(
            context,
            "aimemo_secure_session",
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
        )
    }

    override suspend fun readTokens(): SessionTokens? = withContext(Dispatchers.IO) {
        val access = prefs.getString(KEY_ACCESS, null)?.takeIf { it.isNotBlank() }
        val refresh = prefs.getString(KEY_REFRESH, null)?.takeIf { it.isNotBlank() }
        if (access == null || refresh == null) null else SessionTokens(access, refresh)
    }

    override suspend fun saveTokens(tokens: SessionTokens) = withContext(Dispatchers.IO) {
        prefs.edit()
            .putString(KEY_ACCESS, tokens.accessToken)
            .putString(KEY_REFRESH, tokens.refreshToken)
            .apply()
    }

    override suspend fun clearTokens() = withContext(Dispatchers.IO) {
        prefs.edit().clear().apply()
    }

    private companion object {
        const val KEY_ACCESS = "access_token"
        const val KEY_REFRESH = "refresh_token"
    }
}
