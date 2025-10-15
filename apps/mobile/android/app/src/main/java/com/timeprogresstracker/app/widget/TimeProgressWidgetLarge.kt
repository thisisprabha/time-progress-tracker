package com.timeprogresstracker.app.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import com.timeprogresstracker.app.R
import java.util.*

class TimeProgressWidgetLarge : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.time_progress_widget_large)

        // Calculate time progress
        val calendar = Calendar.getInstance()
        val currentHour = calendar.get(Calendar.HOUR_OF_DAY)
        val currentDay = calendar.get(Calendar.DAY_OF_MONTH)
        val currentMonth = calendar.get(Calendar.MONTH)
        val currentYear = calendar.get(Calendar.YEAR)
        val daysInMonth = calendar.getActualMaximum(Calendar.DAY_OF_MONTH)
        val dayOfYear = calendar.get(Calendar.DAY_OF_YEAR)
        val daysInYear = calendar.getActualMaximum(Calendar.DAY_OF_YEAR)

        // Today progress (assuming 24-hour format for now)
        val hoursLeft = 24 - currentHour
        val todayText = if (hoursLeft > 0) "$hoursLeft" + "h remaining" else "Day done"

        // Month progress
        val daysLeft = daysInMonth - currentDay + 1
        val monthText = if (daysLeft > 1) "$daysLeft days remaining" else "Month done"

        // Year progress
        val yearProgress = ((dayOfYear.toFloat() / daysInYear.toFloat()) * 100).toInt()
        val yearLeft = 100 - yearProgress
        val yearText = if (yearLeft > 0) "$yearLeft% remaining" else "Year done"

        // Update widget views
        views.setTextViewText(R.id.today_text, todayText)
        views.setTextViewText(R.id.month_text, monthText)
        views.setTextViewText(R.id.year_text, yearText)

        // Instruct the widget manager to update the widget
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
