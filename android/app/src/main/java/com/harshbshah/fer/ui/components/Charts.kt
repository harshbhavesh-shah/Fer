package com.harshbshah.fer.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.dp

/** Simple bar chart — Android equivalent of SwiftUI Charts' BarMark usage on Dashboard/History. */
@Composable
fun BarChart(
    values: List<Double>,
    modifier: Modifier = Modifier,
    barColor: Color = MaterialTheme.colorScheme.primary,
    height: androidx.compose.ui.unit.Dp = 120.dp
) {
    val maxValue = (values.maxOrNull() ?: 0.0).coerceAtLeast(1.0)
    Canvas(modifier = modifier.fillMaxWidth().height(height)) {
        if (values.isEmpty()) return@Canvas
        val barWidth = size.width / (values.size * 1.6f)
        val gap = barWidth * 0.6f
        values.forEachIndexed { index, value ->
            val barHeight = (value / maxValue).toFloat() * size.height
            val x = index * (barWidth + gap) + gap / 2
            drawRoundRect(
                color = barColor,
                topLeft = Offset(x, size.height - barHeight),
                size = Size(barWidth, barHeight),
                cornerRadius = androidx.compose.ui.geometry.CornerRadius(6f, 6f)
            )
        }
    }
}

/** Simple donut chart — Android equivalent of SwiftUI Charts' SectorMark usage in the Exercise Library. */
@Composable
fun DonutChart(
    slices: List<Pair<Double, Color>>,
    modifier: Modifier = Modifier
) {
    val total = slices.sumOf { it.first }.coerceAtLeast(0.0001)
    Box(modifier = modifier.fillMaxSize()) {
        Canvas(modifier = Modifier.fillMaxSize()) {
            var startAngle = -90f
            val strokeWidth = size.minDimension * 0.22f
            slices.forEach { (value, color) ->
                val sweep = (value / total * 360f).toFloat()
                drawArc(
                    color = color,
                    startAngle = startAngle + 1.5f,
                    sweepAngle = (sweep - 3f).coerceAtLeast(0f),
                    useCenter = false,
                    style = Stroke(width = strokeWidth, cap = androidx.compose.ui.graphics.StrokeCap.Round)
                )
                startAngle += sweep
            }
        }
    }
}
