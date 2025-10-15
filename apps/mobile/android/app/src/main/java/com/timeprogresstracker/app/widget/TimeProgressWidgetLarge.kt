package com.timeprogresstracker.app.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.timeprogresstracker.app.MainActivity
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

        // Read app settings from SharedPreferences (same as AsyncStorage)
        val prefs = context.getSharedPreferences("RKStorage", Context.MODE_PRIVATE)
        val perspective = prefs.getString("userPerspective", "half-empty") ?: "half-empty"
        val timeMode = prefs.getString("timeMode", "24h") ?: "24h"

        // Calculate time progress
        val calendar = Calendar.getInstance()
        val currentHour = calendar.get(Calendar.HOUR_OF_DAY)
        val currentDay = calendar.get(Calendar.DAY_OF_MONTH)
        val daysInMonth = calendar.getActualMaximum(Calendar.DAY_OF_MONTH)
        val dayOfYear = calendar.get(Calendar.DAY_OF_YEAR)
        val daysInYear = calendar.getActualMaximum(Calendar.DAY_OF_YEAR)

        // Today progress based on time mode and perspective
        val todayText = if (timeMode == "9-5") {
            // Office hours (9 AM to 5 PM = 8 hours)
            val officeHoursCompleted = when {
                currentHour < 9 -> 0
                currentHour >= 17 -> 8
                else -> currentHour - 9
            }
            val officeHoursLeft = 8 - officeHoursCompleted
            
            if (perspective == "half-full") {
                if (officeHoursCompleted > 0) "${officeHoursCompleted}h done" else "Day starting"
            } else {
                if (officeHoursLeft > 0) "${officeHoursLeft}h remaining" else "Day done"
            }
        } else {
            // 24-hour format
            val hoursCompleted = currentHour
            val hoursLeft = 24 - currentHour
            
            if (perspective == "half-full") {
                if (hoursCompleted > 0) "${hoursCompleted}h done" else "Day starting"
            } else {
                if (hoursLeft > 0) "${hoursLeft}h remaining" else "Day done"
            }
        }

        // Month progress based on perspective
        val daysCrossed = currentDay - 1
        val daysLeft = daysInMonth - currentDay + 1
        val monthText = if (perspective == "half-full") {
            if (daysCrossed > 0) "$daysCrossed days done" else "Month starting"
        } else {
            if (daysLeft > 1) "$daysLeft days remaining" else "Month done"
        }

        // Year progress based on perspective
        val yearProgress = ((dayOfYear.toFloat() / daysInYear.toFloat()) * 100).toInt()
        val yearCompleted = yearProgress
        val yearLeft = 100 - yearProgress
        val yearText = if (perspective == "half-full") {
            if (yearCompleted > 0) "$yearCompleted% done" else "Year starting"
        } else {
            if (yearLeft > 0) "$yearLeft% remaining" else "Year done"
        }

        // Create bitmap with custom font for large widget (label left, value right format)
        val content = buildString {
            appendLine("Today                    $todayText")
            appendLine("This Month               $monthText")  
            append("This Year                $yearText")
        }
        
        val bitmap = TextBitmapUtils.createTextBitmap(
            context = context,
            text = content,
            textSize = 28f,
            textColor = android.graphics.Color.BLACK,
            maxWidth = 350,
            maxHeight = 120
        )
        
        // Update widget view with bitmap
        views.setImageViewBitmap(R.id.widget_content_image, bitmap)

        // Add click intent to open the app
        val intent = Intent(context, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            context, 
            0, 
            intent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_container_large, pendingIntent)

        // Instruct the widget manager to update the widget
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
