package com.aimemo.app.domain

import java.time.Instant
import java.util.UUID

enum class PeriodType(val apiName: String, val title: String) {
    Daily("daily", "日"),
    Weekly("weekly", "周"),
    Monthly("monthly", "月"),
    Yearly("yearly", "年"),
    Custom("custom", "自定义")
}

data class UserAccount(
    val id: String,
    val email: String?,
)

data class Quota(
    val limit: Int,
    val used: Int,
    val remaining: Int,
)

data class ClientConfig(
    val hostedModelAvailable: Boolean,
    val monthlyFreeSummaryLimit: Int,
)

data class TaskRecord(
    val id: String,
    val body: String,
    val tags: List<String>,
    val isCompleted: Boolean,
    val createdAt: Instant,
    val completedAt: Instant?,
    val updatedAt: Instant,
    val deletedAt: Instant?,
    val clientId: String?,
) {
    val title: String = body.lineSequence().firstOrNull()?.trim().orEmpty().ifBlank { "未命名任务" }
    val detail: String = body.lineSequence().drop(1).joinToString("\n").trim()
}

data class SummaryRecord(
    val id: String,
    val periodType: PeriodType,
    val periodLabel: String,
    val periodStart: Instant,
    val periodEnd: Instant,
    val tags: List<String>,
    val output: String,
    val model: String,
    val createdAt: Instant,
)

data class SummaryDraft(
    val periodType: PeriodType,
    val periodLabel: String,
    val periodStart: Instant,
    val periodEnd: Instant,
    val tags: List<String>,
    val template: String,
)

data class SessionTokens(
    val accessToken: String,
    val refreshToken: String,
)

fun newAndroidClientId(): String = "android-${UUID.randomUUID()}"

fun nowInstant(): Instant = Instant.now()
