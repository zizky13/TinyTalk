//
//  BottomSheetView.swift
//  TinyTalk
//
//  Created by Zikar Nurizky on 21/02/26.
//
import SwiftUI

struct BottomSheetView: View {
    @Binding var selectedDetent: PresentationDetent
    
    var body: some View {
        VStack(spacing: 16) {
            
            // 🔹 Minimal Info (always visible)
            Text("Quick Summary")
                .font(.headline)

            if selectedDetent == .large {
                Divider()
                
                // 🔹 Detailed Info (only when expanded)
                Text("Here is the full detailed explanation of what is happening. This appears only when the sheet is expanded.")
                    .font(.body)
            }
            
            Spacer()
        }
        .padding()
    }
}
