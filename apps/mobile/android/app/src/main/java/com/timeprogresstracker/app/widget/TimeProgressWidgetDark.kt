package com.timeprogresstracker.app.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.RemoteViews
import com.timeprogresstracker.app.MainActivity
import com.timeprogresstracker.app.R
import java.util.Calendar

class TimeProgressWidgetDark : AppWidgetProvider() {

    private val TAG = "TimeProgressWidgetDark"

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        Log.d(TAG, "onUpdate called with ${appWidgetIds.size} widget IDs")
        for (appWidgetId in appWidgetIds) {
            Log.d(TAG, "Updating widget $appWidgetId")
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }
    
    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        Log.d(TAG, "onEnabled called - widget provider enabled")
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        Log.d(TAG, "onReceive called with action: ${intent.action}")
        if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, TimeProgressWidgetDark::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            Log.d(TAG, "Received update broadcast for ${appWidgetIds.size} widgets")
            onUpdate(context, appWidgetManager, appWidgetIds)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        Log.d(TAG, "updateAppWidget called for widget $appWidgetId")
        val views = RemoteViews(context.packageName, R.layout.time_progress_widget_dark)

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

        // Expand custom items to show all custom events (matching home screen behavior)
        val expandedItems = mutableListOf<String>()
        var customEventIndex = 0
        selectedItems.forEach { item ->
            if (item.startsWith("custom_")) {
                // Extract event ID from "custom_<id>" format (iOS format)
                // Since Android widget doesn't have event IDs, match by index
                if (customEventIndex < customEvents.size) {
                    val event = customEvents[customEventIndex]
                    expandedItems.add("custom_event:${event.first}:${event.second}")
                    customEventIndex++
                }
            } else if (item == "custom") {
                // Legacy format: expand custom to show all custom events
                customEvents.forEach { expandedItems.add("custom_event:${it.first}:${it.second}") }
            } else {
                expandedItems.add(item)
            }
        }

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

        // Helper function to add double spaces between words
        fun addDoubleSpaces(text: String): String {
            return text.replace(" ", "  ")
        }
        
        // Generate label-value pairs - simple format: label (left, regular) + value (right, bold)
        val itemsToProcess = if (expandedItems.isEmpty()) {
            Log.w(TAG, "expandedItems is empty, using default items")
            listOf("today", "month", "year")
        } else {
            expandedItems
        }
        
        val labelValuePairs = mutableListOf<Pair<String, String>>()
        Log.d(TAG, "Processing ${itemsToProcess.size} items for widget")
        itemsToProcess.forEach { item ->
            val (label, value) = when {
                item.startsWith("custom_event:") -> {
                    // Parse custom event from expanded format
                    val parts = item.removePrefix("custom_event:").split(":", limit = 2)
                    if (parts.size == 2) {
                        val eventName = parts[0]
                        val eventDateStr = parts[1]
                        val eventDate = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.getDefault()).parse(eventDateStr)
                        
                        // Normalize both dates to start of day to match app calculation
                        val eventCal = java.util.Calendar.getInstance()
                        eventCal.time = eventDate
                        eventCal.set(java.util.Calendar.HOUR_OF_DAY, 0)
                        eventCal.set(java.util.Calendar.MINUTE, 0)
                        eventCal.set(java.util.Calendar.SECOND, 0)
                        eventCal.set(java.util.Calendar.MILLISECOND, 0)
                        
                        val todayCal = java.util.Calendar.getInstance()
                        todayCal.set(java.util.Calendar.HOUR_OF_DAY, 0)
                        todayCal.set(java.util.Calendar.MINUTE, 0)
                        todayCal.set(java.util.Calendar.SECOND, 0)
                        todayCal.set(java.util.Calendar.MILLISECOND, 0)
                        
                        val daysDiff = kotlin.math.round((eventCal.timeInMillis - todayCal.timeInMillis).toDouble() / (1000 * 60 * 60 * 24)).toInt()
                        
                        val useWeeks = daysDiff > 30
                        if (useWeeks) {
                            val weeksLeft = kotlin.math.round(daysDiff / 7.0).toInt()
                            if (daysDiff > 0) {
                                Pair(addDoubleSpaces(eventName), "${weeksLeft}wk")
                            } else if (daysDiff == 0) {
                                Pair(addDoubleSpaces(eventName), "Today")
                            } else {
                                Pair(addDoubleSpaces(eventName), "${kotlin.math.round(-daysDiff / 7.0).toInt()}wk  ago")
                            }
                        } else {
                            if (daysDiff > 0) {
                                Pair(addDoubleSpaces(eventName), "${daysDiff}d")
                            } else if (daysDiff == 0) {
                                Pair(addDoubleSpaces(eventName), "Today")
                            } else {
                                Pair(addDoubleSpaces(eventName), "${-daysDiff}d  ago")
                            }
                        }
                    } else {
                        Pair("Custom  event", "")
                    }
                }
                item == "today" -> {
                    if (timeMode == "9-5") {
                        val officeHoursCompleted = when {
                            currentHour < 9 -> 0
                            currentHour >= 17 -> 8
                            else -> currentHour - 9
                        }
                        val officeHoursLeft = 8 - officeHoursCompleted
                        
                        if (perspective == "half-full") {
                            if (officeHoursCompleted > 0) Pair("Today", "${officeHoursCompleted}hrs  gone") else Pair("Today", "Starting")
                        } else {
                            if (officeHoursLeft > 0) Pair("Today", "${officeHoursLeft}hrs  only  left") else Pair("Today", "Done")
                        }
                    } else {
                        val hoursCompleted = currentHour
                        val hoursLeft = 24 - currentHour
                        
                        if (perspective == "half-full") {
                            if (hoursCompleted > 0) Pair("Today", "${hoursCompleted}hrs  gone") else Pair("Today", "Starting")
                        } else {
                            if (hoursLeft > 0) Pair("Today", "${hoursLeft}hrs  only  left") else Pair("Today", "Done")
                        }
                    }
                }
                item == "week" -> {
                    val daysLeft = 7 - daysSinceMonday
                    if (perspective == "half-full") {
                        if (daysSinceMonday > 0) Pair("This  Week", "${daysSinceMonday}d  gone") else Pair("This  Week", "Starting")
                    } else {
                        if (daysLeft > 0) Pair("This  Week", "${daysLeft}d  only  left") else Pair("This  Week", "Done")
                    }
                }
                item == "month" -> {
                    val daysCrossed = currentDay - 1
                    val daysLeft = daysInMonth - currentDay + 1
                    if (perspective == "half-full") {
                        if (daysCrossed > 0) Pair("This  Month", "${daysCrossed}d  gone") else Pair("This  Month", "Starting")
                    } else {
                        if (daysLeft > 1) Pair("This  Month", "${daysLeft}d  only  left") else Pair("This  Month", "Done")
                    }
                }
                item == "quarter" -> {
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
                        if (quarterWeeksCompleted > 0) Pair("Q$quarterNumber", "${quarterWeeksCompleted}wk  gone") else Pair("Q$quarterNumber", "Starting")
                    } else {
                        if (quarterWeeksLeft > 0) Pair("Q$quarterNumber", "${quarterWeeksLeft}wk  only  left") else Pair("Q$quarterNumber", "Done")
                    }
                }
                item == "year" -> {
                    val yearProgress = ((dayOfYear.toFloat() / daysInYear.toFloat()) * 100).toInt()
                    if (perspective == "half-full") {
                        if (yearProgress > 0) Pair("This  Year", "$yearProgress%  gone") else Pair("This  Year", "Starting")
                    } else {
                        val yearLeft = 100 - yearProgress
                        if (yearLeft > 0) Pair("This  Year", "$yearLeft%  only  left") else Pair("This  Year", "Done")
                    }
                }
                else -> Pair("Unknown", "")
            }
            
            labelValuePairs.add(Pair(label, value))
        }
        
        // Safety check: ensure we have at least one pair
        if (labelValuePairs.isEmpty()) {
            Log.w(TAG, "No pairs generated, adding default")
            labelValuePairs.add(Pair("Time  Progress  Tracker", ""))
        }
        
        Log.d(TAG, "Generated ${labelValuePairs.size} pairs for widget")

        // Get widget size to adjust text size dynamically
        val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
        val minWidthDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
        // Convert dp to pixels (density-independent pixels)
        val density = context.resources.displayMetrics.density
        var widgetWidthPx = (minWidthDp * density).toInt()
        
        // Safety check: ensure width is valid
        if (widgetWidthPx <= 0) {
            Log.w(TAG, "Invalid widget width: $widgetWidthPx, using default 300px")
            widgetWidthPx = 300 // Default width in pixels
        }
        
        Log.d(TAG, "Widget width: ${minWidthDp}dp = ${widgetWidthPx}px")
        
        // Adjust text size - make smaller for widgets
        val baseTextSize = 40f // Reduced from 44.8f
        val adjustedTextSize = when {
            minWidthDp > 600 -> 32f // Smaller for very large widgets
            minWidthDp > 400 -> 36f // Medium for large widgets
            else -> baseTextSize
        }
        
        // Create bitmap with simple label-value format - WHITE TEXT for dark theme
        val bitmap = TextBitmapUtils.createMultiLabelValueBitmap(
            context = context,
            items = labelValuePairs,
            textSize = adjustedTextSize,
            textColor = android.graphics.Color.WHITE, // WHITE TEXT for dark theme
            backgroundColor = android.graphics.Color.TRANSPARENT,
            maxWidth = widgetWidthPx,
            lineHeightMultiplier = 1.2f
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
        views.setOnClickPendingIntent(R.id.widget_container_dark, pendingIntent)

        // Update widget
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
