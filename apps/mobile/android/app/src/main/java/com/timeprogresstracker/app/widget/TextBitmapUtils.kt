package com.timeprogresstracker.app.widget

import android.content.Context
import android.graphics.*
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable

object TextBitmapUtils {
    
    /**
     * Checks if a character is alphanumeric (A-Z, a-z, 0-9) or whitespace
     */
    private fun isAlphanumeric(char: Char): Boolean {
        return (char in 'A'..'Z') || (char in 'a'..'z') || (char in '0'..'9') || char.isWhitespace()
    }
    
    /**
     * Splits text into parts: alphanumeric vs symbols
     */
    private fun splitTextParts(text: String): List<Pair<String, Boolean>> {
        val parts = mutableListOf<Pair<String, Boolean>>()
        var currentPart = StringBuilder()
        var currentIsAlphanumeric = true
        
        for (char in text) {
            val isAlphanumeric = isAlphanumeric(char)
            if (isAlphanumeric == currentIsAlphanumeric) {
                currentPart.append(char)
            } else {
                if (currentPart.isNotEmpty()) {
                    parts.add(Pair(currentPart.toString(), currentIsAlphanumeric))
                }
                currentPart = StringBuilder(char.toString())
                currentIsAlphanumeric = isAlphanumeric
            }
        }
        if (currentPart.isNotEmpty()) {
            parts.add(Pair(currentPart.toString(), currentIsAlphanumeric))
        }
        
        return parts
    }
    
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
            
            // Use Sabdevi font (accommodates all letters + symbols)
            try {
                val fontName = if (isBold) "fonts/Sabdevi-Bold.ttf" else "fonts/Sabdevi-Regular.ttf"
                this.typeface = Typeface.createFromAsset(context.assets, fontName)
            } catch (e: Exception) {
                // Fallback to system fonts
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
     * Creates a simple label-value bitmap (label left regular, value right bold)
     */
    fun createLabelValueBitmap(
        context: Context,
        label: String, // Left side, regular font
        value: String, // Right side, bold font
        textSize: Float,
        textColor: Int = Color.BLACK,
        backgroundColor: Int = Color.TRANSPARENT,
        maxWidth: Int = 300,
        lineHeightMultiplier: Float = 1.2f
    ): Bitmap {
        val regularPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.textSize = textSize
            this.color = textColor
            this.textAlign = Paint.Align.LEFT
            try {
                this.typeface = Typeface.createFromAsset(context.assets, "fonts/Sabdevi-Regular.ttf")
            } catch (e: Exception) {
                this.typeface = Typeface.SERIF
            }
        }
        
        val boldPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.textSize = textSize
            this.color = textColor
            this.textAlign = Paint.Align.LEFT
            try {
                this.typeface = Typeface.createFromAsset(context.assets, "fonts/Sabdevi-Bold.ttf")
            } catch (e: Exception) {
                this.typeface = Typeface.DEFAULT_BOLD
            }
        }
        
        // Measure text
        val labelBounds = Rect()
        regularPaint.getTextBounds(label, 0, label.length, labelBounds)
        val valueBounds = Rect()
        boldPaint.getTextBounds(value, 0, value.length, valueBounds)
        
        val padding = 12
        val lineHeight = (maxOf(labelBounds.height(), valueBounds.height()) * lineHeightMultiplier).toInt()
        val bitmapHeight = lineHeight + padding * 2
        val bitmapWidth = maxWidth
        
        val bitmap = Bitmap.createBitmap(bitmapWidth, bitmapHeight, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        
        if (backgroundColor != Color.TRANSPARENT) {
            canvas.drawColor(backgroundColor)
        }
        
        // Draw label on left
        val labelY = (padding + labelBounds.height()).toFloat()
        canvas.drawText(label, padding.toFloat(), labelY, regularPaint)
        
        // Draw value on right
        val valueX = (bitmapWidth - valueBounds.width() - padding).toFloat()
        val valueY = (padding + valueBounds.height()).toFloat()
        canvas.drawText(value, valueX, valueY, boldPaint)
        
        return bitmap
    }
    
    /**
     * Creates a multi-line bitmap with label-value pairs stacked vertically
     */
    fun createMultiLabelValueBitmap(
        context: Context,
        items: List<Pair<String, String>>, // (label, value)
        textSize: Float,
        textColor: Int = Color.BLACK,
        backgroundColor: Int = Color.TRANSPARENT,
        maxWidth: Int = 300,
        lineHeightMultiplier: Float = 1.2f
    ): Bitmap {
        val regularPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.textSize = textSize
            this.color = textColor
            this.textAlign = Paint.Align.LEFT
            try {
                this.typeface = Typeface.createFromAsset(context.assets, "fonts/Sabdevi-Regular.ttf")
            } catch (e: Exception) {
                this.typeface = Typeface.SERIF
            }
        }
        
        val boldPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.textSize = textSize
            this.color = textColor
            this.textAlign = Paint.Align.LEFT
            try {
                this.typeface = Typeface.createFromAsset(context.assets, "fonts/Sabdevi-Bold.ttf")
            } catch (e: Exception) {
                this.typeface = Typeface.DEFAULT_BOLD
            }
        }
        
        // Calculate dimensions
        val padding = 12
        var totalHeight = padding
        var maxLineWidth = 0
        
        items.forEach { (label, value) ->
            val labelBounds = Rect()
            regularPaint.getTextBounds(label, 0, label.length, labelBounds)
            val valueBounds = Rect()
            boldPaint.getTextBounds(value, 0, value.length, valueBounds)
            
            val lineHeight = (maxOf(labelBounds.height(), valueBounds.height()) * lineHeightMultiplier).toInt()
            totalHeight += lineHeight
            maxLineWidth = maxOf(maxLineWidth, labelBounds.width() + valueBounds.width() + padding * 3)
        }
        
        totalHeight += padding
        
        val bitmapWidth = maxWidth
        val bitmapHeight = totalHeight
        
        val bitmap = Bitmap.createBitmap(bitmapWidth, bitmapHeight, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        
        if (backgroundColor != Color.TRANSPARENT) {
            canvas.drawColor(backgroundColor)
        }
        
        // Draw each label-value pair
        var currentY = padding.toFloat()
        items.forEach { (label, value) ->
            val labelBounds = Rect()
            regularPaint.getTextBounds(label, 0, label.length, labelBounds)
            val valueBounds = Rect()
            boldPaint.getTextBounds(value, 0, value.length, valueBounds)
            
            val lineHeight = maxOf(labelBounds.height(), valueBounds.height())
            
            // Draw label on left
            val labelY = currentY + labelBounds.height()
            canvas.drawText(label, padding.toFloat(), labelY, regularPaint)
            
            // Draw value on right
            val valueX = (bitmapWidth - valueBounds.width() - padding).toFloat()
            val valueY = currentY + valueBounds.height()
            canvas.drawText(value, valueX, valueY, boldPaint)
            
            currentY += (lineHeight * lineHeightMultiplier)
        }
        
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
        // Group inline parts (bold followed by regular) into single lines
        var totalHeight = 0
        var maxLineWidth = 0
        val lineHeights = mutableListOf<Int>()
        var currentLineWidth = 0
        var currentLineHeight = 0
        
        lines.forEachIndexed { index, (text, isBold) ->
            // Use Sabdevi font (accommodates all letters + symbols)
            try {
                val fontName = if (isBold) "fonts/Sabdevi-Bold.ttf" else "fonts/Sabdevi-Regular.ttf"
                paint.typeface = Typeface.createFromAsset(context.assets, fontName)
            } catch (e: Exception) {
                // Fallback to system fonts
                    paint.typeface = if (isBold) Typeface.DEFAULT_BOLD else Typeface.SERIF
            }
            
            val bounds = Rect()
            paint.getTextBounds(text, 0, text.length, bounds)
            
            // Check if this is a continuation of previous line (regular after bold)
            val isContinuation = index > 0 && lines[index - 1].second && !isBold && text.startsWith(" ")
            
            if (isContinuation) {
                // Add to current line width
                currentLineWidth += bounds.width()
                currentLineHeight = maxOf(currentLineHeight, bounds.height())
            } else {
                // Finish previous line if exists
                if (index > 0) {
                    lineHeights.add(currentLineHeight + 8) // Add line spacing
                    totalHeight += currentLineHeight + 8
                    maxLineWidth = maxOf(maxLineWidth, currentLineWidth)
                }
                // Start new line
                currentLineWidth = bounds.width()
                currentLineHeight = bounds.height()
            }
        }
        
        // Add last line
        if (lines.isNotEmpty()) {
            lineHeights.add(currentLineHeight + 8)
            totalHeight += currentLineHeight + 8
            maxLineWidth = maxOf(maxLineWidth, currentLineWidth)
        }
        
        // Create bitmap - simple text display
        val padding = 12
        var bitmapWidth = maxWidth // Use full widget width
        var bitmapHeight = totalHeight + padding * 2
        
        // Safety check: ensure valid dimensions
        if (bitmapWidth <= 0) {
            bitmapWidth = 300 // Default width
        }
        if (bitmapHeight <= 0) {
            bitmapHeight = 100 // Default height
        }

        val bitmap = Bitmap.createBitmap(bitmapWidth, bitmapHeight, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        // Fill background
        if (backgroundColor != Color.TRANSPARENT) {
            canvas.drawColor(backgroundColor)
        }

        // Draw each line using Sabdevi font (accommodates all letters + symbols)
        // Handle inline bold/regular parts on the same line
        var currentY = padding.toFloat()
        var currentX = padding.toFloat()
        var lineStartY = currentY
        
        lines.forEachIndexed { index, (text, isBold) ->
            // Use Sabdevi font for all text
            try {
                val fontName = if (isBold) "fonts/Sabdevi-Bold.ttf" else "fonts/Sabdevi-Regular.ttf"
                        paint.typeface = Typeface.createFromAsset(context.assets, fontName)
                } catch (e: Exception) {
                // Fallback to system fonts
                    paint.typeface = if (isBold) Typeface.DEFAULT_BOLD else Typeface.SERIF
                }
                
                val bounds = Rect()
            paint.getTextBounds(text, 0, text.length, bounds)
                
            // Check if this is a continuation of the previous line (regular text after bold)
            // If previous line was bold and this is regular, draw on same line
            val isContinuation = index > 0 && lines[index - 1].second && !isBold && text.startsWith(" ")
            
            if (!isContinuation && index > 0) {
                // New line - move Y down
                currentY = lineStartY + bounds.height()
                lineStartY = currentY
                currentX = padding.toFloat()
            } else if (index == 0) {
                // First line
                    currentY += bounds.height()
                lineStartY = currentY
                }
                
            // Draw text at current position
            canvas.drawText(text, currentX, currentY, paint)
            
            // Move X forward for next part on same line
                currentX += bounds.width().toFloat()
            
            // If this is bold and next might be continuation, don't add line spacing yet
            if (!isBold || index == lines.size - 1 || !lines[index + 1].second) {
            currentY += 8 // Line spacing
                currentX = padding.toFloat() // Reset X for next line
            }
        }

        return bitmap
    }
}
