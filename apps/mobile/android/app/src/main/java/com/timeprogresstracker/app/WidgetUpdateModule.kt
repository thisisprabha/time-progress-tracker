package com.timeprogresstracker.app

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
    fun updateWidgets() {
        Log.d(TAG, "updateWidgets called from React Native")
        WidgetUpdateHelper.updateWidgets(reactApplicationContext)
    }
}
