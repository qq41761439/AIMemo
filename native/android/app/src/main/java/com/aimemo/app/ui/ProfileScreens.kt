package com.aimemo.app.ui

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.rounded.Edit
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
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
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.aimemo.app.R
import com.aimemo.app.ui.theme.AimemoPrimary

private val ProfileBg = Color(0xFFFCFBFF)
private val ProfileInk = Color(0xFF080C1B)
private val ProfileMuted = Color(0xFF7B8094)
private val ProfileLine = Color(0xFFE8E6EF)
private val ProfilePurpleSoft = Color(0xFFF1EAFE)
private val ProfileDanger = Color(0xFFFF2D2D)
private val ProfileSuccess = Color(0xFF23B26B)

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
    Scaffold(
        containerColor = ProfileBg,
        topBar = { CenterTitleBar(title = "Me") },
    ) { padding ->
        Column(
            Modifier
                .padding(padding)
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .navigationBarsPadding()
                .padding(horizontal = 16.dp, vertical = 18.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            AccountCard(state = state, showManage = false, onManage = { onComingSoon("Profile editing") })
            CreditsCard(state = state, onUpgrade = { onComingSoon("Upgrade") })
            ProfileMenuGroup {
                ProfileMenuRow("Summary history", R.drawable.ic_history_round, onHistory)
                ProfileMenuRow("Notifications & sync", R.drawable.ic_notifications_round) { onComingSoon("Notifications & sync") }
                ProfileMenuRow("Privacy & security", R.drawable.ic_security_round, onSettings)
                ProfileMenuRow("Help", R.drawable.ic_help_outline_round) { onComingSoon("Help") }
                ProfileMenuRow("About AIMemo", R.drawable.ic_info_outline_round) { onComingSoon("About AIMemo") }
            }
            SignOutButton { confirmLogout = true }
        }
    }
    if (confirmLogout) {
        AlertDialog(
            onDismissRequest = { confirmLogout = false },
            title = { Text("Sign out") },
            text = { Text("This will clear the current account session on this device.") },
            confirmButton = {
                Button(onClick = { confirmLogout = false; onLogout() }) { Text("Sign out") }
            },
            dismissButton = { TextButton(onClick = { confirmLogout = false }) { Text("Cancel") } },
        )
    }
}

@Composable
fun SettingsScreen(onBack: () -> Unit, onComingSoon: (String) -> Unit) {
    var confirmLogout by rememberSaveable { mutableStateOf(false) }
    Scaffold(
        containerColor = ProfileBg,
        topBar = { CenterTitleBar(title = "Settings", onBack = onBack) },
    ) { padding ->
        Column(
            Modifier
                .padding(padding)
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .navigationBarsPadding()
                .padding(horizontal = 16.dp, vertical = 18.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            SettingsAccountCard(onManage = { onComingSoon("Manage account") })
            ProfileMenuGroup {
                ProfileMenuRow("Notifications", R.drawable.ic_notifications_round) { onComingSoon("Notifications") }
                ProfileMenuRow("Sync", R.drawable.ic_history_round) { onComingSoon("Sync") }
                ProfileMenuRow("Privacy", R.drawable.ic_security_round) { onComingSoon("Privacy") }
                ProfileMenuRow("Security", R.drawable.ic_security_round) { onComingSoon("Security") }
                ProfileMenuRow("Appearance", R.drawable.ic_auto_awesome_round) { onComingSoon("Appearance") }
                ProfileMenuRow("Language", R.drawable.ic_info_outline_round) { onComingSoon("Language") }
            }
            ProfileMenuGroup(header = "Support & about") {
                ProfileMenuRow("Help center", R.drawable.ic_help_outline_round) { onComingSoon("Help center") }
                ProfileMenuRow("Send feedback", R.drawable.ic_info_outline_round) { onComingSoon("Send feedback") }
                ProfileMenuRow("Rate AIMemo", R.drawable.ic_auto_awesome_round) { onComingSoon("Rate AIMemo") }
                ProfileMenuRow("About AIMemo", R.drawable.ic_info_outline_round) { onComingSoon("About AIMemo") }
                VersionRow()
            }
            SignOutButton { confirmLogout = true }
        }
    }
    if (confirmLogout) {
        AlertDialog(
            onDismissRequest = { confirmLogout = false },
            title = { Text("Sign out") },
            text = { Text("This will clear the current account session on this device.") },
            confirmButton = {
                Button(onClick = { confirmLogout = false; onComingSoon("Sign out") }) { Text("Sign out") }
            },
            dismissButton = { TextButton(onClick = { confirmLogout = false }) { Text("Cancel") } },
        )
    }
}

@Composable
private fun CenterTitleBar(title: String, onBack: (() -> Unit)? = null) {
    Surface(color = ProfileBg) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 48.dp, bottom = 20.dp),
        ) {
            if (onBack != null) {
                androidx.compose.material3.IconButton(
                    onClick = onBack,
                    modifier = Modifier
                        .align(Alignment.CenterStart)
                        .padding(start = 8.dp)
                        .size(48.dp),
                ) {
                    Icon(Icons.AutoMirrored.Rounded.ArrowBack, contentDescription = "Back", tint = AimemoPrimary, modifier = Modifier.size(32.dp))
                }
            }
            Text(
                title,
                modifier = Modifier.align(Alignment.Center),
                color = ProfileInk,
                fontSize = 27.sp,
                lineHeight = 32.sp,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center,
            )
        }
    }
}

@Composable
private fun AccountCard(state: AIMemoUiState, showManage: Boolean, onManage: () -> Unit) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .height(140.dp)
            .shadow(8.dp, RoundedCornerShape(18.dp), ambientColor = Color(0x10000000), spotColor = Color(0x16000000)),
        shape = RoundedCornerShape(18.dp),
        color = Color.White,
        border = BorderStroke(1.dp, ProfileLine),
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 18.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Portrait(92.dp)
            Spacer(Modifier.width(18.dp))
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text("Alex Morgan", color = ProfileInk, fontSize = 27.sp, lineHeight = 32.sp, fontWeight = FontWeight.Bold, maxLines = 1, overflow = TextOverflow.Ellipsis)
                Text(state.user?.email ?: "alex.morgan@example.com", color = ProfileMuted, fontSize = 18.sp, lineHeight = 22.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
                if (showManage) {
                    Text(
                        "Manage account",
                        modifier = Modifier.clickable(onClick = onManage),
                        color = AimemoPrimary,
                        fontSize = 17.sp,
                        fontWeight = FontWeight.Medium,
                    )
                } else {
                    Surface(shape = RoundedCornerShape(999.dp), color = Color(0xFFE5F6EB)) {
                        Row(
                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(6.dp),
                        ) {
                            Icon(painterResource(R.drawable.ic_check_circle_round), contentDescription = null, tint = ProfileSuccess, modifier = Modifier.size(18.dp))
                            Text("Synced", color = ProfileSuccess, fontSize = 16.sp, lineHeight = 18.sp, fontWeight = FontWeight.Bold)
                        }
                    }
                }
            }
            Surface(
                modifier = Modifier.size(58.dp).clickable(onClick = onManage),
                shape = CircleShape,
                color = ProfilePurpleSoft,
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(Icons.Rounded.Edit, contentDescription = "Edit profile", tint = AimemoPrimary, modifier = Modifier.size(28.dp))
                }
            }
        }
    }
}

@Composable
private fun SettingsAccountCard(onManage: () -> Unit) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .height(132.dp)
            .shadow(7.dp, RoundedCornerShape(18.dp), ambientColor = Color(0x10000000), spotColor = Color(0x14000000)),
        shape = RoundedCornerShape(18.dp),
        color = Color.White,
        border = BorderStroke(1.dp, ProfileLine),
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 18.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Portrait(82.dp)
            Spacer(Modifier.width(18.dp))
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text("Alex Morgan", color = ProfileInk, fontSize = 22.sp, lineHeight = 27.sp, fontWeight = FontWeight.Bold)
                Text("alex.morgan@example.com", color = ProfileMuted, fontSize = 16.sp, lineHeight = 20.sp)
                Text("Manage account", modifier = Modifier.clickable(onClick = onManage), color = AimemoPrimary, fontSize = 16.sp, fontWeight = FontWeight.Medium)
            }
            Icon(painterResource(R.drawable.ic_chevron_right_round), contentDescription = null, tint = AimemoPrimary, modifier = Modifier.size(30.dp))
        }
    }
}

@Composable
private fun Portrait(size: androidx.compose.ui.unit.Dp) {
    Image(
        painterResource(R.drawable.portrait),
        contentDescription = null,
        modifier = Modifier.size(size).clip(CircleShape),
        contentScale = ContentScale.Crop,
    )
}

@Composable
private fun CreditsCard(state: AIMemoUiState, onUpgrade: () -> Unit) {
    val limit = state.quota?.limit ?: state.clientConfig?.monthlyFreeSummaryLimit ?: 1000
    val remaining = state.quota?.remaining ?: 720
    val used = (limit - remaining).coerceAtLeast(0)
    val progress = if (limit > 0) (used.toFloat() / limit.toFloat()).coerceIn(0f, 1f) else 0.72f
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .height(116.dp)
            .shadow(7.dp, RoundedCornerShape(18.dp), ambientColor = Color(0x10000000), spotColor = Color(0x14000000)),
        shape = RoundedCornerShape(18.dp),
        color = Color.White,
        border = BorderStroke(1.dp, ProfileLine),
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 18.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            ProfileIconBubble(R.drawable.ic_auto_awesome_round, Modifier.size(58.dp))
            Spacer(Modifier.width(18.dp))
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text("Free credits", color = ProfileInk, fontSize = 18.sp, lineHeight = 22.sp)
                Row(verticalAlignment = Alignment.Bottom) {
                    Text(remaining.toString(), color = AimemoPrimary, fontSize = 32.sp, lineHeight = 34.sp, fontWeight = FontWeight.Bold)
                    Text(" / ${if (limit > 0) limit else "--"}", color = ProfileMuted, fontSize = 24.sp, lineHeight = 30.sp)
                }
                LinearProgressIndicator(
                    progress = { progress },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(8.dp)
                        .clip(RoundedCornerShape(999.dp)),
                    color = AimemoPrimary,
                    trackColor = Color(0xFFEFE8FF),
                )
            }
            Spacer(Modifier.width(18.dp))
            Surface(
                modifier = Modifier
                    .height(52.dp)
                    .width(110.dp)
                    .clickable(onClick = onUpgrade),
                shape = RoundedCornerShape(16.dp),
                color = Color.White,
                border = BorderStroke(1.dp, AimemoPrimary),
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Text("Upgrade", color = AimemoPrimary, fontSize = 18.sp, fontWeight = FontWeight.Bold)
                }
            }
        }
    }
}

@Composable
private fun ProfileMenuGroup(header: String? = null, content: @Composable () -> Unit) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(7.dp, RoundedCornerShape(18.dp), ambientColor = Color(0x10000000), spotColor = Color(0x14000000)),
        shape = RoundedCornerShape(18.dp),
        color = Color.White,
        border = BorderStroke(1.dp, ProfileLine),
    ) {
        Column(Modifier.padding(horizontal = 18.dp, vertical = 10.dp)) {
            if (header != null) {
                Text(header, color = ProfileMuted, fontSize = 16.sp, lineHeight = 20.sp, modifier = Modifier.padding(top = 4.dp, bottom = 6.dp))
            }
            content()
        }
    }
}

@Composable
private fun ProfileMenuRow(title: String, icon: Int, onClick: () -> Unit) {
    Row(
        Modifier
            .fillMaxWidth()
            .height(64.dp)
            .clickable(onClick = onClick),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        ProfileIconBubble(icon, Modifier.size(46.dp))
        Spacer(Modifier.width(18.dp))
        Text(title, modifier = Modifier.weight(1f), color = ProfileInk, fontSize = 19.sp, lineHeight = 24.sp, fontWeight = FontWeight.Medium)
        Icon(painterResource(R.drawable.ic_chevron_right_round), contentDescription = null, tint = Color(0xFF7D8396), modifier = Modifier.size(30.dp))
    }
    HorizontalDivider(color = ProfileLine, thickness = 1.dp)
}

@Composable
private fun VersionRow() {
    Row(
        Modifier
            .fillMaxWidth()
            .height(64.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Surface(shape = RoundedCornerShape(10.dp), color = ProfilePurpleSoft) {
            Box(Modifier.size(46.dp), contentAlignment = Alignment.Center) {
                Text("1.0", color = AimemoPrimary, fontSize = 16.sp, fontWeight = FontWeight.Medium)
            }
        }
        Spacer(Modifier.width(18.dp))
        Text("Version 1.0.0", modifier = Modifier.weight(1f), color = ProfileInk, fontSize = 19.sp, lineHeight = 24.sp)
    }
}

@Composable
private fun ProfileIconBubble(icon: Int, modifier: Modifier = Modifier) {
    Surface(modifier = modifier, shape = RoundedCornerShape(12.dp), color = ProfilePurpleSoft) {
        Box(contentAlignment = Alignment.Center) {
            Icon(painterResource(icon), contentDescription = null, tint = AimemoPrimary, modifier = Modifier.size(27.dp))
        }
    }
}

@Composable
private fun SignOutButton(onClick: () -> Unit) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .height(58.dp)
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(16.dp),
        color = Color.White,
        border = BorderStroke(1.dp, ProfileDanger),
    ) {
        Row(horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically) {
            Icon(painterResource(R.drawable.ic_logout_round), contentDescription = null, tint = ProfileDanger, modifier = Modifier.size(24.dp))
            Spacer(Modifier.width(12.dp))
            Text("Sign out", color = ProfileDanger, fontSize = 20.sp, lineHeight = 24.sp, fontWeight = FontWeight.Bold)
        }
    }
}
