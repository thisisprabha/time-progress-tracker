package com.timeprogresstracker.app.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import com.timeprogresstracker.app.R
import java.util.*

class TimeProgressWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // There may be multiple widgets active, so update all of them
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        // Calculate time progress
        val calendar = Calendar.getInstance()
        val currentHour = calendar.get(Calendar.HOUR_OF_DAY)
        val hoursLeft = 24 - currentHour
        
        val dayOfMonth = calendar.get(Calendar.DAY_OF_MONTH)
        val maxDaysInMonth = calendar.getActualMaximum(Calendar.DAY_OF_MONTH)
        val daysLeftInMonth = maxDaysInMonth - dayOfMonth
        
        // Create RemoteViews object
        val views = RemoteViews(context.packageName, R.layout.time_progress_widget_simple)
        
        // Update the widget text
        views.setTextViewText(R.id.today_text, "${hoursLeft}h left")
        views.setTextViewText(R.id.month_text, "${daysLeftInMonth} days left")
        
        // Instruct the widget manager to update the widget
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
