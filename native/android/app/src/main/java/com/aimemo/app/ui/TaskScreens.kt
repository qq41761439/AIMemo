package com.aimemo.app.ui

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.rounded.Add
import androidx.compose.material.icons.rounded.Check
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material.icons.rounded.Person
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.aimemo.app.R
import com.aimemo.app.domain.TaskRecord
import com.aimemo.app.domain.cleanTags
import com.aimemo.app.domain.sectionTasks
import com.aimemo.app.ui.theme.AimemoPrimary
import com.aimemo.app.ui.theme.AimemoPrimaryEnd
import java.time.Instant

private val ScreenBg = Color(0xFFFCFBFF)
private val Ink = Color(0xFF080C1B)
private val Muted = Color(0xFF6F7488)
private val Hairline = Color(0xFFE6E4EC)
private val SoftLilac = Color(0xFFF6F2FF)
private val TagBg = Color(0xFFF0EBFA)
private val Danger = Color(0xFFE51B2A)

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
    val sections = remember(state.filteredTasks) { sectionTasks(state.filteredTasks) }
    val tags = remember(state.availableTags) {
        listOf("Product", "Client", "Study", "Personal").let { preferred ->
            (preferred + state.availableTags).distinct()
        }
    }

    Scaffold(
        containerColor = ScreenBg,
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            MainTabsHeader(
                selected = "Tasks",
                onTasks = {},
                onSummary = onOpenSummary,
                onProfile = onOpenProfile,
            )
        },
        bottomBar = {
            QuickAddBar(
                value = quickTask,
                onValueChange = { quickTask = it },
                saving = state.isSavingTask,
                onAdd = {
                    onAddTask(quickTask)
                    quickTask = ""
                },
            )
        },
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize(),
            contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 18.dp, bottom = 112.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            item {
                TagFilterRow(tags = tags, selected = state.selectedTag, onSelect = onSelectTag)
            }
            if (state.isLoadingTasks && state.tasks.isEmpty()) {
                item { EmptyState("Loading tasks...", Modifier.height(260.dp)) }
            } else {
                item {
                    PrototypeTaskSection(
                        title = "Active",
                        subtitle = "Already started  ·  Needs attention",
                        tasks = sections.active,
                        expanded = true,
                        tinted = true,
                        onEditTask = onEditTask,
                        onToggleCompleted = onToggleCompleted,
                    )
                }
                item {
                    PrototypeTaskSection(
                        title = "Upcoming",
                        tasks = sections.upcoming,
                        expanded = true,
                        onEditTask = onEditTask,
                        onToggleCompleted = onToggleCompleted,
                    )
                }
                item {
                    PrototypeTaskSection(
                        title = "Completed",
                        tasks = sections.completed,
                        expanded = true,
                        onEditTask = onEditTask,
                        onToggleCompleted = onToggleCompleted,
                    )
                }
                if (state.filteredTasks.isEmpty()) {
                    item { EmptyState("No tasks yet. Add one from the bottom bar.", Modifier.height(180.dp)) }
                }
                item {
                    TextButton(
                        onClick = onRefresh,
                        enabled = !state.isLoadingTasks,
                        modifier = Modifier.fillMaxWidth(),
                    ) {
                        Text(if (state.isLoadingTasks) "Refreshing..." else "Refresh", color = AimemoPrimary)
                    }
                }
            }
        }
    }
}

@Composable
private fun MainTabsHeader(
    selected: String,
    onTasks: () -> Unit,
    onSummary: () -> Unit,
    onProfile: () -> Unit,
) {
    Surface(
        color = Color.White,
        shadowElevation = 0.dp,
        border = BorderStroke(0.dp, Color.Transparent),
    ) {
        Column {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(start = 40.dp, end = 28.dp, top = 42.dp, bottom = 0.dp),
                verticalAlignment = Alignment.Bottom,
            ) {
                TabTitle("Tasks", selected == "Tasks", onTasks)
                Spacer(Modifier.width(42.dp))
                TabTitle("Summary", selected == "Summary", onSummary)
                Spacer(Modifier.weight(1f))
                IconButton(
                    onClick = onProfile,
                    modifier = Modifier
                        .size(48.dp)
                        .semantics { contentDescription = "Profile" },
                ) {
                    Box(
                        modifier = Modifier
                            .size(31.dp)
                            .border(1.8.dp, Ink, CircleShape),
                        contentAlignment = Alignment.Center,
                    ) {
                        Icon(Icons.Rounded.Person, contentDescription = null, tint = Ink, modifier = Modifier.size(23.dp))
                    }
                }
            }
            HorizontalDivider(color = Hairline, thickness = 1.dp)
        }
    }
}

@Composable
private fun TabTitle(label: String, active: Boolean, onClick: () -> Unit) {
    Column(
        modifier = Modifier
            .width(if (label == "Summary") 96.dp else 72.dp)
            .clickable(onClick = onClick)
            .padding(bottom = 0.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            label,
            color = if (active) Ink else Color(0xFF777B8E),
            fontSize = 21.sp,
            lineHeight = 28.sp,
            fontWeight = FontWeight.Bold,
        )
        Spacer(Modifier.height(18.dp))
        Box(
            modifier = Modifier
                .width(if (active) 37.dp else 0.dp)
                .height(2.dp)
                .clip(RoundedCornerShape(1.dp))
                .background(Ink),
        )
        Spacer(Modifier.height(7.dp))
    }
}

@Composable
private fun TagFilterRow(tags: List<String>, selected: String?, onSelect: (String?) -> Unit) {
    LazyRow(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        item { PrototypeFilterChip("All", selected == null) { onSelect(null) } }
        items(tags) { tag -> PrototypeFilterChip(tag, selected == tag) { onSelect(tag) } }
    }
}

@Composable
private fun PrototypeFilterChip(label: String, selected: Boolean, onClick: () -> Unit) {
    Surface(
        modifier = Modifier
            .height(44.dp)
            .width(
                when (label.length) {
                    in 0..3 -> 60.dp
                    in 4..6 -> 76.dp
                    else -> 98.dp
                },
            )
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(22.dp),
        color = Color.White,
        border = BorderStroke(1.dp, if (selected) AimemoPrimary else Hairline),
    ) {
        Box(contentAlignment = Alignment.Center) {
            Text(
                label,
                color = if (selected) AimemoPrimary else Color(0xFF555B70),
                fontSize = 15.sp,
                fontWeight = FontWeight.Medium,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}

@Composable
private fun PrototypeTaskSection(
    title: String,
    subtitle: String? = null,
    tasks: List<TaskRecord>,
    expanded: Boolean,
    tinted: Boolean = false,
    onEditTask: (String) -> Unit,
    onToggleCompleted: (TaskRecord) -> Unit,
) {
    val sectionShape = RoundedCornerShape(18.dp)
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(if (tinted) 2.dp else 1.dp, sectionShape, ambientColor = Color(0x12000000), spotColor = Color(0x12000000)),
        shape = sectionShape,
        color = if (tinted) SoftLilac else Color.White,
        border = BorderStroke(1.dp, Color(0xFFEDE9F4)),
    ) {
        Column(Modifier.padding(horizontal = 12.dp, vertical = 14.dp)) {
            Row(verticalAlignment = Alignment.Top) {
                Column(Modifier.weight(1f)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(title, color = Ink, fontSize = 23.sp, lineHeight = 28.sp, fontWeight = FontWeight.Bold)
                        Spacer(Modifier.width(10.dp))
                        CountBadge(tasks.size)
                    }
                    if (subtitle != null) {
                        Spacer(Modifier.height(8.dp))
                        Text(subtitle, color = Muted, fontSize = 14.sp, lineHeight = 18.sp)
                    }
                }
                Icon(
                    painter = painterResource(R.drawable.ic_chevron_right_round),
                    contentDescription = null,
                    tint = Color(0xFF7C8295),
                    modifier = Modifier
                        .padding(top = 4.dp)
                        .size(30.dp)
                        .rotate(if (expanded) -90f else 90f),
                )
            }
            if (expanded) {
                Spacer(Modifier.height(if (subtitle == null) 16.dp else 22.dp))
                TaskListCard(tasks, onEditTask, onToggleCompleted)
            }
        }
    }
}

@Composable
private fun CountBadge(count: Int) {
    Surface(shape = CircleShape, color = Color(0xFFEDE7FF)) {
        Text(
            count.toString(),
            modifier = Modifier
                .width(28.dp)
                .padding(vertical = 5.dp),
            color = AimemoPrimary,
            textAlign = TextAlign.Center,
            fontSize = 13.sp,
            lineHeight = 15.sp,
            fontWeight = FontWeight.Bold,
        )
    }
}

@Composable
private fun TaskListCard(
    tasks: List<TaskRecord>,
    onEditTask: (String) -> Unit,
    onToggleCompleted: (TaskRecord) -> Unit,
) {
    Surface(
        shape = RoundedCornerShape(14.dp),
        color = Color.White,
        border = BorderStroke(1.dp, Hairline),
    ) {
        Column {
            if (tasks.isEmpty()) {
                Text(
                    "Nothing here.",
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 18.dp),
                    color = Muted,
                    fontSize = 15.sp,
                )
            } else {
                tasks.forEachIndexed { index, task ->
                    PrototypeTaskRow(
                        task = task,
                        onClick = { onEditTask(task.id) },
                        onToggleCompleted = { onToggleCompleted(task) },
                    )
                    if (index != tasks.lastIndex) HorizontalDivider(color = Hairline, thickness = 1.dp)
                }
            }
        }
    }
}

@Composable
private fun PrototypeTaskRow(task: TaskRecord, onClick: () -> Unit, onToggleCompleted: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(start = 14.dp, end = 16.dp, top = 14.dp, bottom = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        IconButton(
            onClick = onToggleCompleted,
            modifier = Modifier
                .size(42.dp)
                .semantics { contentDescription = if (task.isCompleted) "Mark incomplete" else "Mark completed" },
        ) {
            CompletionCircle(completed = task.isCompleted, modifier = Modifier.size(26.dp))
        }
        Spacer(Modifier.width(8.dp))
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(7.dp)) {
            Text(
                task.title,
                color = if (task.isCompleted) Color(0xFF8E93A3) else Ink,
                fontSize = 17.sp,
                lineHeight = 21.sp,
                fontWeight = FontWeight.SemiBold,
                textDecoration = if (task.isCompleted) TextDecoration.LineThrough else TextDecoration.None,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            if (task.tags.isNotEmpty()) {
                LazyRow(horizontalArrangement = Arrangement.spacedBy(7.dp)) {
                    items(task.tags.take(3)) { tag -> MiniTagPill(tag, muted = task.isCompleted) }
                }
            }
        }
        Spacer(Modifier.width(10.dp))
        Text(
            formatDate(if (task.isCompleted) task.completedAt ?: task.updatedAt else task.createdAt),
            color = Color(0xFF62687C),
            fontSize = 14.sp,
            lineHeight = 18.sp,
            maxLines = 1,
        )
    }
}

@Composable
private fun CompletionCircle(completed: Boolean, modifier: Modifier = Modifier) {
    if (completed) {
        Box(
            modifier = modifier
                .clip(CircleShape)
                .background(AppGradient),
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Rounded.Check, contentDescription = null, tint = Color.White, modifier = Modifier.size(17.dp))
        }
    } else {
        Box(
            modifier = modifier
                .clip(CircleShape)
                .border(1.4.dp, Color(0xFFA9AEBC), CircleShape),
        )
    }
}

@Composable
private fun MiniTagPill(label: String, muted: Boolean = false) {
    Surface(shape = RoundedCornerShape(7.dp), color = if (muted) Color(0xFFEDEEF3) else TagBg) {
        Text(
            label,
            modifier = Modifier.padding(horizontal = 9.dp, vertical = 3.dp),
            color = if (muted) Color(0xFF808696) else Color(0xFF4D5268),
            fontSize = 12.sp,
            lineHeight = 14.sp,
            fontWeight = FontWeight.Medium,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

@Composable
private fun QuickAddBar(
    value: String,
    onValueChange: (String) -> Unit,
    saving: Boolean,
    onAdd: () -> Unit,
) {
    Surface(
        color = ScreenBg,
        shadowElevation = 0.dp,
    ) {
        Surface(
            modifier = Modifier
                .fillMaxWidth()
                .navigationBarsPadding()
                .imePadding()
                .padding(start = 16.dp, end = 16.dp, bottom = 12.dp, top = 8.dp)
                .height(70.dp)
                .shadow(8.dp, RoundedCornerShape(35.dp), ambientColor = Color(0x16000000), spotColor = Color(0x18000000)),
            shape = RoundedCornerShape(35.dp),
            color = Color.White,
            border = BorderStroke(1.dp, Color(0xFFEDEBF2)),
        ) {
            Row(
                modifier = Modifier.padding(start = 12.dp, end = 12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Surface(
                    modifier = Modifier.size(46.dp),
                    shape = CircleShape,
                    color = Color.White,
                    border = BorderStroke(1.dp, Color(0xFFECEAF1)),
                    shadowElevation = 2.dp,
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(Icons.Rounded.Add, contentDescription = null, tint = Ink, modifier = Modifier.size(26.dp))
                    }
                }
                Spacer(Modifier.width(18.dp))
                Box(Modifier.weight(1f)) {
                    if (value.isEmpty()) {
                        Text("Quick add a task...", color = Color(0xFFA5AABE), fontSize = 16.sp)
                    }
                    BasicTextField(
                        value = value,
                        onValueChange = onValueChange,
                        singleLine = true,
                        textStyle = TextStyle(color = Ink, fontSize = 16.sp, lineHeight = 20.sp),
                        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Send),
                        cursorBrush = SolidColor(AimemoPrimary),
                        modifier = Modifier.fillMaxWidth(),
                    )
                }
                Spacer(Modifier.width(10.dp))
                Box(
                    modifier = Modifier
                        .size(48.dp)
                        .clip(CircleShape)
                        .background(AppGradient)
                        .clickable(enabled = value.isNotBlank() && !saving, onClick = onAdd),
                    contentAlignment = Alignment.Center,
                ) {
                    if (saving) {
                        CircularProgressIndicator(Modifier.size(18.dp), strokeWidth = 2.dp, color = Color.White)
                    } else {
                        Icon(painterResource(R.drawable.ic_send_round), contentDescription = null, tint = Color.White, modifier = Modifier.size(25.dp))
                    }
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
    val visibleTags = cleanTags(tags)

    Scaffold(
        containerColor = ScreenBg,
        topBar = {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 48.dp, bottom = 24.dp),
            ) {
                IconButton(
                    onClick = onBack,
                    modifier = Modifier
                        .align(Alignment.CenterStart)
                        .padding(start = 12.dp)
                        .size(48.dp)
                        .semantics { contentDescription = "Back" },
                ) {
                    Icon(Icons.AutoMirrored.Rounded.ArrowBack, contentDescription = null, tint = AimemoPrimary, modifier = Modifier.size(34.dp))
                }
                Text(
                    "Edit Task",
                    modifier = Modifier.align(Alignment.Center),
                    color = Ink,
                    fontSize = 26.sp,
                    lineHeight = 31.sp,
                    fontWeight = FontWeight.Bold,
                )
            }
        },
        bottomBar = {
            Surface(color = ScreenBg) {
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
                            onSave(task, buildTaskBody(title, notes), visibleTags.joinToString(", "), startAt!!, completedAt)
                        }
                    },
                    loading = saving,
                    modifier = Modifier
                        .navigationBarsPadding()
                        .imePadding()
                        .padding(horizontal = 16.dp, vertical = 12.dp),
                )
            }
        },
    ) { padding ->
        Column(
            Modifier
                .padding(padding)
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .imePadding()
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            EditFieldCard(label = "Title") {
                PrototypeTextField(
                    value = title,
                    onValueChange = { title = it },
                    singleLine = true,
                    minHeight = 68.dp,
                    textStyle = TextStyle(color = Ink, fontSize = 22.sp, lineHeight = 28.sp),
                )
            }
            EditFieldCard(label = "Notes") {
                PrototypeTextField(
                    value = notes,
                    onValueChange = { notes = it },
                    singleLine = false,
                    minHeight = 184.dp,
                    textStyle = TextStyle(color = Ink, fontSize = 20.sp, lineHeight = 34.sp),
                )
            }
            EditFieldCard(label = "Tags") {
                LazyRow(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    items(visibleTags) { tag ->
                        EditableTagPill(tag = tag, onRemove = {
                            tags = visibleTags.filterNot { it == tag }.joinToString(", ")
                        })
                    }
                }
            }
            EditFieldCard(label = "Start Time") {
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    TimePartBox(
                        icon = { Icon(painterResource(R.drawable.ic_calendar_month_round), contentDescription = null, tint = AimemoPrimary, modifier = Modifier.size(28.dp)) },
                        text = formatDate(task.createdAt) + ", " + task.createdAt.atZone(java.time.ZoneId.systemDefault()).year,
                        modifier = Modifier.weight(1f),
                    )
                    TimePartBox(
                        icon = { Icon(painterResource(R.drawable.ic_schedule_round), contentDescription = null, tint = AimemoPrimary, modifier = Modifier.size(29.dp)) },
                        text = java.time.format.DateTimeFormatter.ofPattern("h:mm a").withZone(java.time.ZoneId.systemDefault()).format(task.createdAt),
                        modifier = Modifier.weight(1f),
                    )
                }
            }
            Surface(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(14.dp),
                color = Color.White,
                shadowElevation = 5.dp,
            ) {
                Row(
                    Modifier.padding(horizontal = 16.dp, vertical = 18.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text("Mark as completed", modifier = Modifier.weight(1f), color = Ink, fontSize = 19.sp, fontWeight = FontWeight.Bold)
                    Switch(
                        checked = completed,
                        onCheckedChange = { completed = it },
                        colors = SwitchDefaults.colors(
                            checkedThumbColor = Color.White,
                            checkedTrackColor = AimemoPrimary,
                            uncheckedThumbColor = Color.White,
                            uncheckedTrackColor = Color(0xFFE5E5EA),
                            uncheckedBorderColor = Color.Transparent,
                        ),
                    )
                }
            }
            Surface(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { confirmDelete = true },
                shape = RoundedCornerShape(14.dp),
                color = Color.White,
                shadowElevation = 5.dp,
            ) {
                Row(
                    Modifier.padding(horizontal = 16.dp, vertical = 18.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(painterResource(R.drawable.ic_delete_outline_round), contentDescription = null, tint = Danger, modifier = Modifier.size(30.dp))
                    Spacer(Modifier.width(16.dp))
                    Text("Delete task", modifier = Modifier.weight(1f), color = Danger, fontSize = 19.sp, fontWeight = FontWeight.Bold)
                    Icon(painterResource(R.drawable.ic_chevron_right_round), contentDescription = null, tint = Color(0xFF767B88), modifier = Modifier.size(32.dp))
                }
            }
            error?.let { Text(it, color = MaterialTheme.colorScheme.error, modifier = Modifier.padding(horizontal = 4.dp)) }
            Spacer(Modifier.height(90.dp))
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

@Composable
private fun EditFieldCard(label: String, content: @Composable () -> Unit) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(14.dp),
        color = Color.White,
        shadowElevation = 5.dp,
    ) {
        Column(Modifier.padding(horizontal = 16.dp, vertical = 18.dp)) {
            Text(label, color = Ink, fontSize = 19.sp, lineHeight = 24.sp, fontWeight = FontWeight.Bold)
            Spacer(Modifier.height(18.dp))
            content()
        }
    }
}

@Composable
private fun PrototypeTextField(
    value: String,
    onValueChange: (String) -> Unit,
    singleLine: Boolean,
    minHeight: androidx.compose.ui.unit.Dp,
    textStyle: TextStyle,
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(minHeight)
            .border(1.dp, Color(0xFFDADCE4), RoundedCornerShape(14.dp))
            .padding(horizontal = 14.dp, vertical = 14.dp),
        contentAlignment = if (singleLine) Alignment.CenterStart else Alignment.TopStart,
    ) {
        BasicTextField(
            value = value,
            onValueChange = onValueChange,
            singleLine = singleLine,
            textStyle = textStyle,
            cursorBrush = SolidColor(AimemoPrimary),
            modifier = Modifier.fillMaxWidth(),
        )
    }
}

@Composable
private fun EditableTagPill(tag: String, onRemove: () -> Unit) {
    Surface(shape = RoundedCornerShape(22.dp), color = Color(0xFFEFE5FF)) {
        Row(
            modifier = Modifier.padding(horizontal = 14.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Text(tag, color = AimemoPrimary, fontSize = 18.sp, lineHeight = 22.sp)
            Icon(
                Icons.Rounded.Close,
                contentDescription = "Remove $tag",
                tint = AimemoPrimary,
                modifier = Modifier
                    .size(18.dp)
                    .clickable(onClick = onRemove),
            )
        }
    }
}

@Composable
private fun TimePartBox(
    icon: @Composable () -> Unit,
    text: String,
    modifier: Modifier = Modifier,
) {
    Surface(
        modifier = modifier.height(70.dp),
        shape = RoundedCornerShape(14.dp),
        color = Color.White,
        border = BorderStroke(1.dp, Color(0xFFDADCE4)),
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            icon()
            Text(text, color = Ink, fontSize = 18.sp, lineHeight = 22.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
    }
}
