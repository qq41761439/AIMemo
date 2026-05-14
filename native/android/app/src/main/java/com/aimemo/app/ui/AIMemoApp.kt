package com.aimemo.app.ui

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.material3.Tab
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.PrimaryTabRow
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.automirrored.rounded.Send
import androidx.compose.material.icons.rounded.AccountCircle
import androidx.compose.material.icons.rounded.CheckCircle
import androidx.compose.material.icons.rounded.Edit
import androidx.compose.material.icons.rounded.KeyboardArrowDown
import androidx.compose.material.icons.rounded.KeyboardArrowUp
import androidx.compose.material.icons.rounded.Refresh
import com.aimemo.app.R
import com.aimemo.app.domain.PeriodType
import com.aimemo.app.domain.TaskRecord
import com.aimemo.app.domain.defaultTemplate
import com.aimemo.app.domain.periodRange
import com.aimemo.app.domain.sectionTasks
import kotlinx.coroutines.launch
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter

@Composable
fun AIMemoApp(viewModel: AIMemoViewModel) {
    val state by viewModel.uiState.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }

    LaunchedEffect(state.errorMessage, state.lastStatus) {
        val message = state.errorMessage ?: state.lastStatus
        if (message != null) {
            snackbarHostState.showSnackbar(message)
            viewModel.clearTransientMessages()
        }
    }

    if (state.isBooting) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            CircularProgressIndicator()
        }
        return
    }

    var showMe by rememberSaveable { mutableStateOf(false) }

    if (!state.isLoggedIn) {
        AccountScreen(
            state = state,
            onBack = {},
            showBack = false,
            onEmailChange = viewModel::updateAuthEmail,
            onCodeChange = viewModel::updateAuthCode,
            onSendCode = viewModel::sendLoginCode,
            onLogin = viewModel::verifyLogin,
            onLogout = viewModel::logout,
            snackbarHostState = snackbarHostState,
        )
    } else if (showMe) {
        AccountScreen(
            state = state,
            onBack = { showMe = false },
            showBack = true,
            onEmailChange = viewModel::updateAuthEmail,
            onCodeChange = viewModel::updateAuthCode,
            onSendCode = viewModel::sendLoginCode,
            onLogin = viewModel::verifyLogin,
            onLogout = viewModel::logout,
            snackbarHostState = snackbarHostState,
        )
    } else {
        MainScreen(
            state = state,
            snackbarHostState = snackbarHostState,
            onSelectMainTab = viewModel::selectMainTab,
            onSelectSummaryTab = viewModel::selectSummaryTab,
            onOpenMe = { showMe = true },
            onRefreshTasks = viewModel::refreshTasks,
            onAddTask = viewModel::addQuickTask,
            onToggleExpanded = viewModel::toggleTaskExpanded,
            onSelectTag = viewModel::selectTag,
            onToggleCompleted = viewModel::toggleTaskCompleted,
            onSaveTask = viewModel::saveTask,
            onDeleteTask = viewModel::deleteTask,
            onSelectPeriod = viewModel::selectPeriod,
            onToggleSummaryTag = viewModel::toggleSummaryTag,
            onTemplateExpanded = viewModel::setTemplateExpanded,
            onTemplateChange = viewModel::updateTemplate,
            onTemplateReset = viewModel::resetTemplate,
            onGenerateSummary = viewModel::generateSummary,
            onRefreshHistory = viewModel::refreshHistory,
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun MainScreen(
    state: AIMemoUiState,
    snackbarHostState: SnackbarHostState,
    onSelectMainTab: (MainTab) -> Unit,
    onSelectSummaryTab: (SummaryTab) -> Unit,
    onOpenMe: () -> Unit,
    onRefreshTasks: () -> Unit,
    onAddTask: (String) -> Unit,
    onToggleExpanded: (String) -> Unit,
    onSelectTag: (String?) -> Unit,
    onToggleCompleted: (TaskRecord) -> Unit,
    onSaveTask: (TaskRecord, String, String, Instant, Instant?) -> Unit,
    onDeleteTask: (TaskRecord) -> Unit,
    onSelectPeriod: (PeriodType) -> Unit,
    onToggleSummaryTag: (String) -> Unit,
    onTemplateExpanded: (Boolean) -> Unit,
    onTemplateChange: (String) -> Unit,
    onTemplateReset: () -> Unit,
    onGenerateSummary: () -> Unit,
    onRefreshHistory: () -> Unit,
) {
    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            Surface(color = MaterialTheme.colorScheme.background) {
                Column {
                    TopAppBar(
                        title = {
                            Text(
                                "AIMemo",
                                style = MaterialTheme.typography.titleLarge,
                                fontWeight = FontWeight.SemiBold,
                            )
                        },
                        actions = {
                            IconButton(onClick = onOpenMe, modifier = Modifier.semantics { contentDescription = "我的" }) {
                                Icon(Icons.Rounded.AccountCircle, contentDescription = null)
                            }
                        },
                        colors = TopAppBarDefaults.topAppBarColors(
                            containerColor = MaterialTheme.colorScheme.background,
                            titleContentColor = MaterialTheme.colorScheme.onBackground,
                            actionIconContentColor = MaterialTheme.colorScheme.onBackground,
                        ),
                    )
                    MainTabSwitch(
                        selected = state.mainTab,
                        onSelect = onSelectMainTab,
                        modifier = Modifier.padding(start = 16.dp, end = 16.dp, bottom = 10.dp),
                    )
                }
            }
        },
        bottomBar = {
            if (state.mainTab == MainTab.Tasks && state.isLoggedIn) {
                QuickInputBar(
                    enabled = state.isLoggedIn && !state.isSavingTask,
                    loading = state.isSavingTask,
                    onSend = onAddTask,
                )
            }
        },
    ) { padding ->
        when (state.mainTab) {
            MainTab.Tasks -> TaskScreen(
                state = state,
                modifier = Modifier.padding(padding),
                onRefresh = onRefreshTasks,
                onToggleExpanded = onToggleExpanded,
                onSelectTag = onSelectTag,
                onToggleCompleted = onToggleCompleted,
                onSaveTask = onSaveTask,
                onDeleteTask = onDeleteTask,
            )
            MainTab.Summary -> SummaryScreen(
                state = state,
                modifier = Modifier.padding(padding),
                snackbarHostState = snackbarHostState,
                onSelectSummaryTab = onSelectSummaryTab,
                onSelectPeriod = onSelectPeriod,
                onToggleSummaryTag = onToggleSummaryTag,
                onTemplateExpanded = onTemplateExpanded,
                onTemplateChange = onTemplateChange,
                onTemplateReset = onTemplateReset,
                onGenerateSummary = onGenerateSummary,
                onRefreshHistory = onRefreshHistory,
            )
        }
    }
}

@Composable
private fun MainTabSwitch(
    selected: MainTab,
    onSelect: (MainTab) -> Unit,
    modifier: Modifier = Modifier,
) {
    SingleChoiceSegmentedButtonRow(modifier = modifier.fillMaxWidth()) {
        MainTab.entries.forEachIndexed { index, tab ->
            SegmentedButton(
                selected = selected == tab,
                onClick = { onSelect(tab) },
                shape = SegmentedButtonDefaults.itemShape(index, MainTab.entries.size),
                icon = {},
                colors = SegmentedButtonDefaults.colors(
                    activeContainerColor = MaterialTheme.colorScheme.primaryContainer,
                    activeContentColor = MaterialTheme.colorScheme.onPrimaryContainer,
                    inactiveContainerColor = MaterialTheme.colorScheme.surface,
                    inactiveContentColor = MaterialTheme.colorScheme.onSurfaceVariant,
                    activeBorderColor = MaterialTheme.colorScheme.primary,
                    inactiveBorderColor = MaterialTheme.colorScheme.outline,
                ),
            ) {
                Text(
                    if (tab == MainTab.Tasks) "任务" else "总结",
                    fontWeight = if (selected == tab) FontWeight.SemiBold else FontWeight.Medium,
                )
            }
        }
    }
}

@Composable
private fun PageHeader(
    title: String,
    subtitle: String,
    actionLabel: String,
    onAction: () -> Unit,
    enabled: Boolean = true,
) {
    Row(
        Modifier
            .fillMaxWidth()
            .padding(start = 16.dp, end = 12.dp, top = 8.dp, bottom = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(Modifier.weight(1f)) {
            Text(title, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.SemiBold)
            Text(subtitle, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        IconButton(onClick = onAction, enabled = enabled, modifier = Modifier.semantics { contentDescription = actionLabel }) {
            Icon(Icons.Rounded.Refresh, contentDescription = null)
        }
    }
}

@Composable
private fun CompactFilterChip(
    label: String,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    FilterChip(
        selected = selected,
        onClick = onClick,
        label = { Text(label, maxLines = 1, overflow = TextOverflow.Ellipsis) },
        modifier = modifier.height(36.dp),
        shape = RoundedCornerShape(999.dp),
        colors = FilterChipDefaults.filterChipColors(
            selectedContainerColor = MaterialTheme.colorScheme.primaryContainer,
            selectedLabelColor = MaterialTheme.colorScheme.onPrimaryContainer,
            containerColor = MaterialTheme.colorScheme.surface,
            labelColor = MaterialTheme.colorScheme.onSurfaceVariant,
        ),
        border = FilterChipDefaults.filterChipBorder(
            enabled = true,
            selected = selected,
            borderColor = MaterialTheme.colorScheme.outline,
            selectedBorderColor = MaterialTheme.colorScheme.primary,
            borderWidth = 1.dp,
            selectedBorderWidth = 1.dp,
        ),
    )
}

@Composable
private fun TagPill(label: String) {
    Surface(
        shape = RoundedCornerShape(999.dp),
        color = MaterialTheme.colorScheme.surfaceVariant,
        contentColor = MaterialTheme.colorScheme.onSurfaceVariant,
    ) {
        Text(
            label,
            modifier = Modifier.padding(horizontal = 9.dp, vertical = 4.dp),
            style = MaterialTheme.typography.labelMedium,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

@Composable
private fun CompletionIcon(completed: Boolean, modifier: Modifier = Modifier) {
    if (completed) {
        Icon(
            Icons.Rounded.CheckCircle,
            contentDescription = null,
            modifier = modifier,
            tint = MaterialTheme.colorScheme.primary,
        )
    } else {
        Icon(
            painterResource(R.drawable.ic_radio_button_unchecked_round),
            contentDescription = null,
            modifier = modifier,
            tint = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

private val CompactDateFormatter: DateTimeFormatter =
    DateTimeFormatter.ofPattern("MM-dd HH:mm").withZone(ZoneId.systemDefault())

private fun formatInstant(value: Instant?): String =
    value?.let { CompactDateFormatter.format(it) } ?: "未完成"

private fun taskMeta(task: TaskRecord): String =
    if (task.isCompleted) "已完成 ${formatInstant(task.completedAt)}" else "开始 ${formatInstant(task.createdAt)}"

private fun taskSubtitle(state: AIMemoUiState): String {
    val sections = sectionTasks(state.filteredTasks)
    val total = sections.active.size + sections.upcoming.size + sections.completed.size
    val open = sections.active.size + sections.upcoming.size
    val upcomingText = if (sections.upcoming.isNotEmpty()) " · ${sections.upcoming.size} 个即将开始" else ""
    return "$open 个待完成$upcomingText · $total 条任务"
}

@Composable
private fun EmptyGate(
    title: String,
    message: String,
    action: String,
    onAction: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(title, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.SemiBold)
        Spacer(Modifier.height(8.dp))
        Text(message, color = MaterialTheme.colorScheme.onSurfaceVariant, style = MaterialTheme.typography.bodyMedium)
        Spacer(Modifier.height(20.dp))
        Button(onClick = onAction, shape = RoundedCornerShape(6.dp)) { Text(action) }
    }
}

@Composable
private fun QuickInputBar(
    enabled: Boolean,
    loading: Boolean,
    onSend: (String) -> Unit,
) {
    var text by rememberSaveable { mutableStateOf("") }
    val focusManager = LocalFocusManager.current
    Surface(
        color = MaterialTheme.colorScheme.surface,
        shadowElevation = 8.dp,
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .navigationBarsPadding()
                .imePadding()
                .padding(horizontal = 12.dp, vertical = 10.dp),
            verticalAlignment = Alignment.Bottom,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            OutlinedTextField(
                value = text,
                onValueChange = { text = it.take(500) },
                modifier = Modifier.weight(1f),
                enabled = enabled,
                minLines = 1,
                maxLines = 4,
                placeholder = { Text("像发消息一样添加任务") },
                shape = RoundedCornerShape(18.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = MaterialTheme.colorScheme.primary,
                    unfocusedBorderColor = MaterialTheme.colorScheme.outline,
                    focusedContainerColor = MaterialTheme.colorScheme.background,
                    unfocusedContainerColor = MaterialTheme.colorScheme.background,
                ),
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Send),
            )
            IconButton(
                onClick = {
                    val value = text.trim()
                    if (value.isNotEmpty()) {
                        onSend(value)
                        text = ""
                        focusManager.clearFocus()
                    }
                },
                enabled = enabled && text.isNotBlank(),
                modifier = Modifier.size(48.dp),
                colors = IconButtonDefaults.filledIconButtonColors(
                    containerColor = MaterialTheme.colorScheme.primary,
                    contentColor = MaterialTheme.colorScheme.onPrimary,
                    disabledContainerColor = MaterialTheme.colorScheme.surfaceVariant,
                    disabledContentColor = MaterialTheme.colorScheme.onSurfaceVariant,
                ),
            ) {
                if (loading) {
                    CircularProgressIndicator(modifier = Modifier.size(20.dp), color = MaterialTheme.colorScheme.onPrimary)
                } else {
                    Icon(Icons.AutoMirrored.Rounded.Send, contentDescription = "发送")
                }
            }
        }
    }
}

@Composable
private fun TaskScreen(
    state: AIMemoUiState,
    modifier: Modifier,
    onRefresh: () -> Unit,
    onToggleExpanded: (String) -> Unit,
    onSelectTag: (String?) -> Unit,
    onToggleCompleted: (TaskRecord) -> Unit,
    onSaveTask: (TaskRecord, String, String, Instant, Instant?) -> Unit,
    onDeleteTask: (TaskRecord) -> Unit,
) {
    var showActive by rememberSaveable { mutableStateOf(true) }
    var showUpcoming by rememberSaveable { mutableStateOf(true) }
    val sections = remember(state.filteredTasks) { sectionTasks(state.filteredTasks) }
    Column(modifier.fillMaxSize()) {
        PageHeader(
            title = "任务",
            subtitle = taskSubtitle(state),
            actionLabel = "刷新任务",
            onAction = onRefresh,
            enabled = !state.isLoadingTasks,
        )
        if (state.availableTags.isNotEmpty() || state.selectedTag != null) {
            TagFilterRow(
                tags = state.availableTags,
                selected = state.selectedTag,
                onSelect = onSelectTag,
            )
        }
        if (state.isLoadingTasks && state.tasks.isEmpty()) {
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { CircularProgressIndicator() }
        } else if (state.filteredTasks.isEmpty()) {
            EmptyListText("还没有任务，从底部输入框添加第一条。")
        } else {
            var editingTask by remember { mutableStateOf<TaskRecord?>(null) }
            var deletingTask by remember { mutableStateOf<TaskRecord?>(null) }
            LazyColumn(
                contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 8.dp, bottom = 104.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                taskSection(
                    title = "进行中",
                    tasks = sections.active,
                    expanded = showActive,
                    onToggle = { showActive = !showActive },
                    expandedTaskId = state.expandedTaskId,
                    onToggleExpanded = onToggleExpanded,
                    onToggleCompleted = onToggleCompleted,
                    onEdit = { editingTask = it },
                    onDelete = { deletingTask = it },
                )
                taskSection(
                    title = "即将开始",
                    tasks = sections.upcoming,
                    expanded = showUpcoming,
                    onToggle = { showUpcoming = !showUpcoming },
                    expandedTaskId = state.expandedTaskId,
                    onToggleExpanded = onToggleExpanded,
                    onToggleCompleted = onToggleCompleted,
                    onEdit = { editingTask = it },
                    onDelete = { deletingTask = it },
                )
                if (sections.completed.isNotEmpty()) {
                    item(key = "completed-header") {
                        Text(
                            "已完成 (${sections.completed.size})",
                            modifier = Modifier.padding(top = 8.dp, bottom = 2.dp),
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                    items(sections.completed, key = { "completed-${it.id}" }) { task ->
                        TaskCard(
                            task = task,
                            expanded = state.expandedTaskId == task.id,
                            onToggleExpanded = { onToggleExpanded(task.id) },
                            onToggleCompleted = { onToggleCompleted(task) },
                            onEdit = { editingTask = task },
                            onDelete = { deletingTask = task },
                        )
                    }
                }
            }
            editingTask?.let { task ->
                TaskEditSheet(
                    task = task,
                    saving = state.isSavingTask,
                    onDismiss = { editingTask = null },
                    onSave = { body, tags, createdAt, completedAt ->
                        onSaveTask(task, body, tags, createdAt, completedAt)
                        editingTask = null
                    },
                )
            }
            deletingTask?.let { task ->
                AlertDialog(
                    onDismissRequest = { deletingTask = null },
                    title = { Text("删除任务") },
                    text = { Text("删除后会从当前列表移除。") },
                    confirmButton = {
                        Button(
                            onClick = {
                                onDeleteTask(task)
                                deletingTask = null
                            },
                            colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error),
                            shape = RoundedCornerShape(6.dp),
                        ) {
                            Text("删除")
                        }
                    },
                    dismissButton = {
                        TextButton(onClick = { deletingTask = null }) { Text("取消") }
                    },
                )
            }
        }
    }
}

private fun androidx.compose.foundation.lazy.LazyListScope.taskSection(
    title: String,
    tasks: List<TaskRecord>,
    expanded: Boolean,
    onToggle: () -> Unit,
    expandedTaskId: String?,
    onToggleExpanded: (String) -> Unit,
    onToggleCompleted: (TaskRecord) -> Unit,
    onEdit: (TaskRecord) -> Unit,
    onDelete: (TaskRecord) -> Unit,
) {
    item(key = "$title-header") {
        TaskSectionHeader(
            title = title,
            count = tasks.size,
            expanded = expanded,
            onToggle = onToggle,
        )
    }
    if (expanded) {
        if (tasks.isEmpty()) {
            item(key = "$title-empty") {
                Text(
                    if (title == "进行中") "今天没有待处理任务。" else "还没有未来开始的任务。",
                    modifier = Modifier.padding(horizontal = 4.dp, vertical = 6.dp),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        } else {
            items(tasks, key = { "$title-${it.id}" }) { task ->
                TaskCard(
                    task = task,
                    expanded = expandedTaskId == task.id,
                    onToggleExpanded = { onToggleExpanded(task.id) },
                    onToggleCompleted = { onToggleCompleted(task) },
                    onEdit = { onEdit(task) },
                    onDelete = { onDelete(task) },
                )
            }
        }
    }
}

@Composable
private fun TaskSectionHeader(
    title: String,
    count: Int,
    expanded: Boolean,
    onToggle: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 8.dp, bottom = 2.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            "$title ($count)",
            modifier = Modifier.weight(1f),
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
        )
        IconButton(
            onClick = onToggle,
            modifier = Modifier.size(48.dp).semantics { contentDescription = if (expanded) "收起$title" else "展开$title" },
        ) {
            Icon(
                if (expanded) Icons.Rounded.KeyboardArrowUp else Icons.Rounded.KeyboardArrowDown,
                contentDescription = null,
            )
        }
    }
}

@Composable
private fun EmptyListText(text: String) {
    Box(Modifier.fillMaxSize().padding(24.dp), contentAlignment = Alignment.Center) {
        Text(text, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

@Composable
private fun TagFilterRow(tags: List<String>, selected: String?, onSelect: (String?) -> Unit) {
    LazyRow(
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 4.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        item {
            CompactFilterChip(selected = selected == null, onClick = { onSelect(null) }, label = "全部")
        }
        items(tags) { tag ->
            CompactFilterChip(selected = selected == tag, onClick = { onSelect(tag) }, label = tag)
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun TaskCard(
    task: TaskRecord,
    expanded: Boolean,
    onToggleExpanded: () -> Unit,
    onToggleCompleted: () -> Unit,
    onEdit: () -> Unit,
    onDelete: () -> Unit,
) {
    Card(
        modifier = Modifier.fillMaxWidth().clickable(onClick = onToggleExpanded),
        shape = RoundedCornerShape(8.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline),
    ) {
        Column(Modifier.padding(horizontal = 12.dp, vertical = 10.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(verticalAlignment = Alignment.Top, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                IconButton(
                    onClick = onToggleCompleted,
                    modifier = Modifier.size(48.dp).semantics { contentDescription = if (task.isCompleted) "取消完成" else "标记完成" },
                ) {
                    CompletionIcon(completed = task.isCompleted, modifier = Modifier.size(24.dp))
                }
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                    Text(
                        task.title,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = if (task.isCompleted) MaterialTheme.colorScheme.onSurfaceVariant else MaterialTheme.colorScheme.onSurface,
                        textDecoration = if (task.isCompleted) TextDecoration.LineThrough else TextDecoration.None,
                        maxLines = if (expanded) Int.MAX_VALUE else 2,
                        overflow = TextOverflow.Ellipsis,
                    )
                    Text(
                        taskMeta(task),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
                IconButton(onClick = onEdit, modifier = Modifier.size(40.dp).semantics { contentDescription = "编辑任务" }) {
                    Icon(Icons.Rounded.Edit, contentDescription = null)
                }
                IconButton(onClick = onDelete, modifier = Modifier.size(40.dp).semantics { contentDescription = "删除任务" }) {
                    Icon(
                        painterResource(R.drawable.ic_delete_outline_round),
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.error,
                    )
                }
            }
            if (task.tags.isNotEmpty()) {
                FlowRow(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    task.tags.forEach { tag -> TagPill(tag) }
                }
            }
            if (expanded) {
                HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant)
                Text(task.body, style = MaterialTheme.typography.bodyMedium)
                Text("开始：${formatInstant(task.createdAt)}", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Text("完成：${formatInstant(task.completedAt)}", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun TaskEditSheet(
    task: TaskRecord,
    saving: Boolean,
    onDismiss: () -> Unit,
    onSave: (String, String, Instant, Instant?) -> Unit,
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    var body by rememberSaveable(task.id) { mutableStateOf(task.body) }
    var tags by rememberSaveable(task.id) { mutableStateOf(task.tags.joinToString(", ")) }
    var createdAtText by rememberSaveable(task.id) { mutableStateOf(task.createdAt.toString()) }
    var completedAtText by rememberSaveable(task.id) { mutableStateOf(task.completedAt?.toString().orEmpty()) }
    var error by rememberSaveable(task.id) { mutableStateOf<String?>(null) }
    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState) {
        Column(
            Modifier
                .fillMaxWidth()
                .imePadding()
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text("编辑任务", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.SemiBold)
            OutlinedTextField(value = body, onValueChange = { body = it }, label = { Text("正文") }, minLines = 4, modifier = Modifier.fillMaxWidth())
            OutlinedTextField(value = tags, onValueChange = { tags = it }, label = { Text("标签，逗号分隔") }, modifier = Modifier.fillMaxWidth())
            OutlinedTextField(value = createdAtText, onValueChange = { createdAtText = it }, label = { Text("开始时间 ISO") }, modifier = Modifier.fillMaxWidth())
            OutlinedTextField(value = completedAtText, onValueChange = { completedAtText = it }, label = { Text("完成时间 ISO，可留空") }, modifier = Modifier.fillMaxWidth())
            error?.let { Text(it, color = MaterialTheme.colorScheme.error) }
            Button(
                onClick = {
                    val createdAt = runCatching { Instant.parse(createdAtText.trim()) }.getOrNull()
                    val completedAt = completedAtText.trim().takeIf { it.isNotEmpty() }?.let {
                        runCatching { Instant.parse(it) }.getOrNull()
                    }
                    error = when {
                        body.trim().isEmpty() -> "正文不能为空。"
                        createdAt == null -> "开始时间格式无效。"
                        completedAtText.isNotBlank() && completedAt == null -> "完成时间格式无效。"
                        completedAt != null && completedAt < createdAt -> "完成时间不能早于开始时间。"
                        else -> null
                    }
                    if (error == null) onSave(body, tags, createdAt!!, completedAt)
                },
                enabled = !saving,
                modifier = Modifier.fillMaxWidth().height(48.dp),
            ) {
                if (saving) CircularProgressIndicator(Modifier.size(18.dp)) else Text("保存")
            }
            Spacer(Modifier.height(12.dp))
        }
    }
}

@Composable
private fun SummaryScreen(
    state: AIMemoUiState,
    modifier: Modifier,
    snackbarHostState: SnackbarHostState,
    onSelectSummaryTab: (SummaryTab) -> Unit,
    onSelectPeriod: (PeriodType) -> Unit,
    onToggleSummaryTag: (String) -> Unit,
    onTemplateExpanded: (Boolean) -> Unit,
    onTemplateChange: (String) -> Unit,
    onTemplateReset: () -> Unit,
    onGenerateSummary: () -> Unit,
    onRefreshHistory: () -> Unit,
) {
    Column(modifier.fillMaxSize()) {
        PrimaryTabRow(
            selectedTabIndex = SummaryTab.entries.indexOf(state.summaryTab),
            containerColor = MaterialTheme.colorScheme.background,
            contentColor = MaterialTheme.colorScheme.primary,
        ) {
            SummaryTab.entries.forEach { tab ->
                Tab(
                    selected = state.summaryTab == tab,
                    onClick = { onSelectSummaryTab(tab) },
                    text = {
                        Text(
                            if (tab == SummaryTab.Generate) "生成总结" else "历史记录",
                            fontWeight = if (state.summaryTab == tab) FontWeight.SemiBold else FontWeight.Medium,
                        )
                    },
                )
            }
        }
        when (state.summaryTab) {
            SummaryTab.Generate -> GenerateSummaryScreen(
                state = state,
                snackbarHostState = snackbarHostState,
                onSelectPeriod = onSelectPeriod,
                onToggleSummaryTag = onToggleSummaryTag,
                onTemplateExpanded = onTemplateExpanded,
                onTemplateChange = onTemplateChange,
                onTemplateReset = onTemplateReset,
                onGenerateSummary = onGenerateSummary,
            )
            SummaryTab.History -> HistoryScreen(
                state = state,
                snackbarHostState = snackbarHostState,
                onRefresh = onRefreshHistory,
            )
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun GenerateSummaryScreen(
    state: AIMemoUiState,
    snackbarHostState: SnackbarHostState,
    onSelectPeriod: (PeriodType) -> Unit,
    onToggleSummaryTag: (String) -> Unit,
    onTemplateExpanded: (Boolean) -> Unit,
    onTemplateChange: (String) -> Unit,
    onTemplateReset: () -> Unit,
    onGenerateSummary: () -> Unit,
) {
    val clipboard = LocalClipboardManager.current
    val coroutineScope = rememberCoroutineScope()
    val range = periodRange(state.selectedPeriod)
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 14.dp, bottom = 24.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        item {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                LazyRow(
                    modifier = Modifier.weight(1f),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    items(PeriodType.entries) { type ->
                        CompactFilterChip(
                            selected = state.selectedPeriod == type,
                            onClick = { onSelectPeriod(type) },
                            label = type.title,
                        )
                    }
                }
                OutlinedButton(
                    onClick = {},
                    modifier = Modifier.height(40.dp),
                    shape = RoundedCornerShape(6.dp),
                    contentPadding = PaddingValues(horizontal = 12.dp),
                ) {
                    Icon(
                        painterResource(R.drawable.ic_calendar_month_round),
                        contentDescription = null,
                        modifier = Modifier.size(18.dp),
                    )
                    Spacer(Modifier.width(6.dp))
                    Text(range.label, maxLines = 1, overflow = TextOverflow.Ellipsis)
                }
            }
        }
        if (state.availableTags.isNotEmpty()) {
            item {
                Text("标签", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                Spacer(Modifier.height(8.dp))
                FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    state.availableTags.forEach { tag ->
                        CompactFilterChip(
                            selected = tag in state.selectedSummaryTags,
                            onClick = { onToggleSummaryTag(tag) },
                            label = tag,
                        )
                    }
                }
            }
        }
        item {
            Column(
                Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(8.dp))
                    .background(MaterialTheme.colorScheme.surface)
                    .clickable { onTemplateExpanded(!state.templateExpanded) }
                    .padding(12.dp),
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Column(Modifier.weight(1f)) {
                        Text("模板", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                        Text(
                            if (state.templateExpanded) "可编辑" else "默认模板",
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            style = MaterialTheme.typography.bodySmall,
                        )
                    }
                    Icon(
                        if (state.templateExpanded) Icons.Rounded.KeyboardArrowUp else Icons.Rounded.KeyboardArrowDown,
                        contentDescription = null,
                    )
                }
                if (state.templateExpanded) {
                    Spacer(Modifier.height(8.dp))
                    OutlinedTextField(
                        value = state.templateText,
                        onValueChange = onTemplateChange,
                        minLines = 5,
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(6.dp),
                    )
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                        TextButton(onClick = { onTemplateChange(defaultTemplate(state.selectedPeriod)) }) {
                            Text("恢复默认")
                        }
                        TextButton(onClick = onTemplateReset) {
                            Text("重置")
                        }
                    }
                }
            }
        }
        item {
            Button(
                onClick = onGenerateSummary,
                enabled = !state.isGeneratingSummary && state.clientConfig?.hostedModelAvailable != false,
                modifier = Modifier.fillMaxWidth().height(48.dp),
                shape = RoundedCornerShape(6.dp),
                colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary),
            ) {
                if (state.isGeneratingSummary) {
                    CircularProgressIndicator(Modifier.size(18.dp), color = MaterialTheme.colorScheme.onPrimary)
                    Spacer(Modifier.width(8.dp))
                    Text("生成中")
                } else {
                    Text("生成总结")
                }
            }
            if (state.clientConfig?.hostedModelAvailable == false) {
                Spacer(Modifier.height(6.dp))
                Text("官方托管模型暂不可用。", color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall)
            }
        }
        state.latestSummary?.let { output ->
            item {
                Card(
                    border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                    shape = RoundedCornerShape(8.dp),
                    elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
                ) {
                    Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text("最新总结", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
                            IconButton(
                                onClick = {
                                    clipboard.setText(AnnotatedString(output))
                                    coroutineScope.launch { snackbarHostState.showSnackbar("已复制总结。") }
                                },
                                modifier = Modifier.semantics { contentDescription = "复制最新总结" },
                            ) {
                                Icon(painterResource(R.drawable.ic_content_copy_round), contentDescription = null)
                            }
                        }
                        Text(output, style = MaterialTheme.typography.bodyMedium)
                    }
                }
            }
        }
    }
}

@Composable
private fun HistoryScreen(
    state: AIMemoUiState,
    snackbarHostState: SnackbarHostState,
    onRefresh: () -> Unit,
) {
    var expandedId by rememberSaveable { mutableStateOf<String?>(null) }
    val clipboard = LocalClipboardManager.current
    val coroutineScope = rememberCoroutineScope()
    Column(Modifier.fillMaxSize()) {
        PageHeader(
            title = "历史记录",
            subtitle = "${state.summaries.size} 条总结",
            actionLabel = "刷新历史",
            onAction = onRefresh,
            enabled = !state.isLoadingHistory,
        )
        if (state.isLoadingHistory && state.summaries.isEmpty()) {
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { CircularProgressIndicator() }
        } else if (state.summaries.isEmpty()) {
            EmptyListText("生成后会自动保存到这里。")
        } else {
            LazyColumn(
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                items(state.summaries, key = { it.id }) { summary ->
                    Card(
                        modifier = Modifier.fillMaxWidth().clickable {
                            expandedId = if (expandedId == summary.id) null else summary.id
                        },
                        shape = RoundedCornerShape(8.dp),
                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
                        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline),
                    ) {
                        Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Column(Modifier.weight(1f)) {
                                    Text(summary.periodLabel, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                                    Text(
                                        "${summary.periodType.title} · ${summary.model} · ${summary.createdAt}",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                                        maxLines = 1,
                                        overflow = TextOverflow.Ellipsis,
                                    )
                                }
                                IconButton(
                                    onClick = {
                                        clipboard.setText(AnnotatedString(summary.output))
                                        coroutineScope.launch { snackbarHostState.showSnackbar("已复制总结。") }
                                    },
                                    modifier = Modifier.semantics { contentDescription = "复制总结" },
                                ) {
                                    Icon(painterResource(R.drawable.ic_content_copy_round), contentDescription = null)
                                }
                            }
                            if (summary.tags.isNotEmpty()) {
                                FlowRow(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                                    summary.tags.forEach { TagPill(it) }
                                }
                            }
                            Text(
                                summary.output,
                                maxLines = if (expandedId == summary.id) Int.MAX_VALUE else 3,
                                overflow = TextOverflow.Ellipsis,
                            )
                        }
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun AccountScreen(
    state: AIMemoUiState,
    onBack: () -> Unit,
    showBack: Boolean = true,
    onEmailChange: (String) -> Unit,
    onCodeChange: (String) -> Unit,
    onSendCode: () -> Unit,
    onLogin: () -> Unit,
    onLogout: () -> Unit,
    snackbarHostState: SnackbarHostState,
) {
    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            if (showBack || state.isLoggedIn) {
                TopAppBar(
                    title = { Text("我的", fontWeight = FontWeight.SemiBold) },
                    navigationIcon = {
                        if (showBack) {
                            IconButton(onClick = onBack, modifier = Modifier.semantics { contentDescription = "返回" }) {
                                Icon(Icons.AutoMirrored.Rounded.ArrowBack, contentDescription = null)
                            }
                        }
                    },
                    colors = TopAppBarDefaults.topAppBarColors(containerColor = MaterialTheme.colorScheme.background),
                )
            }
        },
    ) { padding ->
        if (state.isLoggedIn) {
            LoggedInAccount(
                state = state,
                onLogout = onLogout,
                modifier = Modifier.padding(padding),
            )
        } else {
            LoginAccount(
                state = state,
                onEmailChange = onEmailChange,
                onCodeChange = onCodeChange,
                onSendCode = onSendCode,
                onLogin = onLogin,
                modifier = Modifier.padding(padding),
            )
        }
    }
}

@Composable
private fun LoginAccount(
    state: AIMemoUiState,
    onEmailChange: (String) -> Unit,
    onCodeChange: (String) -> Unit,
    onSendCode: () -> Unit,
    onLogin: () -> Unit,
    modifier: Modifier,
) {
    Column(
        modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .verticalScroll(rememberScrollState())
            .imePadding()
            .padding(horizontal = 20.dp, vertical = 28.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Image(
            painterResource(R.drawable.logo),
            contentDescription = null,
            modifier = Modifier
                .size(92.dp)
                .clip(RoundedCornerShape(22.dp)),
            contentScale = ContentScale.Fit,
        )
        Spacer(Modifier.height(24.dp))
        Text(
            "AIMemo",
            style = MaterialTheme.typography.headlineLarge,
            fontWeight = FontWeight.SemiBold,
        )
        Spacer(Modifier.height(8.dp))
        Text(
            "登录后开始记录任务和生成总结。",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Spacer(Modifier.height(32.dp))
        Surface(
            color = MaterialTheme.colorScheme.surface,
            shape = RoundedCornerShape(12.dp),
            border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline),
            shadowElevation = 0.dp,
            modifier = Modifier.fillMaxWidth(),
        ) {
            Column(
                Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                OutlinedTextField(
                    value = state.authEmail,
                    onValueChange = onEmailChange,
                    label = { Text("邮箱") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email, imeAction = ImeAction.Next),
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(6.dp),
                )
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                    OutlinedTextField(
                        value = state.authCode,
                        onValueChange = onCodeChange,
                        label = { Text("验证码") },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number, imeAction = ImeAction.Done),
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(6.dp),
                    )
                    OutlinedButton(
                        onClick = onSendCode,
                        enabled = !state.isSendingCode,
                        modifier = Modifier.height(56.dp),
                        shape = RoundedCornerShape(6.dp),
                    ) {
                        if (state.isSendingCode) CircularProgressIndicator(Modifier.size(16.dp)) else Text("发送")
                    }
                }
                Button(
                    onClick = onLogin,
                    enabled = !state.isLoggingIn,
                    modifier = Modifier.fillMaxWidth().height(48.dp),
                    shape = RoundedCornerShape(6.dp),
                ) {
                    if (state.isLoggingIn) CircularProgressIndicator(Modifier.size(18.dp), color = MaterialTheme.colorScheme.onPrimary) else Text("登录")
                }
            }
        }
        Spacer(Modifier.height(28.dp))
    }
}

@Composable
private fun LoggedInAccount(
    state: AIMemoUiState,
    onLogout: () -> Unit,
    modifier: Modifier,
) {
    Column(
        modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .padding(horizontal = 20.dp, vertical = 24.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Image(
            painterResource(R.drawable.logo),
            contentDescription = null,
            modifier = Modifier.size(132.dp),
            contentScale = ContentScale.Fit,
        )
        Surface(
            color = MaterialTheme.colorScheme.surface,
            shape = RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp),
            shadowElevation = 8.dp,
            modifier = Modifier.fillMaxWidth().weight(1f),
        ) {
            Column(
                Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(20.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Text(state.user?.email ?: "AIMemo 账号", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.SemiBold)
                InfoRow("免费额度", state.quota?.let { "${it.remaining}/${it.limit} 剩余" } ?: "加载中")
                InfoRow("官方模型", if (state.clientConfig?.hostedModelAvailable == true) "可用" else "暂不可用")
                InfoRow("同步状态", "云端账号模式")
                Spacer(Modifier.height(8.dp))
                OutlinedButton(
                    onClick = onLogout,
                    modifier = Modifier.fillMaxWidth().height(48.dp),
                    shape = RoundedCornerShape(6.dp),
                ) {
                    Icon(painterResource(R.drawable.ic_logout_round), contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(Modifier.width(8.dp))
                    Text("退出登录")
                }
            }
        }
    }
}

@Composable
private fun InfoRow(label: String, value: String) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(8.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline),
    ) {
        Row(Modifier.fillMaxWidth().padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
            Text(label, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.weight(1f))
            Text(value, fontWeight = FontWeight.Medium)
        }
    }
}
