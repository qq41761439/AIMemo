package com.aimemo.app.ui

import android.content.Intent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Check
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.aimemo.app.R
import com.aimemo.app.domain.PeriodType
import com.aimemo.app.domain.SummaryRecord
import com.aimemo.app.domain.periodRange

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
                            Icon(androidx.compose.ui.res.painterResource(R.drawable.ic_content_copy_round), contentDescription = null)
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
                            Icon(androidx.compose.ui.res.painterResource(R.drawable.ic_auto_awesome_round), contentDescription = null)
                        }
                    }
                    if (state.isGeneratingSummary && state.latestSummary == null) {
                        CircularProgressIndicator()
                    } else {
                        Text(state.latestSummary ?: "Your generated summary will appear here.", style = MaterialTheme.typography.bodyLarge)
                    }
                }
            }
            OutlinedTextField(
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
                    Icon(androidx.compose.ui.res.painterResource(R.drawable.ic_content_copy_round), contentDescription = null)
                }
            }
            Text(summary.output, maxLines = if (expanded) Int.MAX_VALUE else 3, overflow = TextOverflow.Ellipsis)
            if (expanded) {
                Row(verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
                    Icon(Icons.Rounded.Check, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                    Text("Full content expanded", color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }
    }
}
