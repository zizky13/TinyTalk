//
//  BottomSheetView.swift
//  TinyTalk
//
//  Created by Zikar Nurizky on 21/02/26.
//
import SwiftUI

let colorMap: [String: String] = [
    "hungry": "yellow-600",
    "burp": "slate-900",
    "belly pain": "red-400",
    "discomfort": "green-400",
    "tired": "violet-300",
    "cool_hot": "blue-400"
]

struct BottomSheetView: View {
    @Binding var selectedDetent: PresentationDetent
    var result: Result

    var body: some View {
        // Expanded vs compact: when compact (1/3), show only header card + image
        let isExpanded = (selectedDetent == .large)
        let isCompact = (selectedDetent == .fraction(0.33))

        return VStack(spacing: 16) {
            if !isCompact {
                HStack(spacing: 12) {
                    Text(result.headline)
                        .font(.headline)
                }
                Divider()
            }
            
            // HEADER CARD
            VStack {
                Text(result.verdict.capitalized.replacingOccurrences(of: "_", with: " "))
                    .font(.custom("Quicksand-Bold", size: 48))
            }
            .padding(.horizontal, 101)
            .padding(.vertical, 21)
            .background(
                RoundedRectangle(cornerRadius: 36)
                    .fill(verdictColor(for: result.verdict))
            )
            
            // IMAGE
            Image(result.icon)
                .resizable()
                .frame(width: 84, height: 84)
                .padding(.vertical, 48)

//            if isExpanded {
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Why?")
                        .font(.custom("Quicksand-Bold", size: 33))
                        .foregroundColor(Color("black-50"))
                    Text(result.reason)
                        .font(.custom("OpenSans-Regular", size: 13))
                        .lineLimit(isExpanded ? 2: 3)
                        .foregroundColor(Color("black-50"))
                }
                .padding(.bottom, 10)
                
                    
                VStack(alignment: .leading, spacing: 8) {
                    Text("How can we help?")
                        .font(.custom("Quicksand-Bold", size: 33))
                        .foregroundColor(Color("violet-50"))
                    // Render solution line-by-line (no bullets). Prefer newline split; fallback to sentences.
                   
                    ForEach(result.solution, id: \.self) { item in
                        Text(item)
                            .font(.custom("OpenSans-Regular", size: 13))
                            .foregroundColor(Color("violet-50"))
                            .lineLimit(isExpanded ? 2 : 3)
                            .multilineTextAlignment(.leading)
                    }
                }
                    
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 36)
                    .fill(Color("white-800"))
            )
            .padding(.horizontal, 21)
//            }

            Spacer()
        }
        .padding()
        
        
    }
}

// MARK: - Helpers
extension BottomSheetView {
    fileprivate func verdictColor(for verdict: String) -> Color {
        switch verdict.lowercased() {
        case "hungry": return Color("yellow-400")
        case "burp", "burping": return Color("green-400")
        case "belly pain", "belly_pain": return Color("red-400")
        case "discomfort": return Color("violet-200")
        case "tired", "sleepy": return Color("blue-400")
        case "cool_hot", "cold_hot", "temperature": return Color("blue-400")
        default: return Color("white-400")
        }
    }
}

// MARK: - Preview
#Preview("BottomSheetView") {
    struct Wrapper: View {
        @State var detent: PresentationDetent = .large
        var sample = Result(
            headline: "Likely Hungry",
            verdict: "hungry",
            icon: "bottle",
            reason: "Top classes: hungry 82%, burp 9%, sleepy 5%. Captured a strong energy window with clear spectral cues.",
            solution: ["Offer a small feed and burp midway.\nKeep baby upright for 10–15 minutes.\nCheck diaper and room temperature to ensure comfort."]
        )
        var body: some View {
            BottomSheetView(selectedDetent: $detent, result: sample)
                .presentationDetents([.fraction(0.33), .large], selection: $detent)
                .presentationBackground(Color("yellow-50"))
        }
    }
    return Wrapper()
}
