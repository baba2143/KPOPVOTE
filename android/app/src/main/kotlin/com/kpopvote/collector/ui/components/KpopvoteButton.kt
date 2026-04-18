package com.kpopvote.collector.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.unit.dp
import com.kpopvote.collector.ui.theme.BrandColors
import com.kpopvote.collector.ui.theme.KpopvoteShapes

@Composable
fun KpopvoteButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    loading: Boolean = false,
) {
    Button(
        onClick = onClick,
        enabled = enabled && !loading,
        modifier = modifier
            .fillMaxWidth()
            .height(52.dp),
        shape = KpopvoteShapes.medium,
        colors = ButtonDefaults.buttonColors(
            containerColor = BrandColors.AccentPink,
            contentColor = androidx.compose.ui.graphics.Color.White,
        ),
    ) {
        if (loading) {
            CircularProgressIndicator(
                modifier = Modifier.size(20.dp),
                color = androidx.compose.ui.graphics.Color.White,
                strokeWidth = 2.dp,
            )
        } else {
            Text(text)
        }
    }
}

@Composable
fun KpopvoteGradientButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    loading: Boolean = false,
) {
    val gradient = Brush.horizontalGradient(
        colors = listOf(BrandColors.AccentPink, BrandColors.GradientPurple, BrandColors.AccentBlue),
    )
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(52.dp)
            .background(brush = gradient, shape = KpopvoteShapes.medium),
        contentAlignment = Alignment.Center,
    ) {
        Button(
            onClick = onClick,
            enabled = enabled && !loading,
            modifier = Modifier.fillMaxWidth().height(52.dp),
            shape = KpopvoteShapes.medium,
            colors = ButtonDefaults.buttonColors(
                containerColor = androidx.compose.ui.graphics.Color.Transparent,
                contentColor = androidx.compose.ui.graphics.Color.White,
                disabledContainerColor = androidx.compose.ui.graphics.Color.Transparent,
                disabledContentColor = androidx.compose.ui.graphics.Color.White.copy(alpha = 0.5f),
            ),
            contentPadding = androidx.compose.foundation.layout.PaddingValues(0.dp),
        ) {
            if (loading) {
                CircularProgressIndicator(
                    modifier = Modifier.size(20.dp),
                    color = androidx.compose.ui.graphics.Color.White,
                    strokeWidth = 2.dp,
                )
            } else {
                Text(text)
            }
        }
    }
}

@Composable
fun KpopvoteSecondaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
) {
    OutlinedButton(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier
            .fillMaxWidth()
            .height(52.dp),
        shape = KpopvoteShapes.medium,
    ) {
        Text(
            text = text,
            modifier = Modifier.padding(vertical = 4.dp),
        )
    }
}
