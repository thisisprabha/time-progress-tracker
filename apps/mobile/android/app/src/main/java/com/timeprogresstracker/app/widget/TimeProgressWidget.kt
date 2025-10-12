package com.timeprogresstracker.app.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.LinearLayout
import android.widget.RemoteViews
import android.widget.TextView
import com.timeprogresstracker.app.MainActivity
import com.timeprogresstracker.app.R
import java.util.*

class TimeProgressWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        // Enter relevant functionality for when the first widget is created
    }

    override fun onDisabled(context: Context) {
        // Enter relevant functionality for when the last widget is disabled
    }

    companion object {
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val views = RemoteViews(context.packageName, R.layout.time_progress_widget)
            
            // Calculate time progress
            val timeData = calculateTimeProgress(context)
            
            // Update Today progress
            views.setTextViewText(R.id.today_label, "Today")
            views.setTextViewText(R.id.today_text, getProgressText(timeData.todayCompleted, timeData.todayTotal, "h", timeData.perspective))
            
            // Update Month progress
            views.setTextViewText(R.id.month_label, "This Month")
            views.setTextViewText(R.id.month_text, getProgressText(timeData.monthCompleted, timeData.monthTotal, " days", timeData.perspective))
            
            // Update Year progress
            views.setTextViewText(R.id.year_label, "This Year")
            views.setTextViewText(R.id.year_text, getProgressText(timeData.yearCompleted, timeData.yearTotal, " days", timeData.perspective))
            
            // Create tally marks for each section
            createTallyMarks(context, views, timeData)
            
            // Set click intent to open app
            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
        
        private fun createTallyMarks(context: Context, views: RemoteViews, timeData: TimeData) {
            // Create Today tally marks
            createTallyMarksForSection(context, views, R.id.today_completed_marks, R.id.today_remaining_marks, timeData.todayCompleted, timeData.todayTotal)
            
            // Create Month tally marks
            createTallyMarksForSection(context, views, R.id.month_completed_marks, R.id.month_remaining_marks, timeData.monthCompleted, timeData.monthTotal)
            
            // Create Year tally marks
            createTallyMarksForSection(context, views, R.id.year_completed_marks, R.id.year_remaining_marks, timeData.yearCompleted, timeData.yearTotal)
        }
        
        private fun createTallyMarksForSection(context: Context, views: RemoteViews, completedContainerId: Int, remainingContainerId: Int, completed: Int, total: Int) {
            val remaining = total - completed
            
            // Clear existing views
            views.removeAllViews(completedContainerId)
            views.removeAllViews(remainingContainerId)
            
            // Add completed marks (X marks) - limit to 20 for display, slightly duller
            val maxDisplay = 20
            val completedToShow = minOf(completed, maxDisplay)
            for (i in 0 until completedToShow) {
                val textView = TextView(context).apply {
                    text = "✗"
                    textSize = 12f
                    setTextColor(context.getColor(android.R.color.black).withAlpha(153)) // 60% opacity
                    typeface = android.graphics.Typeface.DEFAULT
                }
                views.addView(completedContainerId, textView)
            }
            
            // Add remaining marks (I marks) - limit to 20 for display, full opacity
            val remainingToShow = minOf(remaining, maxDisplay)
            for (i in 0 until remainingToShow) {
                val textView = TextView(context).apply {
                    text = "|"
                    textSize = 12f
                    setTextColor(context.getColor(android.R.color.black)) // Full opacity
                    typeface = android.graphics.Typeface.DEFAULT
                }
                views.addView(remainingContainerId, textView)
            }
        }
        
        private fun calculateTimeProgress(context: Context): TimeData {
            val now = Calendar.getInstance()
            
            // Load settings from SharedPreferences
            val prefs = context.getSharedPreferences("TimeProgressPrefs", Context.MODE_PRIVATE)
            val perspective = prefs.getString("userPerspective", "optimistic") ?: "optimistic"
            val timeMode = prefs.getString("timeMode", "24h") ?: "24h"
            
            // Today calculation
            val startOfDay = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            
            var todayCompleted: Double
            var todayTotal: Int
            
            if (timeMode == "9-5") {
                // 9 AM to 5 PM (8 hours)
                val workStart = Calendar.getInstance().apply {
                    set(Calendar.HOUR_OF_DAY, 9)
                    set(Calendar.MINUTE, 0)
                    set(Calendar.SECOND, 0)
                    set(Calendar.MILLISECOND, 0)
                }
                val workEnd = Calendar.getInstance().apply {
                    set(Calendar.HOUR_OF_DAY, 17)
                    set(Calendar.MINUTE, 0)
                    set(Calendar.SECOND, 0)
                    set(Calendar.MILLISECOND, 0)
                }
                
                todayCompleted = when {
                    now.before(workStart) -> 0.0
                    now.after(workEnd) -> 8.0
                    else -> (now.timeInMillis - workStart.timeInMillis) / (1000.0 * 60 * 60)
                }
                todayTotal = 8
            } else {
                // 24 hours
                todayCompleted = (now.timeInMillis - startOfDay.timeInMillis) / (1000.0 * 60 * 60)
                todayTotal = 24
            }
            
            // Month calculation
            val startOfMonth = Calendar.getInstance().apply {
                set(Calendar.DAY_OF_MONTH, 1)
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            val endOfMonth = Calendar.getInstance().apply {
                add(Calendar.MONTH, 1)
                set(Calendar.DAY_OF_MONTH, 1)
                add(Calendar.DAY_OF_MONTH, -1)
            }
            
            val monthCompleted = now.get(Calendar.DAY_OF_MONTH) - 1
            val monthTotal = endOfMonth.get(Calendar.DAY_OF_MONTH)
            
            // Year calculation
            val startOfYear = Calendar.getInstance().apply {
                set(Calendar.MONTH, Calendar.JANUARY)
                set(Calendar.DAY_OF_MONTH, 1)
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            val endOfYear = Calendar.getInstance().apply {
                set(Calendar.MONTH, Calendar.DECEMBER)
                set(Calendar.DAY_OF_MONTH, 31)
            }
            
            val yearCompleted = now.get(Calendar.DAY_OF_YEAR) - 1
            val yearTotal = if (now.isLeapYear(now.get(Calendar.YEAR))) 366 else 365
            
            val todayProgress = minOf((todayCompleted / todayTotal) * 100, 100.0)
            val monthProgress = minOf((monthCompleted.toDouble() / monthTotal) * 100, 100.0)
            val yearProgress = minOf((yearCompleted.toDouble() / yearTotal) * 100, 100.0)
            
            return TimeData(
                todayProgress = todayProgress,
                monthProgress = monthProgress,
                yearProgress = yearProgress,
                todayCompleted = todayCompleted.toInt(),
                todayTotal = todayTotal,
                monthCompleted = monthCompleted,
                monthTotal = monthTotal,
                yearCompleted = yearCompleted,
                yearTotal = yearTotal,
                perspective = perspective,
                timeMode = timeMode
            )
        }
        
        private fun getProgressText(completed: Int, total: Int, unit: String, perspective: String): String {
            return if (perspective == "pessimistic") {
                val remaining = total - completed
                "$remaining$unit left"
            } else {
                val remaining = total - completed
                "$remaining$unit left"
            }
        }
        
        private fun Calendar.isLeapYear(year: Int): Boolean {
            return year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
        }
    }
}

data class TimeData(
    val todayProgress: Double,
    val monthProgress: Double,
    val yearProgress: Double,
    val todayCompleted: Int,
    val todayTotal: Int,
    val monthCompleted: Int,
    val monthTotal: Int,
    val yearCompleted: Int,
    val yearTotal: Int,
    val perspective: String,
    val timeMode: String
)