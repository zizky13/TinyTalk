//
//  File.swift
//  TinyTalk
//
//  Created by Zikar Nurizky on 20/02/26.
//

import SwiftUI
import CoreText

func registerFontIfNeeded(name: String, extension ext: String, postScriptName: String) {
    // 1. Check if it's already registered to stop the annoying prompts
    let font = UIFont(name: postScriptName, size: 1)
    if font?.fontName == postScriptName {
        return // Already registered, do nothing
    }

    // 2. Otherwise, register it
    guard let fontURL = Bundle.main.url(forResource: name, withExtension: ext) else { return }
    
    var error: Unmanaged<CFError>?
    if !CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error) {
        print("Registration skipped or failed: \(String(describing: error))")
    }
}
