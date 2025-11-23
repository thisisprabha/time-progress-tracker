//
//  WidgetFontHelper.swift
//  TimeProgressWidget
//
//  Font Helper for Widget Extension
//

import SwiftUI
import UIKit

class WidgetFontHelper {
    static var registeredFonts: [String: String] = [:]
    
    static func registerFonts() {
        let fontFiles = [
            ("Sabdevi-Regular", "Regular"),
            ("Sabdevi-Bold", "Bold"),
            ("Sabdevi-Light", "Light")
        ]
        
        for (fileName, style) in fontFiles {
            if let fontURL = Bundle.main.url(forResource: fileName, withExtension: "ttf"),
               let fontData = NSData(contentsOf: fontURL),
               let dataProvider = CGDataProvider(data: fontData),
               let font = CGFont(dataProvider) {
                
                var error: Unmanaged<CFError>?
                if CTFontManagerRegisterGraphicsFont(font, &error) {
                    if let postScriptName = font.postScriptName as String? {
                        registeredFonts[fileName] = postScriptName
                    } else {
                        let familyName = "Sabdevi"
                        let fullName = "\(familyName)-\(style)"
                        registeredFonts[fileName] = fullName
                    }
                }
            }
        }
    }
    
    static func getFontName(for customName: String) -> String {
        if let registeredName = registeredFonts[customName] {
            if UIFont(name: registeredName, size: 16) != nil {
                return registeredName
            }
        }
        
        if UIFont(name: customName, size: 16) != nil {
            return customName
        }
        
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
        
        for family in UIFont.familyNames {
            if family.lowercased().contains("sabdevi") {
                let fonts = UIFont.fontNames(forFamilyName: family)
                if customName.contains("Bold") {
                    if let boldFont = fonts.first(where: { $0.lowercased().contains("bold") }) {
                        return boldFont
                    }
                } else if customName.contains("Light") {
                    if let lightFont = fonts.first(where: { $0.lowercased().contains("light") }) {
                        return lightFont
                    }
                } else {
                    if let regularFont = fonts.first(where: { $0.lowercased().contains("regular") || !$0.lowercased().contains("bold") && !$0.lowercased().contains("light") }) {
                        return regularFont
                    }
                }
                
                if let firstFont = fonts.first {
                    return firstFont
                }
            }
        }
        
        return "System"
    }
}

extension Font {
    static func widgetSabdeviRegular(size: CGFloat) -> Font {
        let fontName = WidgetFontHelper.getFontName(for: "Sabdevi-Regular")
        if fontName == "System" {
            return .system(size: size, weight: .regular)
        }
        return .custom(fontName, size: size)
    }
    
    static func widgetSabdeviBold(size: CGFloat) -> Font {
        let fontName = WidgetFontHelper.getFontName(for: "Sabdevi-Bold")
        if fontName == "System" {
            return .system(size: size, weight: .bold)
        }
        return .custom(fontName, size: size)
    }
}

