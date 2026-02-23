//
//  BottomSheetView.swift
//  TinyTalk
//
//  Created by Zikar Nurizky on 21/02/26.
//
import SwiftUI

struct BottomSheetView: View {
    @Binding var selectedDetent: PresentationDetent
    var result: Result

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(result.icon)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .accessibilityHidden(true)
                Text(result.headline)
                    .font(.headline)
            }

            if selectedDetent == .large {
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    Text(result.reason)
                        .font(.body)
                    Text(result.solution)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()
        }
        .padding()
    }
}
