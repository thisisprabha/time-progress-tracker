package com.timeprogresstracker.app

import android.content.Context
import android.util.Log
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.timeprogresstracker.app.widget.WidgetUpdateHelper

class WidgetUpdateModule(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {

    private val TAG = "WidgetUpdateModule"

    override fun getName(): String {
        return "WidgetUpdateModule"
    }

    @ReactMethod
    fun syncSettingsToSharedPreferences(userPerspective: String, timeMode: String, selectedDisplayItems: String, customEvents: String) {
        Log.d(TAG, "syncSettingsToSharedPreferences called from React Native")
        Log.d(TAG, "Settings to sync - Perspective: $userPerspective, TimeMode: $timeMode, DisplayItems: $selectedDisplayItems, CustomEvents: $customEvents")
        
        try {
            val prefs = reactApplicationContext.getSharedPreferences("RKStorage", Context.MODE_PRIVATE)
            val editor = prefs.edit()
            
            editor.putString("userPerspective", userPerspective)
            editor.putString("timeMode", timeMode)
            editor.putString("selectedDisplayItems", selectedDisplayItems)
            editor.putString("customEvents", customEvents)
            
            val success = editor.commit()
            Log.d(TAG, "Settings synced to SharedPreferences: $success")
            
            // Verify the save worked
            val savedPerspective = prefs.getString("userPerspective", null)
            val savedTimeMode = prefs.getString("timeMode", null)
            val savedDisplayItems = prefs.getString("selectedDisplayItems", null)
            val savedCustomEvents = prefs.getString("customEvents", null)
            Log.d(TAG, "Verification - Saved: Perspective=$savedPerspective, TimeMode=$savedTimeMode, DisplayItems=$savedDisplayItems, CustomEvents=$savedCustomEvents")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error syncing settings to SharedPreferences: ${e.message}")
        }
    }

    @ReactMethod
    fun updateWidgets() {
        Log.d(TAG, "updateWidgets called from React Native")
        WidgetUpdateHelper.updateWidgets(reactApplicationContext)
    }
}
