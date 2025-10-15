package com.timeprogresstracker.app.widget

import android.content.Context
import android.graphics.*
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable

object TextBitmapUtils {
    
    /**
     * Creates a bitmap with custom font text
     */
    fun createTextBitmap(
        context: Context,
        text: String,
        textSize: Float,
        textColor: Int = Color.BLACK,
        backgroundColor: Int = Color.TRANSPARENT,
        isBold: Boolean = false,
        maxWidth: Int = 300,
        maxHeight: Int = 100
    ): Bitmap {
        // Create paint with custom font
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.textSize = textSize
            this.color = textColor
            this.textAlign = Paint.Align.LEFT
            
            // Try to load custom font, fallback to serif if not available
            try {
                val fontName = if (isBold) "fonts/Kalam-Bold.ttf" else "fonts/Kalam-Regular.ttf"
                val typeface = Typeface.createFromAsset(context.assets, fontName)
                this.typeface = typeface
            } catch (e: Exception) {
                // Fallback to serif font if custom font not available
                this.typeface = if (isBold) Typeface.DEFAULT_BOLD else Typeface.SERIF
            }
        }
        
        // Measure text dimensions
        val bounds = Rect()
        paint.getTextBounds(text, 0, text.length, bounds)
        
        // Calculate bitmap dimensions with padding
        val padding = 8
        val bitmapWidth = minOf(bounds.width() + padding * 2, maxWidth)
        val bitmapHeight = minOf(bounds.height() + padding * 2, maxHeight)
        
        // Create bitmap and canvas
        val bitmap = Bitmap.createBitmap(bitmapWidth, bitmapHeight, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        
        // Fill background if not transparent
        if (backgroundColor != Color.TRANSPARENT) {
            canvas.drawColor(backgroundColor)
        }
        
        // Calculate text position (centered)
        val x = padding.toFloat()
        val y = (bitmapHeight / 2 - bounds.centerY()).toFloat()
        
        // Draw text
        canvas.drawText(text, x, y, paint)
        
        return bitmap
    }
    
    /**
     * Creates a multi-line text bitmap for widget content
     */
    fun createMultiLineTextBitmap(
        context: Context,
        lines: List<Pair<String, Boolean>>, // (text, isBold)
        textSize: Float,
        textColor: Int = Color.BLACK,
        backgroundColor: Int = Color.TRANSPARENT,
        maxWidth: Int = 300
    ): Bitmap {
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.textSize = textSize
            this.color = textColor
            this.textAlign = Paint.Align.LEFT
        }
        
        // Calculate total height needed
        var totalHeight = 0
        var maxLineWidth = 0
        val lineHeights = mutableListOf<Int>()
        
        lines.forEach { (text, isBold) ->
            // Set font for measurement
            try {
                val fontName = if (isBold) "fonts/Kalam-Bold.ttf" else "fonts/Kalam-Regular.ttf"
                paint.typeface = Typeface.createFromAsset(context.assets, fontName)
            } catch (e: Exception) {
                paint.typeface = if (isBold) Typeface.DEFAULT_BOLD else Typeface.SERIF
            }
            
            val bounds = Rect()
            paint.getTextBounds(text, 0, text.length, bounds)
            
            val lineHeight = bounds.height() + 8 // Add line spacing
            lineHeights.add(lineHeight)
            totalHeight += lineHeight
            maxLineWidth = maxOf(maxLineWidth, bounds.width())
        }
        
        // Create bitmap
        val padding = 12
        val bitmapWidth = minOf(maxLineWidth + padding * 2, maxWidth)
        val bitmapHeight = totalHeight + padding * 2
        
        val bitmap = Bitmap.createBitmap(bitmapWidth, bitmapHeight, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        
        // Fill background
        if (backgroundColor != Color.TRANSPARENT) {
            canvas.drawColor(backgroundColor)
        }
        
        // Draw each line
        var currentY = padding.toFloat()
        lines.forEachIndexed { index, (text, isBold) ->
            // Set font for this line
            try {
                val fontName = if (isBold) "fonts/Kalam-Bold.ttf" else "fonts/Kalam-Regular.ttf"
                paint.typeface = Typeface.createFromAsset(context.assets, fontName)
            } catch (e: Exception) {
                paint.typeface = if (isBold) Typeface.DEFAULT_BOLD else Typeface.SERIF
            }
            
            val bounds = Rect()
            paint.getTextBounds(text, 0, text.length, bounds)
            
            currentY += bounds.height()
            canvas.drawText(text, padding.toFloat(), currentY, paint)
            currentY += 8 // Line spacing
        }
        
        return bitmap
    }
}
