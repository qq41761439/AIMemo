package com.aimemo.app.data

import com.aimemo.app.domain.ClientConfig
import com.aimemo.app.domain.PeriodType
import com.aimemo.app.domain.Quota
import com.aimemo.app.domain.SessionTokens
import com.aimemo.app.domain.SummaryDraft
import com.aimemo.app.domain.SummaryRecord
import com.aimemo.app.domain.TaskRecord
import com.aimemo.app.domain.UserAccount
import com.aimemo.app.domain.newAndroidClientId
import com.aimemo.app.domain.nowInstant
import com.aimemo.app.domain.renderPrompt
import com.aimemo.app.domain.taskTextForSummary
import java.time.Instant

class AuthRepository(
    private val api: ApiClient,
    private val sessionStore: SessionStore,
) {
    suspend fun startEmailLogin(email: String) = api.startEmailLogin(email)

    suspend fun verifyEmailLogin(email: String, code: String): UserAccount {
        val response = api.verifyEmailLogin(email, code)
        sessionStore.saveTokens(SessionTokens(response.accessToken, response.refreshToken))
        return response.user?.toDomain() ?: api.me().user.toDomain()
    }

    suspend fun currentAccount(): AccountSnapshot? =
        if (sessionStore.readTokens() == null) null else api.me().let {
            AccountSnapshot(it.user.toDomain(), it.quota.toDomain(), it.config.toDomain())
        }

    suspend fun logout() = sessionStore.clearTokens()
}

data class AccountSnapshot(
    val user: UserAccount,
    val quota: Quota,
    val config: ClientConfig,
)

class ClientConfigRepository(private val api: ApiClient) {
    suspend fun getConfig(): ClientConfig = api.clientConfig().toDomain()
}

class TaskRepository(private val api: ApiClient) {
    suspend fun listTasks(): List<TaskRecord> = api.tasks().map { it.toDomain() }

    suspend fun listTags(): List<String> = api.tags()

    suspend fun addQuickTask(body: String): TaskRecord {
        val now = nowInstant()
        return api.createTask(
            TaskInputDto(
                body = body,
                tags = emptyList(),
                isCompleted = false,
                createdAt = now.toString(),
                clientId = newAndroidClientId(),
            )
        ).toDomain()
    }

    suspend fun saveTask(
        task: TaskRecord,
        body: String,
        tags: List<String>,
        createdAt: Instant,
        completedAt: Instant?,
    ): TaskRecord = api.updateTask(
        task.id,
        TaskInputDto(
            body = body,
            tags = tags,
            isCompleted = completedAt != null || task.isCompleted,
            createdAt = createdAt.toString(),
            completedAt = completedAt?.toString(),
        )
    ).toDomain()

    suspend fun setCompleted(task: TaskRecord, completed: Boolean): TaskRecord =
        api.updateTask(
            task.id,
            TaskInputDto(
                isCompleted = completed,
                completedAt = if (completed) nowInstant().toString() else null,
            )
        ).toDomain()

    suspend fun deleteTask(task: TaskRecord): TaskRecord = api.deleteTask(task.id).toDomain()
}

class SummaryRepository(private val api: ApiClient) {
    suspend fun listSummaries(): List<SummaryRecord> = api.summaries().map { it.toDomain() }

    suspend fun generate(draft: SummaryDraft, tasks: List<TaskRecord>): GeneratedSummary {
        val tasksText = taskTextForSummary(tasks).ifBlank { "本周期没有任务记录。" }
        val prompt = renderPrompt(draft, tasksText)
        val response = api.generateSummary(
            GenerateSummaryRequestDto(
                periodType = draft.periodType.apiName,
                periodLabel = draft.periodLabel,
                periodStart = draft.periodStart.toString(),
                periodEnd = draft.periodEnd.toString(),
                tags = draft.tags,
                tasks = tasksText,
                prompt = prompt,
            )
        )
        return GeneratedSummary(response.summary.trim(), response.quota.toDomain())
    }
}

data class GeneratedSummary(
    val output: String,
    val quota: Quota,
)
