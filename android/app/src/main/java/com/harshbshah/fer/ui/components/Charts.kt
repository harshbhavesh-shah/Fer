package com.harshbshah.fer.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.drawText
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.harshbshah.fer.util.Formatters

/**
 * Bar chart with optional axis chrome — Android equivalent of SwiftUI Charts'
 * BarMark usage on Dashboard/History. Everything (bars, gridlines, axis
 * labels, and the optional per-bar "active" dot) is drawn in a single Canvas
 * against one set of computed bar-center x-coordinates, rather than a bar
 * Canvas plus a separately laid-out label Row — a split like that is exactly
 * what caused the day-dot/bar misalignment bug in an earlier pass.
 */
@Composable
fun BarChart(
    values: List<Double>,
    modifier: Modifier = Modifier,
    barColor: Color = MaterialTheme.colorScheme.primary,
    barsHeight: Dp = 120.dp,
    xLabels: List<String> = emptyList(),
    showYAxisLabels: Boolean = false,
    activeIndicators: List<Boolean> = emptyList()
) {
    val textMeasurer = rememberTextMeasurer()
    val labelColor = MaterialTheme.colorScheme.onSurfaceVariant
    val gridColor = MaterialTheme.colorScheme.outlineVariant
    val labelStyle = MaterialTheme.typography.labelSmall.copy(color = labelColor)

    val xLabelHeight = if (xLabels.isNotEmpty()) 18.dp else 0.dp
    val dotHeight = if (activeIndicators.isNotEmpty()) 14.dp else 0.dp
    val totalHeight = barsHeight + xLabelHeight + dotHeight

    Canvas(modifier = modifier.fillMaxWidth().height(totalHeight)) {
        val maxValue = (values.maxOrNull() ?: 0.0).coerceAtLeast(1.0)
        val barsAreaHeightPx = barsHeight.toPx()

        // Measured with softWrap = false and drawn via the pre-measured
        // TextLayoutResult overload (not the convenience drawText(textMeasurer,
        // text, topLeft) form) — that convenience overload infers its own wrap
        // width from the remaining Canvas space to the right of `topLeft`,
        // which silently wrapped numbers like "753.6" mid-digit since these
        // labels are drawn close to the Canvas's right edge.
        val yAxisSteps = 4
        val yAxisValues = if (showYAxisLabels) (0..yAxisSteps).map { i -> maxValue * i / yAxisSteps } else emptyList()
        val yAxisLayouts = yAxisValues.map { textMeasurer.measure(Formatters.weight(it), labelStyle, softWrap = false) }
        val yAxisLabelWidthPx = yAxisLayouts.maxOfOrNull { it.size.width } ?: 0
        val rightMargin = if (showYAxisLabels) yAxisLabelWidthPx + 8.dp.toPx() else 0f
        val chartWidth = size.width - rightMargin

        if (showYAxisLabels) {
            yAxisValues.forEachIndexed { i, v ->
                val y = barsAreaHeightPx - (v / maxValue).toFloat() * barsAreaHeightPx
                drawLine(gridColor, Offset(0f, y), Offset(chartWidth, y), strokeWidth = 1.dp.toPx())
                val layout = yAxisLayouts[i]
                drawText(layout, topLeft = Offset(chartWidth + 8.dp.toPx(), y - layout.size.height / 2))
            }
        }

        if (values.isEmpty()) return@Canvas

        val barWidth = chartWidth / (values.size * 1.6f)
        val gap = barWidth * 0.6f
        val centers = FloatArray(values.size)
        values.forEachIndexed { index, value ->
            val barHeightPx = (value / maxValue).toFloat() * barsAreaHeightPx
            val x = index * (barWidth + gap) + gap / 2
            centers[index] = x + barWidth / 2
            drawRoundRect(
                color = barColor,
                topLeft = Offset(x, barsAreaHeightPx - barHeightPx),
                size = Size(barWidth, barHeightPx),
                cornerRadius = CornerRadius(6f, 6f)
            )
        }

        if (xLabels.isNotEmpty()) {
            xLabels.forEachIndexed { index, label ->
                if (index >= centers.size || label.isEmpty()) return@forEachIndexed
                val layout = textMeasurer.measure(label, labelStyle, softWrap = false)
                drawText(layout, topLeft = Offset(centers[index] - layout.size.width / 2, barsAreaHeightPx + 4.dp.toPx()))
            }
        }

        if (activeIndicators.isNotEmpty()) {
            val dotY = barsAreaHeightPx + xLabelHeight.toPx() + dotHeight.toPx() / 2
            activeIndicators.forEachIndexed { index, active ->
                if (index >= centers.size) return@forEachIndexed
                drawCircle(
                    color = if (active) barColor else labelColor.copy(alpha = 0.2f),
                    radius = 4.dp.toPx(),
                    center = Offset(centers[index], dotY)
                )
            }
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
            // drawArc's stroke straddles the bounding box it's given, so the
            // ring's outer edge overflows past `size` by strokeWidth/2 unless
            // the box is inset first — that overflow was what made the ring
            // crowd/touch the legend text next to it.
            val inset = strokeWidth / 2
            val arcSize = Size(size.width - strokeWidth, size.height - strokeWidth)
            val arcTopLeft = Offset(inset, inset)
            slices.forEach { (value, color) ->
                val sweep = (value / total * 360f).toFloat()
                drawArc(
                    color = color,
                    startAngle = startAngle + 1.5f,
                    sweepAngle = (sweep - 3f).coerceAtLeast(0f),
                    useCenter = false,
                    topLeft = arcTopLeft,
                    size = arcSize,
                    style = Stroke(width = strokeWidth, cap = androidx.compose.ui.graphics.StrokeCap.Round)
                )
                startAngle += sweep
            }
        }
    }
}
