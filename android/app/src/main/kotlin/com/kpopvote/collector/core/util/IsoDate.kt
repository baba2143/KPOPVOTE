package com.kpopvote.collector.core.util

import java.time.Instant
import java.time.ZoneId
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter
import java.time.format.DateTimeFormatterBuilder
import java.time.temporal.ChronoField
import java.util.Locale

/**
 * ISO8601 ⇄ epoch millis conversions used at the UI/domain boundary.
 * The backend uses `ISO8601DateFormatter.Options.withFractionalSeconds` on iOS, so fractional
 * seconds must be tolerated both on parse and round-tripped on serialize.
 */
object IsoDate {
    private val parser: DateTimeFormatter = DateTimeFormatterBuilder()
        .append(DateTimeFormatter.ISO_OFFSET_DATE_TIME)
        .toFormatter(Locale.ROOT)

    private val writer: DateTimeFormatter = DateTimeFormatterBuilder()
        .appendPattern("yyyy-MM-dd'T'HH:mm:ss")
        .optionalStart()
        .appendFraction(ChronoField.NANO_OF_SECOND, 3, 3, true)
        .optionalEnd()
        .appendOffset("+HH:MM", "Z")
        .toFormatter(Locale.ROOT)

    fun parseToMillis(iso: String?): Long? = iso?.let {
        runCatching { Instant.from(parser.parse(it)).toEpochMilli() }.getOrNull()
    }

    fun millisToIso(millis: Long): String =
        ZonedDateTime.ofInstant(Instant.ofEpochMilli(millis), ZoneId.of("UTC")).format(writer)
}
