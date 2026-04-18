package com.kpopvote.collector.core.performance

import com.google.firebase.perf.FirebasePerformance
import com.google.firebase.perf.metrics.Trace
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Wraps Firebase Performance [Trace] in a coroutine-friendly API so callers don't
 * need to remember start/stop or the attribute API.
 *
 * Attribute keys must be ≤ 40 chars and values ≤ 100 chars — Firebase silently drops
 * entries that exceed these limits.
 */
@Singleton
class PerformanceTracer @Inject constructor(
    private val performance: FirebasePerformance,
) {
    /**
     * Starts a trace, runs [block], then stops the trace (even on throw). Attributes
     * added to the receiver inside [block] land on the finished trace.
     */
    suspend fun <T> trace(name: String, block: suspend Trace.() -> T): T {
        val trace = performance.newTrace(name).also { it.start() }
        return try {
            block(trace)
        } finally {
            trace.stop()
        }
    }
}

/** Non-suspend flavor used when wrapping plain blocks. */
inline fun <T> PerformanceTracer.traceBlocking(
    tracer: FirebasePerformance,
    name: String,
    crossinline block: Trace.() -> T,
): T {
    val t = tracer.newTrace(name).also { it.start() }
    return try {
        block(t)
    } finally {
        t.stop()
    }
}
