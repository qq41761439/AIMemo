package com.aimemo.app.ui

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.rounded.CheckCircle
import androidx.compose.material.icons.rounded.Info
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.aimemo.app.R
import com.aimemo.app.domain.PeriodType
import com.aimemo.app.ui.theme.AimemoPrimary
import com.aimemo.app.ui.theme.AimemoPrimaryEnd
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter

val AppGradient = Brush.horizontalGradient(listOf(AimemoPrimary, AimemoPrimaryEnd))
val CardShape = RoundedCornerShape(14.dp)
val ButtonShape = RoundedCornerShape(14.dp)

@Composable
fun AppScaffoldFrame(
    title: String,
    subtitle: String? = null,
    onBack: (() -> Unit)? = null,
    trailing: (@Composable () -> Unit)? = null,
    content: @Composable (PaddingValues) -> Unit,
) {
    androidx.compose.material3.Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            Row(
                Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                if (onBack != null) {
                    IconButton(
                        onClick = onBack,
                        modifier = Modifier.semantics { contentDescription = "Back" },
                    ) {
                        Icon(Icons.AutoMirrored.Rounded.ArrowBack, contentDescription = null)
                    }
                }
                Column(Modifier.weight(1f)) {
                    Text(title, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
                    subtitle?.let {
                        Text(it, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
                trailing?.invoke()
            }
        },
        content = content,
    )
}

@Composable
fun SoftCard(
    modifier: Modifier = Modifier,
    onClick: (() -> Unit)? = null,
    content: @Composable () -> Unit,
) {
    Card(
        modifier = modifier
            .fillMaxWidth()
            .then(if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier),
        shape = CardShape,
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant),
        elevation = CardDefaults.cardElevation(defaultElevation = 3.dp),
    ) {
        content()
    }
}

@Composable
fun GradientButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    loading: Boolean = false,
) {
    Button(
        onClick = onClick,
        enabled = enabled && !loading,
        modifier = modifier
            .fillMaxWidth()
            .height(52.dp)
            .clip(ButtonShape)
            .background(if (enabled) AppGradient else Brush.horizontalGradient(listOf(Color.LightGray, Color.LightGray))),
        shape = ButtonShape,
        colors = ButtonDefaults.buttonColors(containerColor = Color.Transparent, disabledContainerColor = Color.Transparent),
        contentPadding = PaddingValues(horizontal = 18.dp),
    ) {
        if (loading) {
            CircularProgressIndicator(Modifier.size(18.dp), strokeWidth = 2.dp, color = Color.White)
            Spacer(Modifier.width(8.dp))
        }
        Text(text, color = Color.White, fontWeight = FontWeight.Bold)
    }
}

@Composable
fun PeriodSelector(selected: PeriodType, onSelect: (PeriodType) -> Unit) {
    LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        items(PeriodType.entries) { type ->
            AppFilterChip(
                label = type.title,
                selected = selected == type,
                onClick = { onSelect(type) },
            )
        }
    }
}

@Composable
fun AppFilterChip(label: String, selected: Boolean, onClick: () -> Unit) {
    FilterChip(
        selected = selected,
        onClick = onClick,
        label = { Text(label, maxLines = 1, overflow = TextOverflow.Ellipsis) },
        modifier = Modifier.height(36.dp),
        shape = RoundedCornerShape(10.dp),
        colors = FilterChipDefaults.filterChipColors(
            selectedContainerColor = MaterialTheme.colorScheme.primaryContainer,
            selectedLabelColor = MaterialTheme.colorScheme.primary,
            containerColor = MaterialTheme.colorScheme.surface,
            labelColor = MaterialTheme.colorScheme.onSurfaceVariant,
        ),
        border = FilterChipDefaults.filterChipBorder(
            enabled = true,
            selected = selected,
            borderColor = MaterialTheme.colorScheme.outline,
            selectedBorderColor = MaterialTheme.colorScheme.primary,
        ),
    )
}

@Composable
fun TagPill(label: String) {
    Surface(
        shape = RoundedCornerShape(10.dp),
        color = MaterialTheme.colorScheme.primaryContainer,
        contentColor = MaterialTheme.colorScheme.primary,
    ) {
        Text(
            label,
            modifier = Modifier.padding(horizontal = 9.dp, vertical = 4.dp),
            style = MaterialTheme.typography.labelMedium,
            fontWeight = FontWeight.Medium,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

@Composable
fun EmptyState(text: String, modifier: Modifier = Modifier) {
    Box(modifier.fillMaxSize().padding(18.dp), contentAlignment = Alignment.Center) {
        StatusCard(
            title = text,
            body = when {
                text.contains("Loading", ignoreCase = true) -> "We are bringing your latest AIMemo data into view."
                text.contains("No", ignoreCase = true) || text.contains("not found", ignoreCase = true) -> "Once there is content here, it will use the same card layout as the main screens."
                else -> "Please try again in a moment."
            },
            loading = text.contains("Loading", ignoreCase = true),
        )
    }
}

@Composable
fun StatusCard(
    title: String,
    body: String,
    modifier: Modifier = Modifier,
    loading: Boolean = false,
    icon: Int? = null,
) {
    Surface(
        modifier = modifier
            .fillMaxWidth()
            .shadow(5.dp, RoundedCornerShape(18.dp), ambientColor = Color(0x10000000), spotColor = Color(0x14000000)),
        shape = RoundedCornerShape(18.dp),
        color = Color.White,
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant),
    ) {
        Row(
            modifier = Modifier.padding(18.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Surface(shape = RoundedCornerShape(16.dp), color = MaterialTheme.colorScheme.primaryContainer) {
                Box(Modifier.size(54.dp), contentAlignment = Alignment.Center) {
                    if (loading) {
                        CircularProgressIndicator(Modifier.size(24.dp), strokeWidth = 2.dp, color = MaterialTheme.colorScheme.primary)
                    } else if (icon != null) {
                        Icon(painterResource(icon), contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(28.dp))
                    } else {
                        Icon(Icons.Rounded.Info, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(28.dp))
                    }
                }
            }
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(title, color = MaterialTheme.colorScheme.onSurface, fontSize = 18.sp, lineHeight = 22.sp, fontWeight = FontWeight.Bold)
                Text(body, color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 14.sp, lineHeight = 19.sp)
            }
        }
    }
}

@Composable
fun IconBubble(icon: Int, modifier: Modifier = Modifier) {
    Surface(modifier = modifier.size(48.dp), shape = CircleShape, color = MaterialTheme.colorScheme.primaryContainer) {
        Box(contentAlignment = Alignment.Center) {
            Icon(painterResource(icon), contentDescription = null, tint = MaterialTheme.colorScheme.primary)
        }
    }
}

@Composable
fun CompleteIcon(completed: Boolean, modifier: Modifier = Modifier) {
    if (completed) {
        Icon(Icons.Rounded.CheckCircle, contentDescription = null, modifier = modifier, tint = MaterialTheme.colorScheme.primary)
    } else {
        Icon(
            painterResource(R.drawable.ic_radio_button_unchecked_round),
            contentDescription = null,
            modifier = modifier,
            tint = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

private val DateFormatter = DateTimeFormatter.ofPattern("MMM d").withZone(ZoneId.systemDefault())
private val DateTimeFormatterShort = DateTimeFormatter.ofPattern("MMM d, HH:mm").withZone(ZoneId.systemDefault())

fun formatDate(value: Instant): String = DateFormatter.format(value)

fun formatDateTime(value: Instant?): String = value?.let { DateTimeFormatterShort.format(it) } ?: "Not set"

fun buildTaskBody(title: String, notes: String): String =
    listOf(title.trim(), notes.trim()).filter { it.isNotEmpty() }.joinToString("\n")
