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
import androidx.compose.material.icons.rounded.CheckCircle
import androidx.compose.material.icons.rounded.Person
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
import androidx.compose.ui.text.style.TextAlign
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
    val selectedTags = state.selectedSummaryTags.toList()
    val totalTasks = state.summaryTasks.size
    val completedTasks = state.summaryTasks.count { it.isCompleted }
    val inProgressTasks = (totalTasks - completedTasks).coerceAtLeast(0)

    Scaffold(
        containerColor = SummaryBg,
        topBar = { PrototypeTopBar(title = "Generate Summary", onBack = onBack) },
        bottomBar = {
            Surface(color = SummaryBg) {
                GradientButton(
                    text = "Generate Summary",
                    onClick = onGenerate,
                    loading = state.isGeneratingSummary,
                    enabled = state.clientConfig?.hostedModelAvailable != false,
                    modifier = Modifier
                        .navigationBarsPadding()
                        .imePadding()
                        .padding(horizontal = 16.dp, vertical = 12.dp),
                )
            }
        },
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize(),
            contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 14.dp, bottom = 110.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            item {
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(20.dp),
                    color = Color(0xFFF5F1FF),
                    border = BorderStroke(1.dp, Color(0xFFECE4FF)),
                ) {
                    Column(Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                        Text("What would you like to summarize?", color = SummaryInk, fontSize = 22.sp, lineHeight = 28.sp, fontWeight = FontWeight.Bold)
                        SummaryChooserRow(
                            leadingIcon = R.drawable.ic_calendar_month_round,
                            title = periodHeading(state.selectedPeriod),
                            subtitle = periodRange(state.selectedPeriod).label,
                            trailing = R.drawable.ic_chevron_right_round,
                            tint = AimemoPrimary,
                        )
                        SummaryChooserRow(
                            leadingIcon = R.drawable.ic_info_outline_round,
                            title = if (selectedTags.isEmpty()) "All Tags" else selectedTags.joinToString(", "),
                            subtitle = if (selectedTags.isEmpty()) "Include everything" else "${selectedTags.size} selected",
                            trailing = R.drawable.ic_chevron_right_round,
                            tint = Color(0xFF6B7280),
                        )
                    }
                }
            }
            item {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text("Preview", color = SummaryMuted, fontSize = 22.sp, lineHeight = 26.sp, fontWeight = FontWeight.Bold)
                    Spacer(Modifier.width(10.dp))
                    Icon(painterResource(R.drawable.ic_info_outline_round), contentDescription = null, tint = Color(0xFFB4B7C6), modifier = Modifier.size(18.dp))
                }
            }
            item {
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    PreviewStatCard(value = totalTasks, label = "Tasks", modifier = Modifier.weight(1f))
                    PreviewStatCard(value = completedTasks, label = "Completed", modifier = Modifier.weight(1f))
                    PreviewStatCard(value = inProgressTasks, label = "In Progress", modifier = Modifier.weight(1f))
                }
            }
            item {
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(20.dp),
                    color = Color(0xFFF6F1FF),
                    border = BorderStroke(1.dp, Color(0xFFECE4FF)),
                ) {
                    Column(Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                            Icon(painterResource(R.drawable.ic_auto_awesome_round), contentDescription = null, tint = AimemoPrimary, modifier = Modifier.size(22.dp))
                            Text("AI will analyze your tasks and", color = SummaryInk, fontSize = 17.sp, lineHeight = 22.sp, fontWeight = FontWeight.Bold)
                        }
                        SummaryCheckLine("Summarize what you accomplished")
                        SummaryCheckLine("Highlight key insights")
                        SummaryCheckLine("Suggest next steps")
                    }
                }
            }
            if (state.availableTags.isNotEmpty()) {
                item {
                    Text("Tags", color = SummaryMuted, fontSize = 14.sp, fontWeight = FontWeight.Bold)
                    Spacer(Modifier.height(4.dp))
                    FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        state.availableTags.forEach { tag ->
                            AppFilterChip(label = tag, selected = tag in state.selectedSummaryTags, onClick = { onToggleTag(tag) })
                        }
                    }
                }
            }
            if (state.clientConfig?.hostedModelAvailable == false) {
                item {
                    StatusCard(
                        title = "Hosted model is unavailable.",
                        body = "Summary generation will be available when the backend model service is enabled.",
                    )
                }
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
    var lastSentRefinement by rememberSaveable { mutableStateOf("") }
    val summaryText = state.latestSummary.orEmpty()
    val sections = remember(summaryText) { buildSummarySections(summaryText, state) }

    Scaffold(
        containerColor = SummaryBg,
        topBar = { PrototypeTopBar(title = "Generate Summary", onBack = onBack) },
        bottomBar = {
            Column(
                Modifier
                    .fillMaxWidth()
                    .navigationBarsPadding()
                    .imePadding()
                    .padding(horizontal = 16.dp, vertical = 10.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                SummaryRefinementBar(
                    value = refinement,
                    onValueChange = { refinement = it },
                    onSend = {
                        lastSentRefinement = refinement
                        onRefine(refinement)
                    },
                    sending = state.isGeneratingSummary,
                )
                GradientButton(
                    text = "This looks good",
                    onClick = onConfirm,
                    modifier = Modifier.height(50.dp),
                )
                Text(
                    "Future weekly reports will follow this style automatically.",
                    color = SummaryMuted,
                    fontSize = 14.sp,
                    lineHeight = 18.sp,
                    modifier = Modifier.align(Alignment.CenterHorizontally),
                )
            }
        },
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize(),
            contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 12.dp, bottom = 12.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            item {
                SummaryPeriodStrip(selected = state.selectedPeriod)
            }
            item {
                SummaryChooserRow(
                    leadingIcon = R.drawable.ic_calendar_month_round,
                    title = periodRange(state.selectedPeriod).label,
                    subtitle = null,
                    trailing = R.drawable.ic_chevron_right_round,
                    tint = AimemoPrimary,
                )
            }
            item {
                SummaryChooserRow(
                    leadingIcon = R.drawable.ic_info_outline_round,
                    title = if (state.selectedSummaryTags.isEmpty()) "All Tags" else state.selectedSummaryTags.joinToString(", "),
                    subtitle = null,
                    trailing = R.drawable.ic_chevron_right_round,
                    tint = Color(0xFF6B7280),
                )
            }
            item {
                SummaryReportCard(
                    summaryText = summaryText,
                    sections = sections,
                    onCopy = { clipboard.setText(AnnotatedString(summaryText)) },
                )
            }
            if (lastSentRefinement.isNotBlank()) {
                item {
                    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        ChatBubble(
                            text = lastSentRefinement,
                            mine = true,
                            time = nowClockString(),
                        )
                        ChatBubble(
                            text = refinementReply(summaryText),
                            mine = false,
                            time = nowClockString(),
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun SummaryHistoryScreen(
    state: AIMemoUiState,
    onBack: () -> Unit,
    onOpenProfile: () -> Unit,
    onSelectPeriod: (PeriodType) -> Unit,
    onRefresh: () -> Unit,
) {
    val filtered = remember(state.summaries, state.selectedHistoryPeriod) {
        state.summaries.filter { it.periodType == state.selectedHistoryPeriod }
    }
    val clipboard = LocalClipboardManager.current
    val context = LocalContext.current
    var expandedId by rememberSaveable { mutableStateOf<String?>(filtered.firstOrNull()?.id) }
    Scaffold(
        containerColor = SummaryBg,
        topBar = {
            Column {
                SummaryTabsHeader(
                    selected = "Summary",
                    onTasks = { },
                    onSummary = { },
                    onProfile = onOpenProfile,
                )
                Text(
                    "Summary History",
                    modifier = Modifier.padding(start = 16.dp, top = 18.dp, bottom = 12.dp),
                    color = SummaryInk,
                    fontSize = 28.sp,
                    lineHeight = 34.sp,
                    fontWeight = FontWeight.Bold,
                )
            }
        },
        bottomBar = {
            if (!state.isLoadingHistory) {
                TextButton(
                    onClick = onRefresh,
                    modifier = Modifier
                        .fillMaxWidth()
                        .navigationBarsPadding()
                        .padding(horizontal = 16.dp, vertical = 10.dp),
                ) {
                    Text("Refresh")
                }
            }
        },
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize(),
            contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 8.dp, bottom = 88.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            item {
                SummaryPeriodStrip(
                    selected = state.selectedHistoryPeriod,
                    onSelect = onSelectPeriod,
                )
            }
            if (state.isLoadingHistory && state.summaries.isEmpty()) {
                item { EmptyState("Loading history...", Modifier.height(220.dp)) }
            } else if (filtered.isEmpty()) {
                item { EmptyState("No summaries for this report type yet.", Modifier.height(220.dp)) }
            } else {
                items(filtered, key = { it.id }) { summary ->
                    SummaryHistoryCard(
                        summary = summary,
                        expanded = expandedId == summary.id,
                        onToggle = { expandedId = if (expandedId == summary.id) null else summary.id },
                        onCopy = { clipboard.setText(AnnotatedString(summary.output)) },
                        onShare = {
                            context.startActivity(
                                Intent(Intent.ACTION_SEND).apply {
                                    type = "text/plain"
                                    putExtra(Intent.EXTRA_TEXT, summary.output)
                                }.let { Intent.createChooser(it, "Share summary") }
                            )
                        },
                    )
                }
            }
        }
    }
}

@Composable
private fun PrototypeTopBar(title: String, onBack: () -> Unit) {
    Surface(color = SummaryBg) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(start = 12.dp, end = 12.dp, top = 48.dp, bottom = 18.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            IconButton(
                onClick = onBack,
                modifier = Modifier.size(48.dp).semantics { contentDescription = "Back" },
            ) {
                Icon(
                    painterResource(R.drawable.ic_chevron_right_round),
                    contentDescription = null,
                    tint = SummaryInk,
                    modifier = Modifier.size(34.dp).rotate(180f),
                )
            }
            Text(
                title,
                modifier = Modifier.weight(1f),
                color = SummaryInk,
                fontSize = 26.sp,
                lineHeight = 32.sp,
                fontWeight = FontWeight.Bold,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center,
            )
            Spacer(Modifier.size(48.dp))
        }
    }
}

@Composable
private fun SummaryChooserRow(
    leadingIcon: Int,
    title: String,
    subtitle: String?,
    trailing: Int,
    tint: Color,
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(18.dp),
        color = Color.White,
        border = BorderStroke(1.dp, SummaryLine),
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 18.dp, vertical = 16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Surface(shape = RoundedCornerShape(16.dp), color = Color(0xFFF0EAFF)) {
                Box(Modifier.size(64.dp), contentAlignment = Alignment.Center) {
                    Icon(painterResource(leadingIcon), contentDescription = null, tint = tint, modifier = Modifier.size(28.dp))
                }
            }
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(title, color = SummaryInk, fontSize = 18.sp, lineHeight = 22.sp, fontWeight = FontWeight.Bold)
                if (subtitle != null) {
                    Text(subtitle, color = SummaryMuted, fontSize = 15.sp, lineHeight = 18.sp)
                }
            }
            Icon(painterResource(trailing), contentDescription = null, tint = Color(0xFF5B6173), modifier = Modifier.size(30.dp))
        }
    }
}

@Composable
private fun PreviewStatCard(value: Int, label: String, modifier: Modifier = Modifier) {
    Surface(
        modifier = modifier.height(116.dp),
        shape = RoundedCornerShape(20.dp),
        color = Color.White,
        border = BorderStroke(1.dp, SummaryLine),
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text(value.toString(), color = SummaryInk, fontSize = 40.sp, lineHeight = 42.sp, fontWeight = FontWeight.Bold)
            Text(label, color = SummaryMuted, fontSize = 16.sp, lineHeight = 20.sp, fontWeight = FontWeight.Medium)
        }
    }
}

@Composable
private fun SummaryCheckLine(text: String) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        Icon(Icons.Rounded.Check, contentDescription = null, tint = Color(0xFF7C88A4), modifier = Modifier.size(22.dp))
        Text(text, color = SummaryMuted, fontSize = 17.sp, lineHeight = 22.sp)
    }
}

@Composable
private fun SummaryPeriodStrip(
    selected: PeriodType,
    onSelect: ((PeriodType) -> Unit)? = null,
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(18.dp),
        color = Color.White,
        border = BorderStroke(1.dp, SummaryLine),
    ) {
        Row(modifier = Modifier.padding(4.dp)) {
            PeriodType.entries.forEach { type ->
                val active = type == selected
                Surface(
                    modifier = Modifier
                        .weight(1f)
                        .height(42.dp)
                        .clickable(enabled = onSelect != null) { onSelect?.invoke(type) },
                    shape = RoundedCornerShape(14.dp),
                    color = if (active) AimemoPrimary else Color.Transparent,
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Text(
                            type.name.replaceFirstChar { it.uppercase() },
                            color = if (active) Color.White else SummaryMuted,
                            fontSize = 16.sp,
                            lineHeight = 20.sp,
                            fontWeight = FontWeight.Bold,
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun SummaryRefinementBar(
    value: String,
    onValueChange: (String) -> Unit,
    onSend: () -> Unit,
    sending: Boolean,
) {
    Surface(
        shape = RoundedCornerShape(18.dp),
        color = Color.White,
        border = BorderStroke(1.dp, SummaryLine),
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(Modifier.weight(1f)) {
                if (value.isBlank()) {
                    Text("Tell AI how to adjust this report...", color = Color(0xFFA0A5B8), fontSize = 16.sp)
                }
                BasicTextField(
                    value = value,
                    onValueChange = onValueChange,
                    singleLine = true,
                    textStyle = TextStyle(color = SummaryInk, fontSize = 16.sp),
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
                    .background(SummaryGradient)
                    .clickable(enabled = value.isNotBlank() && !sending, onClick = onSend),
                contentAlignment = Alignment.Center,
            ) {
                if (sending) {
                    CircularProgressIndicator(Modifier.size(18.dp), strokeWidth = 2.dp, color = Color.White)
                } else {
                    Icon(painterResource(R.drawable.ic_send_round), contentDescription = null, tint = Color.White, modifier = Modifier.size(24.dp))
                }
            }
        }
    }
}

@Composable
private fun SummaryReportCard(
    summaryText: String,
    sections: List<SummarySection>,
    onCopy: () -> Unit,
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        color = Color.White,
        border = BorderStroke(1.dp, SummaryLine),
    ) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Row(verticalAlignment = Alignment.Top) {
                Surface(shape = RoundedCornerShape(999.dp), color = Color(0xFFF1E8FF)) {
                    Row(
                        modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp),
                    ) {
                        Icon(painterResource(R.drawable.ic_auto_awesome_round), contentDescription = null, tint = AimemoPrimary, modifier = Modifier.size(17.dp))
                        Text("AI-generated", color = AimemoPrimary, fontSize = 13.sp, lineHeight = 16.sp, fontWeight = FontWeight.Medium)
                    }
                }
                Spacer(Modifier.weight(1f))
                IconButton(onClick = onCopy, modifier = Modifier.size(36.dp).semantics { contentDescription = "Copy summary" }) {
                    Icon(painterResource(R.drawable.ic_content_copy_round), contentDescription = null, tint = AimemoPrimary, modifier = Modifier.size(22.dp))
                }
            }
            sections.forEachIndexed { index, section ->
                SummarySectionRow(section = section, divider = index != sections.lastIndex)
            }
            if (summaryText.isBlank()) {
                Text("Your generated summary will appear here.", color = SummaryMuted)
            }
        }
    }
}

@Composable
private fun SummarySectionRow(section: SummarySection, divider: Boolean) {
    Column {
        Row(verticalAlignment = Alignment.Top, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
            Surface(shape = RoundedCornerShape(14.dp), color = Color(0xFFF1E8FF)) {
                Box(Modifier.size(42.dp), contentAlignment = Alignment.Center) {
                    Icon(painterResource(section.icon), contentDescription = null, tint = AimemoPrimary, modifier = Modifier.size(24.dp))
                }
            }
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(section.title, color = SummaryInk, fontSize = 17.sp, lineHeight = 21.sp, fontWeight = FontWeight.Bold)
                section.items.forEach { item ->
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.Top) {
                        Text("•", color = AimemoPrimary, fontSize = 16.sp, lineHeight = 22.sp)
                        Text(item, color = SummaryMuted, fontSize = 15.sp, lineHeight = 20.sp)
                    }
                }
            }
            Icon(painterResource(R.drawable.ic_chevron_right_round), contentDescription = null, tint = Color(0xFF77809A), modifier = Modifier.size(28.dp))
        }
        if (divider) {
            Spacer(Modifier.height(12.dp))
            HorizontalDivider(color = SummaryLine, thickness = 1.dp)
            Spacer(Modifier.height(12.dp))
        } else {
            Spacer(Modifier.height(4.dp))
        }
    }
}

@Composable
private fun ChatBubble(text: String, mine: Boolean, time: String) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = if (mine) Arrangement.End else Arrangement.Start,
        verticalAlignment = Alignment.Bottom,
    ) {
        if (!mine) {
            Surface(shape = CircleShape, color = Color(0xFFF1E8FF)) {
                Box(Modifier.size(42.dp), contentAlignment = Alignment.Center) {
                    Icon(painterResource(R.drawable.ic_auto_awesome_round), contentDescription = null, tint = AimemoPrimary, modifier = Modifier.size(22.dp))
                }
            }
            Spacer(Modifier.width(10.dp))
        }
        Surface(
            shape = RoundedCornerShape(18.dp),
            color = if (mine) Color(0xFFEDE3FF) else Color.White,
            border = BorderStroke(1.dp, SummaryLine),
        ) {
            Column(
                modifier = Modifier.padding(horizontal = 14.dp, vertical = 12.dp),
                verticalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                Text(text, color = SummaryInk, fontSize = 15.sp, lineHeight = 19.sp)
                Text(time, color = SummaryMuted, fontSize = 12.sp)
            }
        }
    }
}

@Composable
private fun SummaryHistoryCard(
    summary: SummaryRecord,
    expanded: Boolean,
    onToggle: () -> Unit,
    onCopy: () -> Unit,
    onShare: () -> Unit,
) {
    val sections = remember(summary.output) { buildSummarySections(summary.output, null, summary) }
    val tasksSection = sections.lastOrNull()
    val cardColor = when (summary.periodType) {
        PeriodType.Daily -> Color(0xFFE9F2FF)
        PeriodType.Weekly -> Color(0xFFE9F8EF)
        PeriodType.Monthly, PeriodType.Yearly -> Color(0xFFFFEFE6)
        PeriodType.Custom -> Color(0xFFF0EAFE)
    }
    val accent = when (summary.periodType) {
        PeriodType.Daily -> Color(0xFF2563EB)
        PeriodType.Weekly -> Color(0xFF16A05B)
        PeriodType.Monthly, PeriodType.Yearly -> Color(0xFFF97316)
        PeriodType.Custom -> Color(0xFF6D45D9)
    }
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        color = Color.White,
        border = BorderStroke(1.dp, SummaryLine),
    ) {
        Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Row(verticalAlignment = Alignment.Top, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                Surface(shape = RoundedCornerShape(16.dp), color = cardColor) {
                    Box(Modifier.size(60.dp), contentAlignment = Alignment.Center) {
                        Icon(painterResource(R.drawable.ic_calendar_month_round), contentDescription = null, tint = accent, modifier = Modifier.size(30.dp))
                    }
                }
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Surface(shape = RoundedCornerShape(999.dp), color = cardColor) {
                        Text(summary.periodType.title, modifier = Modifier.padding(horizontal = 10.dp, vertical = 5.dp), color = accent, fontSize = 13.sp, fontWeight = FontWeight.Bold)
                    }
                    Text(summary.periodLabel, color = SummaryInk, fontSize = 17.sp, lineHeight = 21.sp, fontWeight = FontWeight.Bold)
                    Text("${summary.tags.size} tasks  •  Generated ${formatDate(summary.createdAt)}", color = SummaryMuted, fontSize = 14.sp)
                    if (expanded) {
                        Text(summary.output.take(120), color = SummaryMuted, fontSize = 14.sp, lineHeight = 19.sp)
                    }
                }
                IconButton(onClick = onToggle, modifier = Modifier.size(40.dp)) {
                    Icon(
                        painterResource(R.drawable.ic_chevron_right_round),
                        contentDescription = null,
                        tint = Color(0xFF6E7486),
                        modifier = Modifier.rotate(if (expanded) -90f else 90f).size(26.dp),
                    )
                }
            }
            if (expanded) {
                sections.take(4).forEachIndexed { index, section ->
                    SummaryHistorySectionRow(section = section, divider = index != minOf(3, sections.lastIndex))
                }
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    OutlinedActionButton("Copy", onCopy, modifier = Modifier.weight(1f))
                    GradientActionButton("Share", onShare, modifier = Modifier.weight(1f))
                }
            }
        }
    }
}

@Composable
private fun SummaryHistorySectionRow(section: SummarySection, divider: Boolean) {
    Column {
        Row(verticalAlignment = Alignment.Top, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Surface(shape = RoundedCornerShape(14.dp), color = Color(0xFFF1E8FF)) {
                Box(Modifier.size(40.dp), contentAlignment = Alignment.Center) {
                    Icon(painterResource(section.icon), contentDescription = null, tint = AimemoPrimary, modifier = Modifier.size(22.dp))
                }
            }
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(section.title, color = SummaryInk, fontSize = 16.sp, lineHeight = 20.sp, fontWeight = FontWeight.Bold)
                Text(section.summary, color = SummaryMuted, fontSize = 14.sp, lineHeight = 18.sp)
            }
            Icon(painterResource(R.drawable.ic_chevron_right_round), contentDescription = null, tint = Color(0xFF6E7486), modifier = Modifier.size(26.dp))
        }
        if (divider) {
            Spacer(Modifier.height(10.dp))
            HorizontalDivider(color = SummaryLine, thickness = 1.dp)
            Spacer(Modifier.height(10.dp))
        } else {
            Spacer(Modifier.height(6.dp))
        }
    }
}

@Composable
private fun OutlinedActionButton(text: String, onClick: () -> Unit, modifier: Modifier = Modifier) {
    Surface(
        modifier = modifier.height(44.dp).clickable(onClick = onClick),
        shape = RoundedCornerShape(12.dp),
        color = Color.White,
        border = BorderStroke(1.2.dp, AimemoPrimary),
    ) {
        Box(contentAlignment = Alignment.Center) {
            Text(text, color = AimemoPrimary, fontSize = 15.sp, fontWeight = FontWeight.Bold)
        }
    }
}

@Composable
private fun GradientActionButton(text: String, onClick: () -> Unit, modifier: Modifier = Modifier) {
    Surface(
        modifier = modifier.height(44.dp).clickable(onClick = onClick),
        shape = RoundedCornerShape(12.dp),
        color = Color.Transparent,
    ) {
        Box(
            modifier = Modifier
                .background(SummaryGradient)
                .fillMaxSize(),
            contentAlignment = Alignment.Center,
        ) {
            Text(text, color = Color.White, fontSize = 15.sp, fontWeight = FontWeight.Bold)
        }
    }
}

private data class SummarySection(
    val icon: Int,
    val title: String,
    val summary: String,
    val items: List<String>,
)

private fun periodHeading(periodType: PeriodType): String =
    when (periodType) {
        PeriodType.Daily -> "This Day"
        PeriodType.Weekly -> "This Week"
        PeriodType.Monthly -> "This Month"
        PeriodType.Yearly -> "This Year"
        PeriodType.Custom -> "Custom Range"
    }

private fun buildSummarySections(summaryText: String, state: AIMemoUiState?, summaryRecord: SummaryRecord? = null): List<SummarySection> {
    val rawLines = summaryText.lineSequence().map { it.trim() }.filter { it.isNotBlank() }.toList()
    val source = if (rawLines.isNotEmpty()) rawLines else listOf(summaryText.ifBlank { "No summary available." })
    val buckets = source.chunked((source.size + 2) / 3.coerceAtLeast(1))
    val labels = listOf("What I completed", "Key outcomes", "Next steps")
    val icons = listOf(R.drawable.ic_check_circle_round, R.drawable.ic_auto_awesome_round, R.drawable.ic_info_outline_round)
    return labels.mapIndexed { index, label ->
        val items = buckets.getOrNull(index)?.take(3)?.map { it.trimStart('-', '•', ' ') }?.filter { it.isNotBlank() }
            ?: listOf(source.first())
        SummarySection(
            icon = icons[index],
            title = label,
            summary = items.firstOrNull().orEmpty(),
            items = items.take(3),
        )
    } + SummarySection(
        icon = R.drawable.ic_history_round,
        title = "Included tasks",
        summary = when {
            summaryRecord != null -> "${summaryRecord.tags.size} tasks across ${summaryRecord.tags.joinToString(", ").ifBlank { "all tags" }}."
            state != null -> "${state.summaryTasks.size} tasks across selected tags."
            else -> "Task list for this summary."
        },
        items = summaryRecord?.tags?.take(10)?.ifEmpty { listOf("All tasks") }
            ?: state?.summaryTasks?.take(10)?.map { it.title }?.ifEmpty { listOf("All tasks") }
            ?: listOf("All tasks"),
    )
}

private fun refinementReply(summaryText: String): String =
    summaryText.lineSequence().firstOrNull()?.takeIf { it.isNotBlank() }
        ?: "Updated the summary to be shorter and more outcome-focused."

private fun nowClockString(): String =
    java.time.format.DateTimeFormatter.ofPattern("h:mm a").format(java.time.LocalTime.now())
