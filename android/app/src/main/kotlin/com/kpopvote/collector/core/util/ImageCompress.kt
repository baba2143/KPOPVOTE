package com.kpopvote.collector.core.util

import android.content.ContentResolver
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream

/**
 * Decode a [Uri] (typically from PhotoPicker) into a JPEG byte array at the given quality.
 * Uses `inSampleSize` to avoid loading huge images into memory when the device has limited heap.
 */
object ImageCompress {
    private const val MAX_DIMENSION = 1920
    private const val JPEG_QUALITY = 80

    suspend fun compressUri(resolver: ContentResolver, uri: Uri): ByteArray =
        withContext(Dispatchers.IO) {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            resolver.openInputStream(uri).use { BitmapFactory.decodeStream(it, null, bounds) }
            val sample = calculateInSampleSize(bounds.outWidth, bounds.outHeight)

            val opts = BitmapFactory.Options().apply { inSampleSize = sample }
            val bitmap = resolver.openInputStream(uri).use {
                BitmapFactory.decodeStream(it, null, opts)
            } ?: error("Failed to decode image at $uri")

            val out = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.JPEG, JPEG_QUALITY, out)
            bitmap.recycle()
            out.toByteArray()
        }

    private fun calculateInSampleSize(width: Int, height: Int): Int {
        var sample = 1
        val longest = maxOf(width, height)
        while (longest / sample > MAX_DIMENSION) sample *= 2
        return sample.coerceAtLeast(1)
    }
}
