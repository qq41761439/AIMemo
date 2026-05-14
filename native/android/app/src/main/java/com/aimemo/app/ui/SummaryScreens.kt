package com.aimemo.app.ui

import android.content.Intent
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
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
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Add
import androidx.compose.material.icons.rounded.Check
import androidx.compose.material.icons.rounded.Person
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
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
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.aimemo.app.R
import com.aimemo.app.domain.PeriodType
import com.aimemo.app.domain.SummaryRecord
import com.aimemo.app.domain.periodRange
import com.aimemo.app.ui.theme.AimemoPrimary
import com.aimemo.app.ui.theme.AimemoPrimaryEnd

private val SummaryBg = Color(0xFFFCFBFF)
private val SummaryInk = Color(0xFF080C1B)
private val SummaryMuted = Color(0xFF6F7488)
private val SummaryLine = Color(0xFFE6E4EC)
private val SummaryPurpleSoft = Color(0xFFF3ECFF)
private val SummaryGradient = Brush.horizontalGradient(listOf(AimemoPrimary, AimemoPrimaryEnd))

@Composable
fun SummaryMainScreen(
    state: AIMemoUiState,
    snackbarHostState: SnackbarHostState,
    onOpenTasks: () -> Unit,
    onOpenProfile: () -> Unit,
    onGenerate: () -> Unit,
    onHistory: () -> Unit,
    onAddTask: (String) -> Unit,
) {
    var quickTask by rememberSaveable { mutableStateOf("") }
    val summaries = remember(state.summaries) { state.summaries.sortedByDescending { it.createdAt }.take(4) }
    Scaffold(
        containerColor = SummaryBg,
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            SummaryTabsHeader(
                selected = "Summary",
                onTasks = onOpenTasks,
                onSummary = {},
                onProfile = onOpenProfile,
            )
        },
        bottomBar = {
            SummaryQuickAddBar(
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
            contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 22.dp, bottom = 112.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp),
        ) {
            item { SummaryHeroCard(onGenerate = onGenerate, loading = state.isGeneratingSummary) }
            item {
                Row(
                    Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text("Recent Summaries", modifier = Modifier.weight(1f), color = SummaryInk, fontSize = 22.sp, fontWeight = FontWeight.Bold)
                    Text(
                        "View all",
                        modifier = Modifier.clickable(onClick = onHistory).padding(8.dp),
                        color = AimemoPrimary,
                        fontSize = 15.sp,
                        fontWeight = FontWeight.Medium,
                    )
                }
            }
            if (summaries.isEmpty()) {
                items(sampleSummaryRows()) { row ->
                    SummaryListRow(row = row, onClick = onHistory)
                }
            } else {
                items(summaries, key = { it.id }) { summary ->
                    SummaryListRow(row = summary.toSummaryRow(), onClick = onHistory)
                }
            }
        }
    }
}

@Composable
private fun SummaryTabsHeader(
    selected: String,
    onTasks: () -> Unit,
    onSummary: () -> Unit,
    onProfile: () -> Unit,
) {
    Surface(color = Color.White) {
        Column {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(start = 38.dp, end = 26.dp, top = 42.dp),
                verticalAlignment = Alignment.Bottom,
            ) {
                SummaryTabTitle("Tasks", selected == "Tasks", onTasks)
                Spacer(Modifier.width(44.dp))
                SummaryTabTitle("Summary", selected == "Summary", onSummary)
                Spacer(Modifier.weight(1f))
                Surface(
                    modifier = Modifier
                        .padding(bottom = 18.dp)
                        .size(46.dp)
                        .clickable(onClick = onProfile),
                    shape = CircleShape,
                    color = Color(0xFFEDE7FF),
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(Icons.Rounded.Person, contentDescription = "Profile", tint = AimemoPrimary, modifier = Modifier.size(28.dp))
                    }
                }
            }
            androidx.compose.material3.HorizontalDivider(color = SummaryLine, thickness = 1.dp)
        }
    }
}

@Composable
private fun SummaryTabTitle(label: String, active: Boolean, onClick: () -> Unit) {
    Column(
        modifier = Modifier
            .width(if (label == "Summary") 104.dp else 72.dp)
            .clickable(onClick = onClick),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            label,
            color = if (active) SummaryInk else Color(0xFF777B8E),
            fontSize = 21.sp,
            lineHeight = 28.sp,
            fontWeight = FontWeight.Bold,
        )
        Spacer(Modifier.height(18.dp))
        Box(
            modifier = Modifier
                .width(if (active) 92.dp else 0.dp)
                .height(3.dp)
                .clip(RoundedCornerShape(2.dp))
                .background(if (active) AimemoPrimary else Color.Transparent),
        )
    }
}

@Composable
private fun SummaryHeroCard(onGenerate: () -> Unit, loading: Boolean) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .height(218.dp)
            .shadow(5.dp, RoundedCornerShape(18.dp), ambientColor = Color(0x12000000), spotColor = Color(0x14000000)),
        shape = RoundedCornerShape(18.dp),
        color = Color(0xFFFAF7FF),
        border = BorderStroke(1.dp, Color(0xFFEDE7FF)),
    ) {
        Box(Modifier.fillMaxSize()) {
            SummaryHeroIllustration(Modifier.align(Alignment.CenterEnd).padding(end = 22.dp).size(145.dp))
            Column(
                modifier = Modifier
                    .align(Alignment.CenterStart)
                    .padding(start = 22.dp, end = 166.dp),
                verticalArrangement = Arrangement.Center,
            ) {
                Text("AI Summary", color = SummaryInk, fontSize = 32.sp, lineHeight = 38.sp, fontWeight = FontWeight.Bold)
                Spacer(Modifier.height(16.dp))
                Text("Turn your tasks into\nclear progress updates.", color = SummaryMuted, fontSize = 20.sp, lineHeight = 30.sp)
                Spacer(Modifier.height(24.dp))
                Box(
                    modifier = Modifier
                        .height(52.dp)
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(14.dp))
                        .background(SummaryGradient)
                        .clickable(enabled = !loading, onClick = onGenerate),
                    contentAlignment = Alignment.Center,
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        Icon(painterResource(R.drawable.ic_auto_awesome_round), contentDescription = null, tint = Color.White, modifier = Modifier.size(24.dp))
                        Text("Generate Summary", color = Color.White, fontSize = 17.sp, fontWeight = FontWeight.Bold)
                    }
                }
            }
        }
    }
}

@Composable
private fun SummaryHeroIllustration(modifier: Modifier = Modifier) {
    Canvas(modifier) {
        drawCircle(Color(0xFFECE5FF), radius = size.minDimension * 0.42f, center = Offset(size.width * 0.56f, size.height * 0.58f))
        drawRoundRect(
            color = Color.White,
            topLeft = Offset(size.width * 0.12f, size.height * 0.04f),
            size = Size(size.width * 0.68f, size.height * 0.86f),
            cornerRadius = CornerRadius(18.dp.toPx(), 18.dp.toPx()),
        )
        drawRoundRect(
            color = Color(0xFFE1D7FF),
            topLeft = Offset(size.width * 0.26f, size.height * 0.2f),
            size = Size(size.width * 0.34f, size.height * 0.05f),
            cornerRadius = CornerRadius(8.dp.toPx(), 8.dp.toPx()),
        )
        repeat(4) { index ->
            val y = size.height * (0.36f + index * 0.11f)
            drawCircle(Color(0xFFC6B1FF), radius = 5.dp.toPx(), center = Offset(size.width * 0.28f, y))
            drawRoundRect(
                color = Color(0xFFE0D8FA),
                topLeft = Offset(size.width * 0.36f, y - 4.dp.toPx()),
                size = Size(size.width * (0.36f - index * 0.04f), 8.dp.toPx()),
                cornerRadius = CornerRadius(6.dp.toPx(), 6.dp.toPx()),
            )
        }
        repeat(3) { index ->
            drawRoundRect(
                color = Color(0xFFC4A9FA),
                topLeft = Offset(size.width * (0.57f + index * 0.1f), size.height * (0.72f - index * 0.04f)),
                size = Size(14.dp.toPx(), size.height * (0.16f + index * 0.04f)),
                cornerRadius = CornerRadius(6.dp.toPx(), 6.dp.toPx()),
            )
        }
        val fold = Path().apply {
            moveTo(size.width * 0.8f, size.height * 0.04f)
            lineTo(size.width * 0.8f, size.height * 0.25f)
            quadraticBezierTo(size.width * 0.8f, size.height * 0.3f, size.width * 0.86f, size.height * 0.3f)
            lineTo(size.width * 0.98f, size.height * 0.3f)
            close()
        }
        drawPath(fold, Color(0xFFE6DBFF))
    }
}

private data class SummaryRow(
    val type: String,
    val title: String,
    val detail: String,
    val tint: Color,
    val accent: Color,
    val icon: Int,
)

private fun sampleSummaryRows(): List<SummaryRow> = listOf(
    SummaryRow("Daily", "Daily  •  May 28, 2025", "8 tasks  •  Generated May 28, 2025", Color(0xFFEAF2FF), Color(0xFF2563EB), R.drawable.ic_auto_awesome_round),
    SummaryRow("Weekly", "Weekly  •  May 19 – May 25, 2025", "24 tasks  •  Generated May 25, 2025", Color(0xFFE9F8EF), Color(0xFF16A05B), R.drawable.ic_calendar_month_round),
    SummaryRow("Monthly", "Monthly  •  May 2025", "96 tasks  •  Generated May 28, 2025", Color(0xFFFFEFE6), Color(0xFFF97316), R.drawable.ic_calendar_month_round),
    SummaryRow("Custom", "Custom  •  Product Launch Sprint", "32 tasks  •  Generated May 27, 2025", Color(0xFFF0EAFE), Color(0xFF6D45D9), R.drawable.ic_auto_awesome_round),
)

private fun SummaryRecord.toSummaryRow(): SummaryRow {
    val period = periodType.name.replaceFirstChar { it.uppercase() }
    val palette = when (periodType) {
        PeriodType.Daily -> Triple(Color(0xFFEAF2FF), Color(0xFF2563EB), R.drawable.ic_auto_awesome_round)
        PeriodType.Weekly -> Triple(Color(0xFFE9F8EF), Color(0xFF16A05B), R.drawable.ic_calendar_month_round)
        PeriodType.Monthly, PeriodType.Yearly -> Triple(Color(0xFFFFEFE6), Color(0xFFF97316), R.drawable.ic_calendar_month_round)
        PeriodType.Custom -> Triple(Color(0xFFF0EAFE), Color(0xFF6D45D9), R.drawable.ic_auto_awesome_round)
    }
    return SummaryRow(
        type = period,
        title = "$period  •  $periodLabel",
        detail = "${tags.ifEmpty { listOf("All") }.joinToString(", ")}  •  Generated ${formatDate(createdAt)}",
        tint = palette.first,
        accent = palette.second,
        icon = palette.third,
    )
}

@Composable
private fun SummaryListRow(row: SummaryRow, onClick: () -> Unit) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .height(76.dp)
            .shadow(4.dp, RoundedCornerShape(14.dp), ambientColor = Color(0x10000000), spotColor = Color(0x14000000))
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(14.dp),
        color = Color.White,
        border = BorderStroke(1.dp, Color(0xFFEDEBF2)),
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Surface(modifier = Modifier.size(50.dp), shape = RoundedCornerShape(14.dp), color = row.tint) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(painterResource(row.icon), contentDescription = null, tint = row.accent, modifier = Modifier.size(30.dp))
                }
            }
            Spacer(Modifier.width(14.dp))
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(7.dp)) {
                Text(row.title, color = SummaryInk, fontSize = 17.sp, lineHeight = 21.sp, fontWeight = FontWeight.SemiBold, maxLines = 1, overflow = TextOverflow.Ellipsis)
                Text(row.detail, color = SummaryMuted, fontSize = 13.sp, lineHeight = 16.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
            Surface(shape = RoundedCornerShape(9.dp), color = row.tint) {
                Text(row.type, modifier = Modifier.padding(horizontal = 12.dp, vertical = 7.dp), color = row.accent, fontSize = 13.sp, fontWeight = FontWeight.Bold)
            }
            Icon(
                painterResource(R.drawable.ic_chevron_right_round),
                contentDescription = null,
                tint = Color(0xFF4D5363),
                modifier = Modifier.size(32.dp),
            )
        }
    }
}

@Composable
private fun SummaryQuickAddBar(
    value: String,
    onValueChange: (String) -> Unit,
    saving: Boolean,
    onAdd: () -> Unit,
) {
    Surface(color = SummaryBg) {
        Surface(
            modifier = Modifier
                .fillMaxWidth()
                .navigationBarsPadding()
                .imePadding()
                .padding(start = 16.dp, end = 16.dp, bottom = 12.dp, top = 8.dp)
                .height(70.dp)
                .shadow(8.dp, RoundedCornerShape(21.dp), ambientColor = Color(0x16000000), spotColor = Color(0x18000000)),
            shape = RoundedCornerShape(21.dp),
            color = Color.White,
            border = BorderStroke(1.dp, Color(0xFFEDEBF2)),
        ) {
            Row(modifier = Modifier.padding(horizontal = 12.dp), verticalAlignment = Alignment.CenterVertically) {
                Surface(modifier = Modifier.size(50.dp), shape = CircleShape, color = SummaryPurpleSoft) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(Icons.Rounded.Add, contentDescription = null, tint = AimemoPrimary, modifier = Modifier.size(29.dp))
                    }
                }
                Spacer(Modifier.width(18.dp))
                Box(Modifier.weight(1f)) {
                    if (value.isEmpty()) Text("Quick add a task...", color = Color(0xFFA0A5B8), fontSize = 17.sp)
                    BasicTextField(
                        value = value,
                        onValueChange = onValueChange,
                        singleLine = true,
                        textStyle = TextStyle(color = SummaryInk, fontSize = 17.sp),
                        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Send),
                        cursorBrush = SolidColor(AimemoPrimary),
                        modifier = Modifier.fillMaxWidth(),
                    )
                }
                Spacer(Modifier.width(10.dp))
                Box(
                    modifier = Modifier
                        .size(50.dp)
                        .clip(CircleShape)
                        .background(SummaryGradient)
                        .clickable(enabled = value.isNotBlank() && !saving, onClick = onAdd),
                    contentAlignment = Alignment.Center,
                ) {
                    if (saving) {
                        CircularProgressIndicator(Modifier.size(18.dp), strokeWidth = 2.dp, color = Color.White)
                    } else {
                        Icon(painterResource(R.drawable.ic_send_round), contentDescription = null, tint = Color.White, modifier = Modifier.size(26.dp))
                    }
                }
            }
        }
    }
}

@Composable
fun SummaryEntryScreen(
    state: AIMemoUiState,
    onBack: () -> Unit,
    onHistory: () -> Unit,
    onSelectPeriod: (PeriodType) -> Unit,
    onToggleTag: (String) -> Unit,
    onGenerate: () -> Unit,
) {
    AppScaffoldFrame(title = "AI Summary", subtitle = "Generate a focused report from your tasks", onBack = onBack) { padding ->
        LazyColumn(
            Modifier.padding(padding).fillMaxSize(),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            item {
                SoftCard {
                    Column(Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        IconBubble(R.drawable.ic_auto_awesome_round)
                        Text("Turn tasks into a clear summary", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                        Text("Choose a report type, optionally narrow by tags, then generate a report you can copy or share.", color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
            }
            item {
                Text("Report type", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                Spacer(Modifier.height(8.dp))
                PeriodSelector(selected = state.selectedPeriod, onSelect = onSelectPeriod)
            }
            if (state.availableTags.isNotEmpty()) {
                item {
                    Text("Included tags", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                    Spacer(Modifier.height(8.dp))
                    FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        state.availableTags.forEach { tag ->
                            AppFilterChip(label = tag, selected = tag in state.selectedSummaryTags, onClick = { onToggleTag(tag) })
                        }
                    }
                }
            }
            item {
                Text(
                    "Range: ${periodRange(state.selectedPeriod).label}",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            item {
                GradientButton("Generate Summary", onClick = onGenerate, loading = state.isGeneratingSummary, enabled = state.clientConfig?.hostedModelAvailable != false)
                if (state.clientConfig?.hostedModelAvailable == false) {
                    Spacer(Modifier.height(6.dp))
                    Text("Hosted model is unavailable.", color = MaterialTheme.colorScheme.error)
                }
            }
            item {
                TextButton(onClick = onHistory, modifier = Modifier.fillMaxWidth()) { Text("View Summary History") }
            }
        }
    }
}

@Composable
fun SummaryResultScreen(
    state: AIMemoUiState,
    onBack: () -> Unit,
    onConfirm: () -> Unit,
    onRefine: (String) -> Unit,
) {
    val clipboard = LocalClipboardManager.current
    val context = LocalContext.current
    var refinement by rememberSaveable { mutableStateOf("") }
    AppScaffoldFrame(title = "Summary Result", subtitle = periodRange(state.selectedPeriod).label, onBack = onBack) { padding ->
        Column(
            Modifier
                .padding(padding)
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            SoftCard {
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        IconButton(
                            onClick = { clipboard.setText(AnnotatedString(state.latestSummary.orEmpty())) },
                            modifier = Modifier.semantics { contentDescription = "Copy summary" },
                        ) {
                            Icon(painterResource(R.drawable.ic_content_copy_round), contentDescription = null)
                        }
                        IconButton(
                            onClick = {
                                val intent = Intent(Intent.ACTION_SEND).apply {
                                    type = "text/plain"
                                    putExtra(Intent.EXTRA_TEXT, state.latestSummary.orEmpty())
                                }
                                context.startActivity(Intent.createChooser(intent, "Share summary"))
                            },
                            modifier = Modifier.semantics { contentDescription = "Share summary" },
                        ) {
                            Icon(painterResource(R.drawable.ic_auto_awesome_round), contentDescription = null)
                        }
                    }
                    if (state.isGeneratingSummary && state.latestSummary == null) {
                        CircularProgressIndicator()
                    } else {
                        Text(state.latestSummary ?: "Your generated summary will appear here.", style = MaterialTheme.typography.bodyLarge)
                    }
                }
            }
            androidx.compose.material3.OutlinedTextField(
                value = refinement,
                onValueChange = { refinement = it },
                label = { Text("Modification request") },
                minLines = 3,
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
            )
            Button(
                onClick = { onRefine(refinement) },
                enabled = refinement.isNotBlank() && !state.isGeneratingSummary,
                modifier = Modifier.fillMaxWidth().height(48.dp),
                shape = ButtonShape,
            ) {
                if (state.isGeneratingSummary) CircularProgressIndicator(Modifier.height(18.dp)) else Text("Regenerate")
            }
            GradientButton("Looks Good", onClick = onConfirm)
        }
    }
}

@Composable
fun SummaryHistoryScreen(
    state: AIMemoUiState,
    onBack: () -> Unit,
    onSelectPeriod: (PeriodType) -> Unit,
    onRefresh: () -> Unit,
) {
    val filtered = remember(state.summaries, state.selectedHistoryPeriod) {
        state.summaries.filter { it.periodType == state.selectedHistoryPeriod }
    }
    val clipboard = LocalClipboardManager.current
    var expandedId by rememberSaveable { mutableStateOf<String?>(null) }
    AppScaffoldFrame(
        title = "Summary History",
        subtitle = "${filtered.size} records",
        onBack = onBack,
        trailing = { TextButton(onClick = onRefresh, enabled = !state.isLoadingHistory) { Text("Refresh") } },
    ) { padding ->
        Column(Modifier.padding(padding).fillMaxSize()) {
            Row(Modifier.padding(horizontal = 16.dp, vertical = 6.dp)) {
                PeriodSelector(selected = state.selectedHistoryPeriod, onSelect = onSelectPeriod)
            }
            if (state.isLoadingHistory && state.summaries.isEmpty()) {
                EmptyState("Loading history...")
            } else if (filtered.isEmpty()) {
                EmptyState("No summaries for this report type yet.")
            } else {
                LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    items(filtered, key = { it.id }) { summary ->
                        HistoryCard(
                            summary = summary,
                            expanded = expandedId == summary.id,
                            onToggle = { expandedId = if (expandedId == summary.id) null else summary.id },
                            onCopy = {
                                clipboard.setText(AnnotatedString(summary.output))
                            },
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun HistoryCard(summary: SummaryRecord, expanded: Boolean, onToggle: () -> Unit, onCopy: () -> Unit) {
    SoftCard(onClick = onToggle) {
        Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row {
                Column(Modifier.weight(1f)) {
                    Text(summary.periodLabel, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                    Text("${summary.periodType.title} · ${summary.tags.size} tags · ${formatDate(summary.createdAt)}", color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                IconButton(onClick = onCopy, modifier = Modifier.semantics { contentDescription = "Copy summary" }) {
                    Icon(painterResource(R.drawable.ic_content_copy_round), contentDescription = null)
                }
            }
            Text(summary.output, maxLines = if (expanded) Int.MAX_VALUE else 3, overflow = TextOverflow.Ellipsis)
            if (expanded) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Rounded.Check, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                    Text("Full content expanded", color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }
    }
}
