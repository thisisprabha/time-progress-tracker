package com.timeprogresstracker.app.widget

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log

object WidgetUpdateHelper {
    
    private val TAG = "WidgetUpdateHelper"
    
    /**
     * Triggers widget update when settings change
     */
    fun updateWidgets(context: Context) {
        Log.d(TAG, "updateWidgets called")
        val appWidgetManager = AppWidgetManager.getInstance(context)
        
        // Update light widgets
        val lightWidgetProvider = ComponentName(context, TimeProgressWidgetLarge::class.java)
        val lightAppWidgetIds = appWidgetManager.getAppWidgetIds(lightWidgetProvider)
        
        Log.d(TAG, "Found ${lightAppWidgetIds.size} light widget instances")
        
        if (lightAppWidgetIds.isNotEmpty()) {
            val lightIntent = Intent(context, TimeProgressWidgetLarge::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, lightAppWidgetIds)
            }
            Log.d(TAG, "Sending light widget update broadcast")
            context.sendBroadcast(lightIntent)
        }
        
        // Update dark widgets
        val darkWidgetProvider = ComponentName(context, TimeProgressWidgetDark::class.java)
        val darkAppWidgetIds = appWidgetManager.getAppWidgetIds(darkWidgetProvider)
        
        Log.d(TAG, "Found ${darkAppWidgetIds.size} dark widget instances")
        
        if (darkAppWidgetIds.isNotEmpty()) {
            val darkIntent = Intent(context, TimeProgressWidgetDark::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, darkAppWidgetIds)
            }
            Log.d(TAG, "Sending dark widget update broadcast")
            context.sendBroadcast(darkIntent)
        }
        
        if (lightAppWidgetIds.isEmpty() && darkAppWidgetIds.isEmpty()) {
            Log.w(TAG, "No widgets found to update")
        }
    }
}
