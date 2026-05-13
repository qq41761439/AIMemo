package com.aimemo.app.data

import com.aimemo.app.domain.SessionTokens
import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.engine.okhttp.OkHttp
import io.ktor.client.plugins.HttpResponseValidator
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.plugins.defaultRequest
import io.ktor.client.request.HttpRequestBuilder
import io.ktor.client.request.bearerAuth
import io.ktor.client.request.delete
import io.ktor.client.request.get
import io.ktor.client.request.patch
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.ContentType
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.http.contentType
import io.ktor.serialization.kotlinx.json.json
import kotlinx.serialization.json.Json

open class ApiException(
    val code: String,
    override val message: String,
    val status: Int? = null,
) : Exception(message)

class AuthExpiredException : ApiException("auth_expired", "登录状态已失效，请重新登录。", 401)

class ApiClient(
    baseUrl: String,
    private val sessionStore: SessionStore,
    private val json: Json = defaultJson,
    client: HttpClient? = null,
) {
    private val normalizedBaseUrl = baseUrl.trim().trimEnd('/')
    private val http = client ?: HttpClient(OkHttp) {
        install(ContentNegotiation) { json(json) }
        defaultRequest { contentType(ContentType.Application.Json) }
        HttpResponseValidator {
            validateResponse { response ->
                if (response.status.value >= 400) {
                    throw decodeError(response, json)
                }
            }
        }
    }

    suspend fun startEmailLogin(email: String) {
        http.post("$normalizedBaseUrl/auth/email/start") {
            setBody(EmailStartRequestDto(email))
        }.body<OkDto>()
    }

    suspend fun verifyEmailLogin(email: String, code: String): TokenResponseDto =
        http.post("$normalizedBaseUrl/auth/email/verify") {
            setBody(EmailVerifyRequestDto(email, code))
        }.body()

    suspend fun refresh(refreshToken: String): SessionTokens =
        http.post("$normalizedBaseUrl/auth/refresh") {
            setBody(RefreshRequestDto(refreshToken))
        }.body<TokenResponseDto>().tokens()

    suspend fun me(): MeResponseDto = authorized { token ->
        http.get("$normalizedBaseUrl/me") { bearerAuth(token) }.body()
    }

    suspend fun clientConfig(): ClientConfigDto =
        http.get("$normalizedBaseUrl/client/config").body()

    suspend fun tasks(): List<TaskDto> = authorized { token ->
        http.get("$normalizedBaseUrl/tasks") { bearerAuth(token) }
            .body<ItemsResponseDto<TaskDto>>()
            .items
    }

    suspend fun tags(): List<String> = authorized { token ->
        http.get("$normalizedBaseUrl/tags") { bearerAuth(token) }
            .body<ItemsResponseDto<String>>()
            .items
    }

    suspend fun createTask(input: TaskInputDto): TaskDto = authorized { token ->
        http.post("$normalizedBaseUrl/tasks") {
            bearerAuth(token)
            setBody(input)
        }.body<TaskResponseDto>().task
    }

    suspend fun updateTask(id: String, input: TaskInputDto): TaskDto = authorized { token ->
        http.patch("$normalizedBaseUrl/tasks/$id") {
            bearerAuth(token)
            setBody(input)
        }.body<TaskResponseDto>().task
    }

    suspend fun deleteTask(id: String): TaskDto = authorized { token ->
        http.delete("$normalizedBaseUrl/tasks/$id") { bearerAuth(token) }
            .body<TaskResponseDto>().task
    }

    suspend fun generateSummary(input: GenerateSummaryRequestDto): GenerateSummaryResponseDto =
        authorized { token ->
            http.post("$normalizedBaseUrl/summaries/generate") {
                bearerAuth(token)
                setBody(input)
            }.body()
        }

    suspend fun summaries(): List<SummaryDto> = authorized { token ->
        http.get("$normalizedBaseUrl/summaries") { bearerAuth(token) }
            .body<ItemsResponseDto<SummaryDto>>()
            .items
    }

    private suspend fun <T> authorized(block: suspend (String) -> T): T {
        val initial = sessionStore.readTokens() ?: throw AuthExpiredException()
        try {
            return block(initial.accessToken)
        } catch (error: ApiException) {
            if (error.status != 401) throw error
        }

        val refreshed = try {
            refresh(initial.refreshToken)
        } catch (_: Exception) {
            sessionStore.clearTokens()
            throw AuthExpiredException()
        }
        sessionStore.saveTokens(refreshed)
        return try {
            block(refreshed.accessToken)
        } catch (error: ApiException) {
            if (error.status == 401) {
                sessionStore.clearTokens()
                throw AuthExpiredException()
            }
            throw error
        }
    }

    companion object {
        val defaultJson = Json {
            ignoreUnknownKeys = true
            explicitNulls = false
        }

        suspend fun decodeError(response: HttpResponse, json: Json = defaultJson): ApiException {
            val text = runCatching { response.bodyAsText() }.getOrDefault("")
            return decodeErrorBody(response.status, text, json)
        }

        fun decodeErrorBody(
            status: HttpStatusCode,
            text: String,
            json: Json = defaultJson,
        ): ApiException {
            val envelope = runCatching { json.decodeFromString<ErrorEnvelopeDto>(text) }.getOrNull()
            val apiError = envelope?.error
            val message = apiError?.message?.takeIf { it.isNotBlank() }
                ?: when (status) {
                    HttpStatusCode.Unauthorized -> "登录状态已失效，请重新登录。"
                    HttpStatusCode.TooManyRequests -> "免费额度不足，请下月再试。"
                    else -> "AIMemo 后端请求失败，状态码 ${status.value}。"
                }
            return ApiException(
                code = apiError?.code ?: status.description,
                message = message,
                status = status.value,
            )
        }
    }
}
