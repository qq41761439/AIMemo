package com.aimemo.app.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.aimemo.app.data.AccountSnapshot
import com.aimemo.app.data.ApiException
import com.aimemo.app.data.AuthExpiredException
import com.aimemo.app.data.AuthRepository
import com.aimemo.app.data.ClientConfigRepository
import com.aimemo.app.data.SummaryRepository
import com.aimemo.app.data.TaskRepository
import com.aimemo.app.domain.ClientConfig
import com.aimemo.app.domain.PeriodType
import com.aimemo.app.domain.Quota
import com.aimemo.app.domain.SummaryDraft
import com.aimemo.app.domain.SummaryRecord
import com.aimemo.app.domain.TaskRecord
import com.aimemo.app.domain.UserAccount
import com.aimemo.app.domain.cleanTags
import com.aimemo.app.domain.defaultTemplate
import com.aimemo.app.domain.nowInstant
import com.aimemo.app.domain.periodRange
import com.aimemo.app.domain.sortTasks
import com.aimemo.app.domain.tagsFromTasks
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.time.Instant

data class AIMemoUiState(
    val isBooting: Boolean = true,
    val onboardingCompleted: Boolean = false,
    val isLoadingTasks: Boolean = false,
    val isSavingTask: Boolean = false,
    val isDeletingTask: Boolean = false,
    val isGeneratingSummary: Boolean = false,
    val isLoadingHistory: Boolean = false,
    val user: UserAccount? = null,
    val quota: Quota? = null,
    val clientConfig: ClientConfig? = null,
    val tasks: List<TaskRecord> = emptyList(),
    val remoteTags: List<String> = emptyList(),
    val selectedTag: String? = null,
    val expandedTaskId: String? = null,
    val summaries: List<SummaryRecord> = emptyList(),
    val selectedPeriod: PeriodType = PeriodType.Weekly,
    val selectedHistoryPeriod: PeriodType = PeriodType.Weekly,
    val selectedSummaryTags: Set<String> = emptySet(),
    val templateExpanded: Boolean = false,
    val templateText: String = defaultTemplate(PeriodType.Weekly),
    val latestSummary: String? = null,
    val authEmail: String = "",
    val authCode: String = "",
    val loginCodeSent: Boolean = false,
    val isSendingCode: Boolean = false,
    val isLoggingIn: Boolean = false,
    val lastStatus: String? = null,
    val errorMessage: String? = null,
) {
    val isLoggedIn: Boolean get() = user != null
    val availableTags: List<String> get() = (remoteTags + tagsFromTasks(tasks)).distinct()
    val filteredTasks: List<TaskRecord>
        get() = sortTasks(tasks).filter { selectedTag == null || selectedTag in it.tags }
    val summaryTasks: List<TaskRecord>
        get() = if (selectedSummaryTags.isEmpty()) sortTasks(tasks) else sortTasks(tasks).filter { task ->
            task.tags.any { it in selectedSummaryTags }
        }
}

class AIMemoViewModel(
    private val authRepository: AuthRepository,
    private val taskRepository: TaskRepository,
    private val summaryRepository: SummaryRepository,
    private val clientConfigRepository: ClientConfigRepository,
) : ViewModel() {
    private val _uiState = MutableStateFlow(AIMemoUiState())
    val uiState: StateFlow<AIMemoUiState> = _uiState

    init {
        bootstrap()
    }

    fun bootstrap() = viewModelScope.launch {
        _uiState.update { it.copy(isBooting = false) }
        runCatching { clientConfigRepository.getConfig() }
            .onSuccess { config -> _uiState.update { it.copy(clientConfig = config) } }
        runCatching { authRepository.currentAccount() }
            .onSuccess { snapshot ->
                if (snapshot != null) {
                    applyAccount(snapshot)
                    refreshAll()
                }
            }
            .onFailure { handleFailure(it) }
    }

    fun completeOnboarding() = _uiState.update { it.copy(onboardingCompleted = true) }

    fun updateAuthEmail(value: String) = _uiState.update { it.copy(authEmail = value) }

    fun updateAuthCode(value: String) = _uiState.update { it.copy(authCode = value) }

    fun sendLoginCode() = viewModelScope.launch {
        val email = uiState.value.authEmail.trim()
        if (email.isEmpty()) {
            _uiState.update { it.copy(errorMessage = "请输入邮箱地址。") }
            return@launch
        }
        _uiState.update { it.copy(isSendingCode = true, errorMessage = null) }
        runCatching { authRepository.startEmailLogin(email) }
            .onSuccess {
                _uiState.update {
                    it.copy(
                        isSendingCode = false,
                        loginCodeSent = true,
                        lastStatus = "验证码已发送。",
                    )
                }
            }
            .onFailure { error ->
                _uiState.update { it.copy(isSendingCode = false) }
                handleFailure(error)
            }
    }

    fun verifyLogin() = viewModelScope.launch {
        val state = uiState.value
        val email = state.authEmail.trim()
        val code = state.authCode.trim()
        if (email.isEmpty() || code.isEmpty()) {
            _uiState.update { it.copy(errorMessage = "请输入邮箱和验证码。") }
            return@launch
        }
        _uiState.update { it.copy(isLoggingIn = true, errorMessage = null) }
        runCatching {
            authRepository.verifyEmailLogin(email, code)
            authRepository.currentAccount()
        }.onSuccess { snapshot ->
            if (snapshot != null) applyAccount(snapshot)
            _uiState.update {
                it.copy(
                    isLoggingIn = false,
                    loginCodeSent = false,
                    authCode = "",
                    lastStatus = "登录成功。",
                )
            }
            refreshAll()
        }.onFailure { error ->
            _uiState.update { it.copy(isLoggingIn = false) }
            handleFailure(error)
        }
    }

    fun logout() = viewModelScope.launch {
        val onboardingCompleted = uiState.value.onboardingCompleted
        authRepository.logout()
        _uiState.update {
            AIMemoUiState(
                clientConfig = it.clientConfig,
                isBooting = false,
                onboardingCompleted = onboardingCompleted,
                lastStatus = "已退出登录。",
            )
        }
    }

    fun refreshAll() {
        refreshTasks()
        refreshHistory()
        refreshMe()
    }

    fun refreshTasks() = viewModelScope.launch {
        if (!uiState.value.isLoggedIn) return@launch
        _uiState.update { it.copy(isLoadingTasks = true, errorMessage = null) }
        runCatching {
            val tasks = taskRepository.listTasks()
            val tags = taskRepository.listTags()
            tasks to tags
        }.onSuccess { (tasks, tags) ->
            _uiState.update { it.copy(tasks = tasks, remoteTags = tags, isLoadingTasks = false) }
        }.onFailure { error ->
            _uiState.update { it.copy(isLoadingTasks = false) }
            handleFailure(error)
        }
    }

    fun addQuickTask(body: String) = viewModelScope.launch {
        val text = body.trim()
        if (text.isEmpty()) return@launch
        _uiState.update { it.copy(isSavingTask = true, errorMessage = null) }
        runCatching { taskRepository.addQuickTask(text) }
            .onSuccess { task ->
                _uiState.update {
                    it.copy(
                        tasks = it.tasks + task,
                        isSavingTask = false,
                        lastStatus = "任务已添加。",
                    )
                }
                refreshTasks()
            }
            .onFailure { error ->
                _uiState.update { it.copy(isSavingTask = false) }
                handleFailure(error)
            }
    }

    fun toggleTaskExpanded(taskId: String) = _uiState.update {
        it.copy(expandedTaskId = if (it.expandedTaskId == taskId) null else taskId)
    }

    fun selectTag(tag: String?) = _uiState.update { it.copy(selectedTag = tag) }

    fun toggleTaskCompleted(task: TaskRecord) = viewModelScope.launch {
        runCatching { taskRepository.setCompleted(task, !task.isCompleted) }
            .onSuccess { updated -> replaceTask(updated, if (updated.isCompleted) "任务已完成。" else "已取消完成。") }
            .onFailure { handleFailure(it) }
    }

    fun saveTask(task: TaskRecord, body: String, tagsText: String, createdAt: Instant, completedAt: Instant?) =
        viewModelScope.launch {
            if (body.trim().isEmpty()) {
                _uiState.update { it.copy(errorMessage = "正文不能为空。") }
                return@launch
            }
            if (completedAt != null && completedAt < createdAt) {
                _uiState.update { it.copy(errorMessage = "完成时间不能早于开始时间。") }
                return@launch
            }
            _uiState.update { it.copy(isSavingTask = true, errorMessage = null) }
            runCatching {
                taskRepository.saveTask(task, body.trim(), cleanTags(tagsText), createdAt, completedAt)
            }.onSuccess { updated ->
                replaceTask(updated, "任务已保存。")
                _uiState.update { it.copy(isSavingTask = false) }
            }.onFailure { error ->
                _uiState.update { it.copy(isSavingTask = false) }
                handleFailure(error)
            }
        }

    fun deleteTask(task: TaskRecord) = viewModelScope.launch {
        _uiState.update { it.copy(isDeletingTask = true, errorMessage = null) }
        runCatching { taskRepository.deleteTask(task) }
            .onSuccess {
                _uiState.update { state ->
                    state.copy(
                        tasks = state.tasks.filterNot { it.id == task.id },
                        isDeletingTask = false,
                        lastStatus = "任务已删除。",
                    )
                }
                refreshTasks()
            }
            .onFailure { error ->
                _uiState.update { it.copy(isDeletingTask = false) }
                handleFailure(error)
            }
    }

    fun selectPeriod(periodType: PeriodType) = _uiState.update {
        it.copy(
            selectedPeriod = periodType,
            templateText = defaultTemplate(periodType),
        )
    }

    fun toggleSummaryTag(tag: String) = _uiState.update { state ->
        val tags = state.selectedSummaryTags.toMutableSet()
        if (!tags.add(tag)) tags.remove(tag)
        state.copy(selectedSummaryTags = tags)
    }

    fun selectHistoryPeriod(periodType: PeriodType) = _uiState.update {
        it.copy(selectedHistoryPeriod = periodType)
    }

    fun setTemplateExpanded(expanded: Boolean) = _uiState.update { it.copy(templateExpanded = expanded) }

    fun updateTemplate(value: String) = _uiState.update { it.copy(templateText = value) }

    fun resetTemplate() = _uiState.update { it.copy(templateText = defaultTemplate(it.selectedPeriod)) }

    fun generateSummary(refinement: String? = null) = viewModelScope.launch {
        val state = uiState.value
        if (!state.isLoggedIn) {
            _uiState.update { it.copy(errorMessage = "请先登录 AIMemo。") }
            return@launch
        }
        if (state.clientConfig?.hostedModelAvailable == false) {
            _uiState.update { it.copy(errorMessage = "官方托管模型暂不可用。") }
            return@launch
        }
        val range = periodRange(state.selectedPeriod)
        val draft = SummaryDraft(
            periodType = state.selectedPeriod,
            periodLabel = range.label,
            periodStart = range.start,
            periodEnd = range.end,
            tags = state.selectedSummaryTags.toList(),
            template = buildString {
                append(state.templateText.ifBlank { defaultTemplate(state.selectedPeriod) })
                val instruction = refinement?.trim().orEmpty()
                if (instruction.isNotEmpty()) {
                    append("\n\n请根据这条修改意见重新生成：")
                    append(instruction)
                }
            },
        )
        _uiState.update {
            it.copy(
                isGeneratingSummary = true,
                latestSummary = if (refinement == null) null else it.latestSummary,
                errorMessage = null,
            )
        }
        runCatching { summaryRepository.generate(draft, state.summaryTasks) }
            .onSuccess { generated ->
                _uiState.update {
                    it.copy(
                        latestSummary = generated.output,
                        quota = generated.quota,
                        isGeneratingSummary = false,
                        lastStatus = "总结已生成。",
                    )
                }
                refreshHistory()
            }
            .onFailure { error ->
                _uiState.update { it.copy(isGeneratingSummary = false) }
                handleFailure(error)
            }
    }

    fun refreshHistory() = viewModelScope.launch {
        if (!uiState.value.isLoggedIn) return@launch
        _uiState.update { it.copy(isLoadingHistory = true) }
        runCatching { summaryRepository.listSummaries() }
            .onSuccess { records -> _uiState.update { it.copy(summaries = records, isLoadingHistory = false) } }
            .onFailure { error ->
                _uiState.update { it.copy(isLoadingHistory = false) }
                handleFailure(error)
            }
    }

    fun clearTransientMessages() = _uiState.update { it.copy(errorMessage = null, lastStatus = null) }

    fun showComingSoon(feature: String) = _uiState.update {
        it.copy(lastStatus = "$feature 暂未开放。")
    }

    private fun refreshMe() = viewModelScope.launch {
        runCatching { authRepository.currentAccount() }
            .onSuccess { it?.let(::applyAccount) }
            .onFailure { handleFailure(it) }
    }

    private fun applyAccount(snapshot: AccountSnapshot) = _uiState.update {
        it.copy(user = snapshot.user, quota = snapshot.quota, clientConfig = snapshot.config)
    }

    private fun replaceTask(task: TaskRecord, status: String) = _uiState.update { state ->
        val replaced = state.tasks.filterNot { it.id == task.id } + task
        state.copy(tasks = replaced, lastStatus = status)
    }

    private fun handleFailure(error: Throwable) {
        if (error is AuthExpiredException) {
            _uiState.update {
                it.copy(
                    user = null,
                    quota = null,
                    tasks = emptyList(),
                    summaries = emptyList(),
                    errorMessage = error.message,
                )
            }
            return
        }
        val message = when (error) {
            is ApiException -> error.message
            else -> error.message?.takeIf { it.isNotBlank() } ?: "操作失败，请稍后重试。"
        }
        _uiState.update { it.copy(errorMessage = message) }
    }
}
