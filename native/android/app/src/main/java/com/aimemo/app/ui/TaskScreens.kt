package com.aimemo.app.ui

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
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
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Add
import androidx.compose.material.icons.rounded.Check
import androidx.compose.material.icons.rounded.Person
import androidx.compose.material.icons.rounded.Settings
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.aimemo.app.R
import com.aimemo.app.domain.TaskRecord
import com.aimemo.app.domain.cleanTags
import com.aimemo.app.domain.sectionTasks
import java.time.Instant

@Composable
fun TasksScreen(
    state: AIMemoUiState,
    snackbarHostState: SnackbarHostState,
    onOpenProfile: () -> Unit,
    onOpenSettings: () -> Unit,
    onOpenSummary: () -> Unit,
    onEditTask: (String) -> Unit,
    onRefresh: () -> Unit,
    onSelectTag: (String?) -> Unit,
    onToggleCompleted: (TaskRecord) -> Unit,
    onAddTask: (String) -> Unit,
) {
    var quickTask by rememberSaveable { mutableStateOf("") }
    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            Row(
                Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Column(Modifier.weight(1f)) {
                    Text("Tasks", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
                    Text(taskSubtitle(state), color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                IconButton(onClick = onOpenProfile, modifier = Modifier.semantics { contentDescription = "Profile" }) {
                    Icon(Icons.Rounded.Person, contentDescription = null)
                }
                IconButton(onClick = onOpenSettings, modifier = Modifier.semantics { contentDescription = "Settings" }) {
                    Icon(Icons.Rounded.Settings, contentDescription = null)
                }
            }
        },
        floatingActionButton = {
            FloatingActionButton(onClick = onOpenSummary, containerColor = MaterialTheme.colorScheme.primary) {
                Icon(R.drawable.ic_auto_awesome_round.let { androidx.compose.ui.res.painterResource(it) }, contentDescription = "Summary")
            }
        },
        bottomBar = {
            Row(
                Modifier
                    .fillMaxWidth()
                    .navigationBarsPadding()
                    .imePadding()
                    .padding(12.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                OutlinedTextField(
                    value = quickTask,
                    onValueChange = { quickTask = it },
                    placeholder = { Text("Quick add task") },
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(14.dp),
                    keyboardOptions = KeyboardOptions(imeAction = ImeAction.Send),
                )
                Button(
                    onClick = {
                        onAddTask(quickTask)
                        quickTask = ""
                    },
                    enabled = quickTask.isNotBlank() && !state.isSavingTask,
                    modifier = Modifier.size(52.dp),
                    shape = RoundedCornerShape(16.dp),
                    contentPadding = PaddingValues(0.dp),
                ) {
                    if (state.isSavingTask) CircularProgressIndicator(Modifier.size(18.dp)) else Icon(Icons.Rounded.Add, contentDescription = null)
                }
            }
        },
    ) { padding ->
        Column(Modifier.padding(padding).fillMaxSize()) {
            if (state.availableTags.isNotEmpty() || state.selectedTag != null) {
                TagFilterRow(tags = state.availableTags, selected = state.selectedTag, onSelect = onSelectTag)
            }
            if (state.isLoadingTasks && state.tasks.isEmpty()) {
                EmptyState("Loading tasks...")
            } else {
                val sections = remember(state.filteredTasks) { sectionTasks(state.filteredTasks) }
                LazyColumn(
                    contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 6.dp, bottom = 108.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    taskSection("Active", sections.active, onEditTask, onToggleCompleted)
                    taskSection("Upcoming", sections.upcoming, onEditTask, onToggleCompleted)
                    taskSection("Completed", sections.completed, onEditTask, onToggleCompleted)
                    if (state.filteredTasks.isEmpty()) {
                        item { EmptyState("No tasks yet. Add one from the bottom bar.", Modifier.height(260.dp)) }
                    }
                    item {
                        TextButton(onClick = onRefresh, enabled = !state.isLoadingTasks, modifier = Modifier.fillMaxWidth()) {
                            Text(if (state.isLoadingTasks) "Refreshing..." else "Refresh")
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun TagFilterRow(tags: List<String>, selected: String?, onSelect: (String?) -> Unit) {
    LazyRow(contentPadding = PaddingValues(horizontal = 16.dp, vertical = 4.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        item { AppFilterChip("All", selected == null) { onSelect(null) } }
        items(tags) { tag -> AppFilterChip(tag, selected == tag) { onSelect(tag) } }
    }
}

@OptIn(ExperimentalFoundationApi::class)
private fun androidx.compose.foundation.lazy.LazyListScope.taskSection(
    title: String,
    tasks: List<TaskRecord>,
    onEditTask: (String) -> Unit,
    onToggleCompleted: (TaskRecord) -> Unit,
) {
    stickyHeader {
        Text(
            "$title (${tasks.size})",
            modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp),
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
        )
    }
    if (tasks.isEmpty()) {
        item { Text("Nothing here.", color = MaterialTheme.colorScheme.onSurfaceVariant) }
    } else {
        items(tasks, key = { it.id }) { task ->
            TaskCard(task = task, onClick = { onEditTask(task.id) }, onToggleCompleted = { onToggleCompleted(task) })
        }
    }
}

@Composable
private fun TaskCard(task: TaskRecord, onClick: () -> Unit, onToggleCompleted: () -> Unit) {
    SoftCard(onClick = onClick) {
        Row(Modifier.padding(14.dp), horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.Top) {
            IconButton(
                onClick = onToggleCompleted,
                modifier = Modifier.size(44.dp).semantics { contentDescription = if (task.isCompleted) "Mark incomplete" else "Mark completed" },
            ) {
                CompleteIcon(task.isCompleted, Modifier.size(24.dp))
            }
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(7.dp)) {
                Text(
                    task.title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    textDecoration = if (task.isCompleted) TextDecoration.LineThrough else TextDecoration.None,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                )
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    if (task.tags.isNotEmpty()) {
                        LazyRow(Modifier.weight(1f), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                            items(task.tags.take(3)) { TagPill(it) }
                        }
                    } else {
                        Spacer(Modifier.weight(1f))
                    }
                    Text(formatDate(if (task.isCompleted) task.completedAt ?: task.updatedAt else task.createdAt), style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }
    }
}

@Composable
fun TaskEditScreen(
    task: TaskRecord?,
    saving: Boolean,
    deleting: Boolean,
    onBack: () -> Unit,
    onSave: (TaskRecord, String, String, Instant, Instant?) -> Unit,
    onDelete: (TaskRecord) -> Unit,
) {
    if (task == null) {
        AppScaffoldFrame(title = "Task", onBack = onBack) { EmptyState("Task not found.") }
        return
    }
    var title by rememberSaveable(task.id) { mutableStateOf(task.title) }
    var notes by rememberSaveable(task.id) { mutableStateOf(task.detail) }
    var tags by rememberSaveable(task.id) { mutableStateOf(task.tags.joinToString(", ")) }
    var startAtText by rememberSaveable(task.id) { mutableStateOf(task.createdAt.toString()) }
    var completed by rememberSaveable(task.id) { mutableStateOf(task.isCompleted) }
    var error by rememberSaveable(task.id) { mutableStateOf<String?>(null) }
    var confirmDelete by rememberSaveable(task.id) { mutableStateOf(false) }

    AppScaffoldFrame(title = "Edit Task", subtitle = "Update title, notes, tags and start time", onBack = onBack) { padding ->
        Column(
            Modifier
                .padding(padding)
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .imePadding()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            OutlinedTextField(title, { title = it }, label = { Text("Title") }, modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(12.dp))
            OutlinedTextField(notes, { notes = it }, label = { Text("Notes") }, minLines = 4, modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(12.dp))
            OutlinedTextField(tags, { tags = it }, label = { Text("Tags") }, modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(12.dp))
            OutlinedTextField(startAtText, { startAtText = it }, label = { Text("Start Time") }, modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(12.dp))
            SoftCard {
                Row(Modifier.padding(14.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text("Mark as completed", modifier = Modifier.weight(1f), fontWeight = FontWeight.Medium)
                    Switch(checked = completed, onCheckedChange = { completed = it })
                }
            }
            error?.let { Text(it, color = MaterialTheme.colorScheme.error) }
            GradientButton(
                text = "Save Changes",
                onClick = {
                    val startAt = runCatching { Instant.parse(startAtText.trim()) }.getOrNull()
                    error = when {
                        title.trim().isEmpty() -> "Title is required."
                        startAt == null -> "Start Time must be an ISO timestamp."
                        else -> null
                    }
                    if (error == null) {
                        val completedAt = if (completed) task.completedAt ?: Instant.now() else null
                        onSave(task, buildTaskBody(title, notes), cleanTags(tags).joinToString(", "), startAt!!, completedAt)
                    }
                },
                loading = saving,
            )
            TextButton(onClick = { confirmDelete = true }, modifier = Modifier.fillMaxWidth()) {
                Text("Delete task", color = MaterialTheme.colorScheme.error, fontWeight = FontWeight.Medium)
            }
            Spacer(Modifier.height(20.dp))
        }
    }

    if (confirmDelete) {
        AlertDialog(
            onDismissRequest = { confirmDelete = false },
            title = { Text("Delete task") },
            text = { Text("This task will be removed from the visible list.") },
            confirmButton = {
                Button(
                    onClick = {
                        confirmDelete = false
                        onDelete(task)
                    },
                    enabled = !deleting,
                ) {
                    if (deleting) CircularProgressIndicator(Modifier.size(16.dp)) else Text("Delete")
                }
            },
            dismissButton = { TextButton(onClick = { confirmDelete = false }) { Text("Cancel") } },
        )
    }
}

private fun taskSubtitle(state: AIMemoUiState): String {
    val sections = sectionTasks(state.filteredTasks)
    return "${sections.active.size} active · ${sections.upcoming.size} upcoming · ${sections.completed.size} completed"
}
