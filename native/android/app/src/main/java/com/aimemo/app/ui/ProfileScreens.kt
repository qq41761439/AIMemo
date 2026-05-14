package com.aimemo.app.ui

import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.aimemo.app.R

@Composable
fun ProfileScreen(
    state: AIMemoUiState,
    onBack: () -> Unit,
    onSettings: () -> Unit,
    onHistory: () -> Unit,
    onLogout: () -> Unit,
    onComingSoon: (String) -> Unit,
) {
    var confirmLogout by rememberSaveable { mutableStateOf(false) }
    AppScaffoldFrame(title = "Profile", subtitle = "Account and activity", onBack = onBack) { padding ->
        Column(
            Modifier
                .padding(padding)
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            SoftCard {
                Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                    Image(
                        painterResource(R.drawable.portrait),
                        contentDescription = null,
                        modifier = Modifier.size(72.dp).clip(CircleShape),
                        contentScale = ContentScale.Crop,
                    )
                    Column(Modifier.weight(1f)) {
                        Text("AIMemo Account", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                        Text(state.user?.email ?: "Not signed in", color = MaterialTheme.colorScheme.onSurfaceVariant, maxLines = 1, overflow = TextOverflow.Ellipsis)
                    }
                }
            }
            QuotaCard(state)
            MenuCard {
                MenuRow("Summary History", R.drawable.ic_history_round, onHistory)
                MenuRow("Settings", R.drawable.ic_security_round, onSettings)
                MenuRow("Notifications", R.drawable.ic_notifications_round) { onComingSoon("Notifications") }
                MenuRow("Help & Feedback", R.drawable.ic_help_outline_round) { onComingSoon("Help & Feedback") }
            }
            Button(onClick = { confirmLogout = true }, modifier = Modifier.fillMaxWidth().height(52.dp)) {
                Icon(painterResource(R.drawable.ic_logout_round), contentDescription = null)
                Spacer(Modifier.size(8.dp))
                Text("Log Out")
            }
        }
    }
    if (confirmLogout) {
        AlertDialog(
            onDismissRequest = { confirmLogout = false },
            title = { Text("Log out") },
            text = { Text("This will clear the current account session on this device.") },
            confirmButton = {
                Button(onClick = { confirmLogout = false; onLogout() }) { Text("Log Out") }
            },
            dismissButton = { TextButton(onClick = { confirmLogout = false }) { Text("Cancel") } },
        )
    }
}

@Composable
fun SettingsScreen(onBack: () -> Unit, onComingSoon: (String) -> Unit) {
    AppScaffoldFrame(title = "Settings", subtitle = "Account, sync, privacy and help", onBack = onBack) { padding ->
        Column(
            Modifier
                .padding(padding)
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            MenuCard {
                MenuRow("Account Settings", R.drawable.ic_security_round) { onComingSoon("Account Settings") }
                MenuRow("Sync Options", R.drawable.ic_auto_awesome_round) { onComingSoon("Sync Options") }
                MenuRow("Privacy", R.drawable.ic_security_round) { onComingSoon("Privacy") }
                MenuRow("Help", R.drawable.ic_help_outline_round) { onComingSoon("Help") }
                MenuRow("About AIMemo", R.drawable.ic_info_outline_round) { onComingSoon("About AIMemo") }
            }
            Text(
                "Custom model API keys are not part of the first Android app flow.",
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                style = MaterialTheme.typography.bodySmall,
            )
        }
    }
}

@Composable
private fun QuotaCard(state: AIMemoUiState) {
    val limit = state.quota?.limit ?: state.clientConfig?.monthlyFreeSummaryLimit ?: 0
    val remaining = state.quota?.remaining ?: limit
    val progress = if (limit > 0) (remaining.toFloat() / limit.toFloat()).coerceIn(0f, 1f) else 0f
    SoftCard {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Text("Free Summary Credits", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
            Text("$remaining / ${if (limit > 0) limit else "--"} remaining", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
            LinearProgressIndicator(progress = { progress }, modifier = Modifier.fillMaxWidth().height(8.dp).clip(androidx.compose.foundation.shape.RoundedCornerShape(999.dp)))
        }
    }
}

@Composable
private fun MenuCard(content: @Composable () -> Unit) {
    SoftCard {
        Column(Modifier.padding(vertical = 4.dp)) {
            content()
        }
    }
}

@Composable
private fun MenuRow(title: String, icon: Int, onClick: () -> Unit) {
    Row(
        Modifier
            .fillMaxWidth()
            .height(58.dp)
            .clickable(onClick = onClick)
            .padding(horizontal = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        IconBubble(icon, Modifier.size(42.dp))
        Text(title, modifier = Modifier.weight(1f), fontWeight = FontWeight.Medium)
        Icon(
            painterResource(R.drawable.ic_chevron_right_round),
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
    HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant)
}
