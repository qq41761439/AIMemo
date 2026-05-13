package com.aimemo.app.data

import com.aimemo.app.domain.ClientConfig
import com.aimemo.app.domain.PeriodType
import com.aimemo.app.domain.Quota
import com.aimemo.app.domain.SessionTokens
import com.aimemo.app.domain.SummaryRecord
import com.aimemo.app.domain.TaskRecord
import com.aimemo.app.domain.UserAccount
import java.time.Instant
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class ErrorEnvelopeDto(val error: ApiErrorDto? = null)

@Serializable
data class ApiErrorDto(val code: String? = null, val message: String? = null)

@Serializable
data class OkDto(val ok: Boolean = false)

@Serializable
data class TokenResponseDto(
    val accessToken: String,
    val refreshToken: String,
    val user: UserDto? = null,
) {
    fun tokens() = SessionTokens(accessToken, refreshToken)
}

@Serializable
data class UserDto(
    val id: String,
    val email: String? = null,
) {
    fun toDomain() = UserAccount(id, email)
}

@Serializable
data class QuotaDto(
    val limit: Int,
    val used: Int,
    val remaining: Int,
) {
    fun toDomain() = Quota(limit, used, remaining)
}

@Serializable
data class ClientConfigDto(
    val hostedModelAvailable: Boolean = false,
    val monthlyFreeSummaryLimit: Int = 0,
) {
    fun toDomain() = ClientConfig(hostedModelAvailable, monthlyFreeSummaryLimit)
}

@Serializable
data class MeResponseDto(
    val user: UserDto,
    val quota: QuotaDto,
    val config: ClientConfigDto,
)

@Serializable
data class ItemsResponseDto<T>(val items: List<T> = emptyList())

@Serializable
data class TaskResponseDto(val task: TaskDto)

@Serializable
data class TaskDto(
    val id: String,
    val body: String,
    val tags: List<String> = emptyList(),
    val isCompleted: Boolean = false,
    val createdAt: String,
    val completedAt: String? = null,
    val updatedAt: String,
    val deletedAt: String? = null,
    val clientId: String? = null,
) {
    fun toDomain() = TaskRecord(
        id = id,
        body = body,
        tags = tags,
        isCompleted = isCompleted,
        createdAt = Instant.parse(createdAt),
        completedAt = completedAt?.let(Instant::parse),
        updatedAt = Instant.parse(updatedAt),
        deletedAt = deletedAt?.let(Instant::parse),
        clientId = clientId,
    )
}

@Serializable
data class TaskInputDto(
    val body: String? = null,
    val tags: List<String>? = null,
    val isCompleted: Boolean? = null,
    val createdAt: String? = null,
    val completedAt: String? = null,
    val clientId: String? = null,
)

@Serializable
data class GenerateSummaryRequestDto(
    val periodType: String,
    val periodLabel: String,
    val periodStart: String,
    val periodEnd: String,
    val tags: List<String>,
    val tasks: String,
    val prompt: String,
)

@Serializable
data class GenerateSummaryResponseDto(
    val summary: String,
    val quota: QuotaDto,
)

@Serializable
data class SummaryDto(
    val id: String,
    val periodType: String,
    val periodLabel: String,
    val periodStart: String,
    val periodEnd: String,
    val tags: List<String> = emptyList(),
    val output: String,
    val model: String,
    val createdAt: String,
) {
    fun toDomain() = SummaryRecord(
        id = id,
        periodType = when (periodType) {
            "daily" -> PeriodType.Daily
            "weekly" -> PeriodType.Weekly
            "monthly" -> PeriodType.Monthly
            "yearly" -> PeriodType.Yearly
            else -> PeriodType.Custom
        },
        periodLabel = periodLabel,
        periodStart = Instant.parse(periodStart),
        periodEnd = Instant.parse(periodEnd),
        tags = tags,
        output = output,
        model = model,
        createdAt = Instant.parse(createdAt),
    )
}

@Serializable
data class EmailStartRequestDto(val email: String)

@Serializable
data class EmailVerifyRequestDto(val email: String, val code: String)

@Serializable
data class RefreshRequestDto(val refreshToken: String)
