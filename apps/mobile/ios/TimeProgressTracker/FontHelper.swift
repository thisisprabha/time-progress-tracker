//
//  FontHelper.swift
//  TimeProgressTracker
//
//  Font Loading Helper
//

import SwiftUI
import UIKit

class FontHelper {
    static var registeredFonts: [String: String] = [:] // Maps custom name to actual font name
    
    static func registerFonts() {
        let fontFiles = [
            ("Sabdevi-Regular", "Regular"),
            ("Sabdevi-Bold", "Bold"),
            ("Sabdevi-Light", "Light")
        ]
        
        for (fileName, style) in fontFiles {
            // Try multiple paths
            var fontURL: URL?
            // Try direct path first
            fontURL = Bundle.main.url(forResource: fileName, withExtension: "ttf")
            // Try Assets/Fonts path
            if fontURL == nil {
                fontURL = Bundle.main.url(forResource: "Assets/Fonts/\(fileName)", withExtension: "ttf")
            }
            // Try just the filename in bundle
            if fontURL == nil {
                fontURL = Bundle.main.url(forResource: fileName, withExtension: "ttf", subdirectory: "Assets/Fonts")
            }
            
            if let url = fontURL,
               let fontData = NSData(contentsOf: fontURL),
               let dataProvider = CGDataProvider(data: fontData),
               let font = CGFont(dataProvider) {
                
                var error: Unmanaged<CFError>?
                if CTFontManagerRegisterGraphicsFont(font, &error) {
                    // Get the actual PostScript name
                    if let postScriptName = font.postScriptName as String? {
                        print("✓ Registered font: \(fileName) -> \(postScriptName)")
                        registeredFonts[fileName] = postScriptName
                    } else {
                        // Try to get from family name
                        let familyName = "Sabdevi"
                        let fullName = "\(familyName)-\(style)"
                        registeredFonts[fileName] = fullName
                        print("✓ Registered font: \(fileName) -> \(fullName)")
                    }
                } else {
                    if let error = error?.takeRetainedValue() {
                        let errorDescription = CFErrorCopyDescription(error)
                        print("✗ Failed to register \(fileName): \(errorDescription ?? "Unknown error" as CFString)")
                    }
                }
            } else {
                print("✗ Font file not found: \(fileName).ttf")
            }
        }
        
        // Print all available fonts containing 'Sabdevi'
        print("\nAvailable fonts containing 'Sabdevi':")
        for family in UIFont.familyNames.sorted() {
            if family.lowercased().contains("sabdevi") {
                print("  Family: \(family)")
                for fontName in UIFont.fontNames(forFamilyName: family) {
                    print("    - \(fontName)")
                }
            }
        }
    }
    
    static func getFontName(for customName: String) -> String {
        // First check if we registered it
        if let registeredName = registeredFonts[customName] {
            if UIFont(name: registeredName, size: 16) != nil {
                return registeredName
            }
        }
        
        // Try the custom name directly
        if UIFont(name: customName, size: 16) != nil {
            return customName
        }
        
        // Try variations
        let variations = [
            customName.replacingOccurrences(of: "-", with: " "),
            customName.replacingOccurrences(of: "-Regular", with: ""),
            customName.replacingOccurrences(of: "-Bold", with: " Bold"),
            customName.replacingOccurrences(of: "-Light", with: " Light"),
        ]
        
        for variation in variations {
            if UIFont(name: variation, size: 16) != nil {
                return variation
            }
        }
        
        // Check all fonts for partial match
        for family in UIFont.familyNames {
            if family.lowercased().contains("sabdevi") {
                let fonts = UIFont.fontNames(forFamilyName: family)
                // Try to match style
                if customName.contains("Bold") {
                    if let boldFont = fonts.first(where: { $0.lowercased().contains("bold") }) {
                        return boldFont
                    }
                } else if customName.contains("Light") {
                    if let lightFont = fonts.first(where: { $0.lowercased().contains("light") }) {
                        return lightFont
                    }
                } else if customName.contains("Regular") {
                    if let regularFont = fonts.first(where: { $0.lowercased().contains("regular") || !$0.lowercased().contains("bold") && !$0.lowercased().contains("light") }) {
                        return regularFont
                    }
                }
                
                // Fallback to first font in family
                if let firstFont = fonts.first {
                    return firstFont
                }
            }
        }
        
        // Final fallback
        print("⚠ Font not found: \(customName), using system font")
        return "System" // Will be handled by Font extension
    }
}

extension Font {
    static func sabdeviRegular(size: CGFloat) -> Font {
        let fontName = FontHelper.getFontName(for: "Sabdevi-Regular")
        if fontName == "System" {
            return .system(size: size)
        }
        return .custom(fontName, size: size)
    }
    
    static func sabdeviBold(size: CGFloat) -> Font {
        let fontName = FontHelper.getFontName(for: "Sabdevi-Bold")
        if fontName == "System" {
            return .system(size: size, weight: .bold)
        }
        return .custom(fontName, size: size)
    }
}

