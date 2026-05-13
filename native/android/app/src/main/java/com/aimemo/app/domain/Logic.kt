package com.aimemo.app.domain

import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

fun cleanTags(input: String): List<String> =
    input.split(',', '，')
        .map { it.trim() }
        .filter { it.isNotEmpty() }
        .distinct()

fun sortTasks(tasks: List<TaskRecord>): List<TaskRecord> {
    val visible = tasks.filter { it.deletedAt == null }
    return visible.sortedWith(
        compareBy<TaskRecord> { it.isCompleted }
            .thenByDescending { if (it.isCompleted) it.completedAt ?: it.updatedAt else it.createdAt }
    )
}

fun tagsFromTasks(tasks: List<TaskRecord>): List<String> {
    data class TagMarker(val updatedAt: Instant, val order: Int)
    val latestByTag = linkedMapOf<String, TagMarker>()
    var order = 0
    tasks.filter { it.deletedAt == null }.forEach { task ->
        task.tags.forEach { tag ->
            val marker = TagMarker(task.updatedAt, order++)
            val current = latestByTag[tag]
            if (current == null || marker.updatedAt > current.updatedAt || marker.order > current.order) {
                latestByTag[tag] = marker
            }
        }
    }
    return latestByTag.entries
        .sortedWith(compareByDescending<Map.Entry<String, TagMarker>> { it.value.updatedAt }.thenBy { it.value.order })
        .map { it.key }
}

fun taskTextForSummary(tasks: List<TaskRecord>): String =
    sortTasks(tasks).joinToString("\n") { task ->
        val status = if (task.isCompleted) "已完成" else "未完成"
        val tags = if (task.tags.isEmpty()) "" else " 标签：${task.tags.joinToString("、")}"
        "- [$status] ${task.body.replace('\n', ' ')}$tags"
    }

fun defaultTemplate(type: PeriodType): String =
    when (type) {
        PeriodType.Daily, PeriodType.Weekly -> "请基于任务记录输出：\n1. 已完成工作\n2. 下一步计划"
        PeriodType.Monthly, PeriodType.Yearly, PeriodType.Custom ->
            "请基于任务记录输出：\n1. 阶段概览\n2. 关键进展\n3. 问题与风险\n4. 下一阶段计划"
    }

fun renderPrompt(draft: SummaryDraft, tasksText: String): String = """
你是 AIMemo 的个人工作复盘助手。请用中文生成自然、清晰、可复制的周期总结。

周期：${draft.periodLabel}
标签：${draft.tags.ifEmpty { listOf("全部") }.joinToString("、")}

模板：
${draft.template}

任务记录：
$tasksText
""".trim()

data class PeriodRange(
    val label: String,
    val start: Instant,
    val end: Instant,
)

fun periodRange(type: PeriodType, nowDate: LocalDate = LocalDate.now()): PeriodRange {
    val zone = ZoneId.systemDefault()
    val startDate = when (type) {
        PeriodType.Daily, PeriodType.Custom -> nowDate
        PeriodType.Weekly -> nowDate.minusDays((nowDate.dayOfWeek.value - 1).toLong())
        PeriodType.Monthly -> LocalDate.of(nowDate.year, nowDate.monthValue, 1)
        PeriodType.Yearly -> LocalDate.of(nowDate.year, 1, 1)
    }
    val endDate = when (type) {
        PeriodType.Daily, PeriodType.Custom -> startDate.plusDays(1)
        PeriodType.Weekly -> startDate.plusDays(7)
        PeriodType.Monthly -> startDate.plusMonths(1)
        PeriodType.Yearly -> startDate.plusYears(1)
    }
    val label = when (type) {
        PeriodType.Daily -> "${startDate.year}-${startDate.monthValue.toString().padStart(2, '0')}-${startDate.dayOfMonth.toString().padStart(2, '0')}"
        PeriodType.Weekly -> "${startDate.year} 第${nowDate.dayOfYear / 7 + 1}周"
        PeriodType.Monthly -> "${startDate.year}-${startDate.monthValue.toString().padStart(2, '0')}"
        PeriodType.Yearly -> "${startDate.year}"
        PeriodType.Custom -> "自定义 ${startDate.year}-${startDate.monthValue.toString().padStart(2, '0')}-${startDate.dayOfMonth.toString().padStart(2, '0')}"
    }
    return PeriodRange(
        label = label,
        start = startDate.atStartOfDay(zone).toInstant(),
        end = endDate.atStartOfDay(zone).toInstant(),
    )
}
