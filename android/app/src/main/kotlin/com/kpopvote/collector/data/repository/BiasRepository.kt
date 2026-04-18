package com.kpopvote.collector.data.repository

import com.kpopvote.collector.data.model.BiasSettings

/** Current user's bias (oshi) settings. Mirrors iOS `BiasService`. */
interface BiasRepository {
    suspend fun getBias(): Result<List<BiasSettings>>
    suspend fun setBias(settings: List<BiasSettings>): Result<Unit>
}
