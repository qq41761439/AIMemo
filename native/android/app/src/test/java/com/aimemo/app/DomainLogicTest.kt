package com.aimemo.app

import com.aimemo.app.domain.PeriodType
import com.aimemo.app.domain.SummaryDraft
import com.aimemo.app.domain.TaskRecord
import com.aimemo.app.domain.cleanTags
import com.aimemo.app.domain.defaultTemplate
import com.aimemo.app.domain.periodRange
import com.aimemo.app.domain.renderPrompt
import com.aimemo.app.domain.sectionTasks
import com.aimemo.app.domain.sortTasks
import com.aimemo.app.domain.tagsFromTasks
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

class DomainLogicTest {
    @Test
    fun cleanTagsSplitsChineseAndEnglishCommas() {
        assertEquals(listOf("工作", "后端", "总结"), cleanTags(" 工作, 后端， 总结,,工作 "))
    }

    @Test
    fun sortTasksKeepsOpenTasksFirstAndNewestFirst() {
        val oldOpen = task("1", createdAt = "2026-05-10T00:00:00Z")
        val newOpen = task("2", createdAt = "2026-05-12T00:00:00Z")
        val done = task(
            "3",
            completedAt = "2026-05-13T00:00:00Z",
            isCompleted = true,
        )

        assertEquals(listOf("2", "1", "3"), sortTasks(listOf(oldOpen, done, newOpen)).map { it.id })
    }

    @Test
    fun sectionTasksSeparatesActiveUpcomingAndCompleted() {
        val zone = ZoneId.of("UTC")
        val active = task("1", createdAt = "2026-05-14T00:00:00Z")
        val upcoming = task("2", createdAt = "2026-05-15T00:00:00Z")
        val done = task(
            "3",
            createdAt = "2026-05-10T00:00:00Z",
            completedAt = "2026-05-13T00:00:00Z",
            isCompleted = true,
        )

        val sections = sectionTasks(
            listOf(upcoming, done, active),
            today = LocalDate.of(2026, 5, 14),
            zone = zone,
        )

        assertEquals(listOf("1"), sections.active.map { it.id })
        assertEquals(listOf("2"), sections.upcoming.map { it.id })
        assertEquals(listOf("3"), sections.completed.map { it.id })
    }

    @Test
    fun tagsAreOrderedByLatestAssociatedTask() {
        val old = task("1", tags = listOf("旧"), updatedAt = "2026-05-10T00:00:00Z")
        val new = task("2", tags = listOf("新", "旧"), updatedAt = "2026-05-13T00:00:00Z")

        assertEquals(listOf("新", "旧"), tagsFromTasks(listOf(old, new)))
    }

    @Test
    fun weeklyPeriodStartsOnMonday() {
        val range = periodRange(PeriodType.Weekly, LocalDate.of(2026, 5, 13))

        assertTrue(range.label.contains("2026"))
        assertEquals(LocalDate.of(2026, 5, 11), range.start.atZone(ZoneId.systemDefault()).toLocalDate())
    }

    @Test
    fun renderPromptIncludesTemplateAndTasks() {
        val range = periodRange(PeriodType.Daily, LocalDate.of(2026, 5, 13))
        val prompt = renderPrompt(
            SummaryDraft(
                periodType = PeriodType.Daily,
                periodLabel = range.label,
                periodStart = range.start,
                periodEnd = range.end,
                tags = listOf("工作"),
                template = defaultTemplate(PeriodType.Daily),
            ),
            "- [已完成] 完成安卓端",
        )

        assertTrue(prompt.contains("完成安卓端"))
        assertTrue(prompt.contains("已完成工作"))
    }

    private fun task(
        id: String,
        tags: List<String> = emptyList(),
        createdAt: String = "2026-05-13T00:00:00Z",
        updatedAt: String = createdAt,
        completedAt: String? = null,
        isCompleted: Boolean = false,
    ) = TaskRecord(
        id = id,
        body = "任务 $id",
        tags = tags,
        isCompleted = isCompleted,
        createdAt = Instant.parse(createdAt),
        completedAt = completedAt?.let(Instant::parse),
        updatedAt = Instant.parse(updatedAt),
        deletedAt = null,
        clientId = "android-$id",
    )
}
