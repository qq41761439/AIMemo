package com.aimemo.app.ui

import androidx.compose.foundation.Image
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Canvas
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
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Email
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.aimemo.app.ui.theme.AimemoPrimary
import com.aimemo.app.ui.theme.AimemoPrimaryEnd
import com.aimemo.app.R

@Composable
fun OnboardingScreen(onContinue: () -> Unit, onSkip: () -> Unit) {
    Scaffold(containerColor = MaterialTheme.colorScheme.background) { padding ->
        Column(
            Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 24.dp, vertical = 28.dp),
            verticalArrangement = Arrangement.SpaceBetween,
        ) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                TextButton(onClick = onSkip) { Text("Skip") }
            }
            Column(verticalArrangement = Arrangement.spacedBy(18.dp)) {
                Image(
                    painterResource(R.drawable.logo),
                    contentDescription = null,
                    modifier = Modifier
                        .size(92.dp)
                        .clip(RoundedCornerShape(24.dp)),
                    contentScale = ContentScale.Fit,
                )
                Text("Organize tasks into clear progress", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
                Text(
                    "AIMemo keeps daily work lightweight, then turns completed tasks into useful AI summaries when you need them.",
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                SoftCard {
                    Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        Text("Tasks", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                        Text("Group active, upcoming, and completed work with compact tags.", color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
                SoftCard {
                    Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        Text("AI Summary", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                        Text("Generate daily, weekly, monthly, or custom summaries from real task history.", color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
            }
            GradientButton(text = "Get Started", onClick = onContinue)
        }
    }
}

@Composable
fun AuthScreen(
    state: AIMemoUiState,
    snackbarHostState: SnackbarHostState,
    onEmailChange: (String) -> Unit,
    onCodeChange: (String) -> Unit,
    onSendCode: () -> Unit,
    onLogin: () -> Unit,
    onComingSoon: (String) -> Unit,
) {
    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        snackbarHost = { SnackbarHost(snackbarHostState) },
    ) { padding ->
        Column(
            Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .imePadding()
                .padding(horizontal = 24.dp, vertical = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Spacer(Modifier.height(26.dp))
            AuthLogo()
            Spacer(Modifier.height(16.dp))
            Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(
                    "AIMemo",
                    fontSize = 42.sp,
                    lineHeight = 46.sp,
                    fontWeight = FontWeight.Black,
                    color = Color(0xFF080524),
                )
                Text(
                    "Capture your work.\nTurn it into clear AI summaries.",
                    textAlign = TextAlign.Center,
                    fontSize = 17.sp,
                    lineHeight = 24.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            Spacer(Modifier.height(28.dp))
            AuthFormCard(
                state = state,
                onEmailChange = onEmailChange,
                onCodeChange = onCodeChange,
                onSendCode = onSendCode,
                onLogin = onLogin,
                onComingSoon = onComingSoon,
            )
            Spacer(Modifier.height(14.dp))
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.Center) {
                Text("Don't have an account?", color = MaterialTheme.colorScheme.onSurfaceVariant)
                TextButton(onClick = { onComingSoon("Sign up") }) { Text("Sign up") }
            }
            Row(horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically) {
                TextButton(onClick = { onComingSoon("Privacy") }) { Text("Privacy") }
                Text("•", color = MaterialTheme.colorScheme.onSurfaceVariant)
                TextButton(onClick = { onComingSoon("Terms") }) { Text("Terms") }
                Text("•", color = MaterialTheme.colorScheme.onSurfaceVariant)
                TextButton(onClick = { onComingSoon("How sync works") }) { Text("How sync works") }
            }
            Spacer(Modifier.height(10.dp))
        }
    }
}

@Composable
private fun AuthLogo() {
    Box(
        modifier = Modifier.size(92.dp),
        contentAlignment = Alignment.Center,
    ) {
        Canvas(Modifier.fillMaxSize()) {
            val stroke = size.width * 0.18f
            val brush = Brush.linearGradient(listOf(AimemoPrimary, AimemoPrimaryEnd))
            drawLine(
                brush = brush,
                start = androidx.compose.ui.geometry.Offset(size.width * 0.24f, size.height * 0.74f),
                end = androidx.compose.ui.geometry.Offset(size.width * 0.48f, size.height * 0.2f),
                strokeWidth = stroke,
                cap = StrokeCap.Round,
            )
            drawLine(
                brush = brush,
                start = androidx.compose.ui.geometry.Offset(size.width * 0.5f, size.height * 0.2f),
                end = androidx.compose.ui.geometry.Offset(size.width * 0.76f, size.height * 0.74f),
                strokeWidth = stroke,
                cap = StrokeCap.Round,
            )
            drawLine(
                brush = brush,
                start = androidx.compose.ui.geometry.Offset(size.width * 0.38f, size.height * 0.52f),
                end = androidx.compose.ui.geometry.Offset(size.width * 0.62f, size.height * 0.52f),
                strokeWidth = stroke * 0.72f,
                cap = StrokeCap.Round,
            )
        }
        Surface(
            modifier = Modifier.align(Alignment.TopEnd).padding(top = 8.dp, end = 11.dp).size(19.dp),
            shape = CircleShape,
            color = AimemoPrimaryEnd,
        ) {}
    }
}

@Composable
private fun AuthFormCard(
    state: AIMemoUiState,
    onEmailChange: (String) -> Unit,
    onCodeChange: (String) -> Unit,
    onSendCode: () -> Unit,
    onLogin: () -> Unit,
    onComingSoon: (String) -> Unit,
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(22.dp),
        color = MaterialTheme.colorScheme.surface,
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline),
        shadowElevation = 5.dp,
    ) {
        Column(Modifier.padding(horizontal = 16.dp, vertical = 18.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            AuthTextField(
                value = state.authEmail,
                onValueChange = onEmailChange,
                placeholder = "Email",
                leadingIcon = { Icon(Icons.Outlined.Email, contentDescription = null, tint = AimemoPrimary) },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email, imeAction = ImeAction.Next),
            )
            AuthTextField(
                value = state.authCode,
                onValueChange = onCodeChange,
                placeholder = "Verification code",
                leadingIcon = { Icon(Icons.Outlined.Lock, contentDescription = null, tint = AimemoPrimary) },
                trailingIcon = {
                    TextButton(onClick = onSendCode, enabled = !state.isSendingCode) {
                        if (state.isSendingCode) CircularProgressIndicator(Modifier.size(16.dp), strokeWidth = 2.dp) else Text("Send")
                    }
                },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number, imeAction = ImeAction.Done),
            )
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                TextButton(onClick = { onComingSoon("Forgot password") }) {
                    Text("Forgot password?", color = AimemoPrimary)
                }
            }
            GradientButton(
                text = "Log in",
                onClick = onLogin,
                loading = state.isLoggingIn,
                modifier = Modifier.height(52.dp),
            )
            OrDivider()
            SocialButton(label = "Continue with Google", mark = "G") { onComingSoon("Google sign-in") }
            SocialButton(label = "Continue with Apple", mark = "●") { onComingSoon("Apple sign-in") }
        }
    }
}

@Composable
private fun AuthTextField(
    value: String,
    onValueChange: (String) -> Unit,
    placeholder: String,
    leadingIcon: @Composable () -> Unit,
    trailingIcon: (@Composable () -> Unit)? = null,
    keyboardOptions: KeyboardOptions,
) {
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        placeholder = { Text(placeholder) },
        leadingIcon = leadingIcon,
        trailingIcon = trailingIcon,
        keyboardOptions = keyboardOptions,
        singleLine = true,
        modifier = Modifier.fillMaxWidth().height(58.dp),
        shape = RoundedCornerShape(16.dp),
        colors = OutlinedTextFieldDefaults.colors(
            focusedBorderColor = AimemoPrimary,
            unfocusedBorderColor = MaterialTheme.colorScheme.outline,
            focusedContainerColor = Color.White,
            unfocusedContainerColor = Color.White,
        ),
    )
}

@Composable
private fun OrDivider() {
    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        HorizontalDivider(Modifier.weight(1f), color = MaterialTheme.colorScheme.outlineVariant)
        Text("or continue with", color = MaterialTheme.colorScheme.onSurfaceVariant, style = MaterialTheme.typography.bodySmall)
        HorizontalDivider(Modifier.weight(1f), color = MaterialTheme.colorScheme.outlineVariant)
    }
}

@Composable
private fun SocialButton(label: String, mark: String, onClick: () -> Unit) {
    Surface(
        modifier = Modifier.fillMaxWidth().height(50.dp).clickable(onClick = onClick),
        shape = RoundedCornerShape(14.dp),
        color = Color.White,
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline),
    ) {
        Row(horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically) {
            Text(mark, color = if (mark == "G") Color(0xFF4285F4) else Color.Black, fontWeight = FontWeight.Bold)
            Spacer(Modifier.width(14.dp))
            Text(label, fontWeight = FontWeight.Medium)
        }
    }
}
