//
//  File.swift
//  TinyTalk
//
//  Created by Zikar Nurizky on 20/02/26.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    var isListening: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("Quicksand-Regular", size: 28))
            .foregroundColor(Color("black-700"))
            .padding(.vertical, 28)
            .padding(.horizontal, 30)
            .background(
                RoundedRectangle(cornerRadius: 36)
                    .fill(isListening ? Color("red-500"):Color("yellow-400"))
                    .scaleEffect(configuration.isPressed ? 0.96 : 1.0) // 🔵 press effect
            )
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
