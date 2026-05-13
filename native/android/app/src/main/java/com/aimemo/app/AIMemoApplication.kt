package com.aimemo.app

import android.app.Application
import com.aimemo.app.data.ApiClient
import com.aimemo.app.data.AuthRepository
import com.aimemo.app.data.ClientConfigRepository
import com.aimemo.app.data.EncryptedSessionStore
import com.aimemo.app.data.SummaryRepository
import com.aimemo.app.data.TaskRepository

class AIMemoApplication : Application() {
    lateinit var container: AppContainer
        private set

    override fun onCreate() {
        super.onCreate()
        val sessionStore = EncryptedSessionStore(this)
        val api = ApiClient(BuildConfig.AIMEMO_BACKEND_BASE_URL, sessionStore)
        container = AppContainer(
            authRepository = AuthRepository(api, sessionStore),
            taskRepository = TaskRepository(api),
            summaryRepository = SummaryRepository(api),
            clientConfigRepository = ClientConfigRepository(api),
        )
    }
}

data class AppContainer(
    val authRepository: AuthRepository,
    val taskRepository: TaskRepository,
    val summaryRepository: SummaryRepository,
    val clientConfigRepository: ClientConfigRepository,
)
