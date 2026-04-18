package com.kpopvote.collector.core.performance

import com.google.firebase.perf.FirebasePerformance
import com.google.firebase.perf.metrics.Trace
import io.mockk.Runs
import io.mockk.every
import io.mockk.just
import io.mockk.mockk
import io.mockk.verify
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

class PerformanceTracerTest {

    @Test
    fun `trace starts and stops around successful block`() = runTest {
        val trace: Trace = mockk(relaxed = true) {
            every { start() } just Runs
            every { stop() } just Runs
        }
        val performance: FirebasePerformance = mockk {
            every { newTrace("load_votes") } returns trace
        }
        val tracer = PerformanceTracer(performance)

        val result = tracer.trace("load_votes") { 42 }

        assertEquals(42, result)
        verify(exactly = 1) { trace.start() }
        verify(exactly = 1) { trace.stop() }
    }

    @Test
    fun `trace still stops trace when block throws`() = runTest {
        val trace: Trace = mockk(relaxed = true) {
            every { start() } just Runs
            every { stop() } just Runs
        }
        val performance: FirebasePerformance = mockk {
            every { newTrace("failing_op") } returns trace
        }
        val tracer = PerformanceTracer(performance)

        assertThrows(IllegalStateException::class.java) {
            kotlinx.coroutines.runBlocking {
                tracer.trace<Int>("failing_op") { error("boom") }
            }
        }

        verify(exactly = 1) { trace.start() }
        verify(exactly = 1) { trace.stop() }
    }
}
