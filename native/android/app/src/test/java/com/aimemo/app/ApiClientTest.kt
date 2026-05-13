package com.aimemo.app

import com.aimemo.app.data.ApiClient
import com.aimemo.app.data.ApiException
import io.ktor.http.HttpStatusCode
import org.junit.Assert.assertEquals
import org.junit.Test

class ApiClientTest {
    @Test
    fun decodeErrorUsesBackendMessage() {
        val error: ApiException = ApiClient.decodeErrorBody(
            status = HttpStatusCode.TooManyRequests,
            text = """{"error":{"code":"quota_exceeded","message":"免费额度不足。"}}""",
        )

        assertEquals("quota_exceeded", error.code)
        assertEquals("免费额度不足。", error.message)
        assertEquals(429, error.status)
    }
}
