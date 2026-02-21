//
//  File.swift
//  TinyTalk
//
//  Created by Zikar Nurizky on 21/02/26.
//

import Foundation
import SwiftUI

struct FancySpinner: View {
    @State private var rotation = 0.0
    
    var body: some View {
        Circle()
            .trim(from: 0.3, to: 1)
            .stroke(
                AngularGradient(
                    gradient: Gradient(colors: [Color("violet-50"), Color("violet-200")]),
                    center: .center
                ),
                style: StrokeStyle(lineWidth: 3, lineCap: .round)
            )
            .frame(width: 250, height: 250)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(
                    .linear(duration: 3)
                        .repeatForever(autoreverses: false)
                ) {
                    rotation = 360
                }
            }
    }
}
