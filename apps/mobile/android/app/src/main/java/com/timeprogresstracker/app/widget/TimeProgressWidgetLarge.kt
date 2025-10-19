package com.timeprogresstracker.app.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.RemoteViews
import com.timeprogresstracker.app.MainActivity
import com.timeprogresstracker.app.R
import java.util.Calendar

class TimeProgressWidgetLarge : AppWidgetProvider() {

    private val TAG = "TimeProgressWidgetLarge"

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
        Log.d(TAG, "updateAppWidget called for widget $appWidgetId")
        val views = RemoteViews(context.packageName, R.layout.time_progress_widget_large)

        // Read settings from SharedPreferences
        val prefs = context.getSharedPreferences("RKStorage", Context.MODE_PRIVATE)
        val perspective = prefs.getString("userPerspective", "half-empty") ?: "half-empty"
        val timeMode = prefs.getString("timeMode", "24h") ?: "24h"
        val customEventsJson = prefs.getString("customEvents", "[]") ?: "[]"
        
        Log.d(TAG, "Settings read - Perspective: $perspective, TimeMode: $timeMode, CustomEvents: $customEventsJson")
        
        // Parse custom events with better error handling
        val customEvents = try {
            if (customEventsJson == "[]" || customEventsJson.isEmpty()) {
                emptyList()
            } else {
                // Use a more robust JSON parsing approach
                val events = mutableListOf<Pair<String, String>>()
                val jsonArray = customEventsJson.removeSurrounding("[", "]")
                
                if (jsonArray.isNotEmpty()) {
                    // Split by "},{"
                    val eventStrings = jsonArray.split("},{")
                    for (eventStr in eventStrings) {
                        try {
                            val cleanStr = eventStr.removeSurrounding("{", "}")
                            val nameMatch = Regex("\"name\":\"([^\"]+)\"").find(cleanStr)
                            val dateMatch = Regex("\"date\":\"([^\"]+)\"").find(cleanStr)
                            
                            if (nameMatch != null && dateMatch != null) {
                                val name = nameMatch.groupValues[1]
                                val date = dateMatch.groupValues[1]
                                events.add(Pair(name, date))
                                Log.d(TAG, "Parsed event: name=$name, date=$date")
                            } else {
                                Log.w(TAG, "Failed to parse event: $eventStr")
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Error parsing individual event: ${e.message}")
                        }
                    }
                }
                events
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing custom events: ${e.message}")
            emptyList()
        }
        
        Log.d(TAG, "Parsed custom events: $customEvents")
        
        // Get selected display items (default to today, month, year)
        val selectedItemsJson = prefs.getString("selectedDisplayItems", null)
        Log.d(TAG, "SelectedDisplayItems JSON: $selectedItemsJson")
        
        val selectedItems = if (selectedItemsJson != null) {
            try {
                selectedItemsJson
                    .removeSurrounding("[", "]")
                    .split(",")
                    .map { it.trim().removeSurrounding("\"") }
                    .take(3) // Show up to 3 items
            } catch (e: Exception) {
                Log.e(TAG, "Error parsing selectedDisplayItems: ${e.message}")
                listOf("today", "month", "year")
            }
        } else {
            listOf("today", "month", "year")
        }
        
        Log.d(TAG, "Selected items: $selectedItems")

        // Calculate current time data
        val calendar = Calendar.getInstance()
        val currentHour = calendar.get(Calendar.HOUR_OF_DAY)
        val currentDay = calendar.get(Calendar.DAY_OF_MONTH)
        val daysInMonth = calendar.getActualMaximum(Calendar.DAY_OF_MONTH)
        val dayOfYear = calendar.get(Calendar.DAY_OF_YEAR)
        val daysInYear = calendar.getActualMaximum(Calendar.DAY_OF_YEAR)
        val dayOfWeek = calendar.get(Calendar.DAY_OF_WEEK)
        val daysSinceMonday = if (dayOfWeek == Calendar.SUNDAY) 6 else dayOfWeek - Calendar.MONDAY
        val quarterNumber = (calendar.get(Calendar.MONTH) / 3) + 1

        // Generate content lines - clean style like main screen
        val lines = mutableListOf<Pair<String, Boolean>>()
        selectedItems.forEach { item ->
            val text = when (item) {
                "today" -> {
                    if (timeMode == "9-5") {
                        val officeHoursCompleted = when {
                            currentHour < 9 -> 0
                            currentHour >= 17 -> 8
                            else -> currentHour - 9
                        }
                        val officeHoursLeft = 8 - officeHoursCompleted
                        
                        if (perspective == "half-full") {
                            if (officeHoursCompleted > 0) "${officeHoursCompleted}h done today" else "Day starting"
                        } else {
                            if (officeHoursLeft > 0) "${officeHoursLeft}h left today" else "Day done"
                        }
                    } else {
                        val hoursCompleted = currentHour
                        val hoursLeft = 24 - currentHour
                        
                        if (perspective == "half-full") {
                            if (hoursCompleted > 0) "${hoursCompleted}h done today" else "Day starting"
                        } else {
                            if (hoursLeft > 0) "${hoursLeft}h left today" else "Day done"
                        }
                    }
                }
                "week" -> {
                    val daysLeft = 7 - daysSinceMonday
                    if (perspective == "half-full") {
                        if (daysSinceMonday > 0) "$daysSinceMonday days done this week" else "Week starting"
                    } else {
                        if (daysLeft > 0) "$daysLeft days left this week" else "Week done"
                    }
                }
                "month" -> {
                    val daysCrossed = currentDay - 1
                    val daysLeft = daysInMonth - currentDay + 1
                    if (perspective == "half-full") {
                        if (daysCrossed > 0) "$daysCrossed days done this month" else "Month starting"
                    } else {
                        if (daysLeft > 1) "$daysLeft days left this month" else "Month done"
                    }
                }
                "quarter" -> {
                    // Calculate actual quarter progress
                    val quarterStartMonth = (quarterNumber - 1) * 3
                    val quarterStartDay = 1
                    val quarterStartCalendar = Calendar.getInstance().apply {
                        set(Calendar.MONTH, quarterStartMonth)
                        set(Calendar.DAY_OF_MONTH, quarterStartDay)
                    }
                    
                    val daysSinceQuarterStart = ((calendar.timeInMillis - quarterStartCalendar.timeInMillis) / (1000 * 60 * 60 * 24)).toInt()
                    val quarterWeeksCompleted = daysSinceQuarterStart / 7
                    val quarterWeeksLeft = 13 - quarterWeeksCompleted
                    
                    if (perspective == "half-full") {
                        if (quarterWeeksCompleted > 0) "$quarterWeeksCompleted weeks done Q$quarterNumber" else "Q$quarterNumber starting"
                    } else {
                        if (quarterWeeksLeft > 0) "$quarterWeeksLeft weeks left Q$quarterNumber" else "Q$quarterNumber done"
                    }
                }
                "year" -> {
                    val yearProgress = ((dayOfYear.toFloat() / daysInYear.toFloat()) * 100).toInt()
                    if (perspective == "half-full") {
                        if (yearProgress > 0) "$yearProgress% done this year" else "Year starting"
                    } else {
                        val yearLeft = 100 - yearProgress
                        if (yearLeft > 0) "$yearLeft% left this year" else "Year done"
                    }
                }
                "custom" -> {
                    // For custom events, show actual event details
                    if (customEvents.isNotEmpty()) {
                        val event = customEvents.first() // Show first event
                        val eventDate = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.getDefault()).parse(event.second)
                        val today = java.util.Calendar.getInstance()
                        val daysDiff = ((eventDate.time - today.timeInMillis) / (1000 * 60 * 60 * 24)).toInt()
                        
                        if (daysDiff > 0) {
                            "${daysDiff} days for ${event.first}"
                        } else if (daysDiff == 0) {
                            "Today: ${event.first}"
                        } else {
                            "${-daysDiff} days since ${event.first}"
                        }
                    } else {
                        "No custom events"
                    }
                }
                else -> "Unknown"
            }
            
            lines.add(text to false) // Each line is not bold
        }

        // Add additional custom events if there are more than one
        if (customEvents.size > 1) {
            customEvents.drop(1).forEach { event ->
                val eventDate = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.getDefault()).parse(event.second)
                val today = java.util.Calendar.getInstance()
                val daysDiff = ((eventDate.time - today.timeInMillis) / (1000 * 60 * 60 * 24)).toInt()
                
                val eventText = if (daysDiff > 0) {
                    "${daysDiff} days for ${event.first}"
                } else if (daysDiff == 0) {
                    "Today: ${event.first}"
                } else {
                    "${-daysDiff} days since ${event.first}"
                }
                
                lines.add(eventText to false)
            }
        }

        // Create bitmap with multi-line support
        val bitmap = TextBitmapUtils.createMultiLineTextBitmap(
            context = context,
            lines = lines,
            textSize = 20f, // Smaller text size for widget
            textColor = android.graphics.Color.BLACK,
            maxWidth = 350
        )

        // Update widget
        views.setImageViewBitmap(R.id.widget_content_image, bitmap)

        // Add click intent to open app
        val intent = Intent(context, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            context, 
            0, 
            intent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_container_large, pendingIntent)

        // Update widget
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}