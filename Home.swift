//
//  SwiftUIView.swift
//  TinyTalk
//
//  Created by Zikar Nurizky on 20/02/26.
//

import Foundation
import SwiftUI

struct Home: View {
    @State private var scale = 1.0
    @State private var isListening = false
    @State private var isProcessing = false
    @State private var showSheet = false
    @State private var selectedDetent: PresentationDetent = .fraction(0.33)

    private func startAnimation() {
        // Cancel any running animation immediately
        withAnimation(.none) {
            scale = 1.0
        }

        if isListening {
            // Listening animation (pulse)
            withAnimation(
                .linear(duration: 1.2)
                    .repeatForever(autoreverses: true)
            ) {
                scale = 0.8
            }
        } else {
            // Not listening animation (subtle expand)
            withAnimation(
                .linear(duration: 1.2)
                    .repeatForever(autoreverses: true)
            ) {
                scale = 1.1
            }
        }
    }
    private func startRecording() {
        
    }
    private func startProcessing() {
        
    }
    
    
    var body: some View {
        VStack {
            Spacer()
            Text("Let's find out \nwhat they need")
                .font(.custom("Quicksand-Bold", size: 28))
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Spacer()
            VStack {
                if isProcessing {
                    FancySpinner()
                } else {
                    ZStack {
                        Circle()
                            .fill(
                                isListening
                                    ? Color("violet-50") : Color("violet-200")
                            )
                            .frame(width: 250, height: 250)
                            .scaleEffect(scale)
                            .onAppear {
                                startAnimation()
                            }
                            .onChange(of: isListening) { _ in
                                startAnimation()
                            }

                        Image("ear")
                            .resizable()
                            .frame(width: 84, height: 84)
                            .aspectRatio(contentMode: .fit)
                    }
                }
                Text(
                    isListening
                        ? "Hold the phone close to your little one..."
                        : "Waiting for sound..."
                )
                .font(.custom("OpenSans-Regular", size: 11))
                .padding(10)
            }
            Spacer()
            Button(isListening ? "Stop" : "Hear them") {
                isListening.toggle()
                Task {
                    // Simulate listening for 3 seconds
                    try? await Task.sleep(nanoseconds: 3_000_000_000)

                    // Switch to processing
                    isListening = true
                    isProcessing = true

                    // Simulate processing for 2 seconds
                    try? await Task.sleep(nanoseconds: 2_000_000_000)

                    // Back to idle
                    isProcessing = false
                    isListening = false
                    showSheet.toggle()
                }
            }
            .buttonStyle(PrimaryButtonStyle(isListening: isListening))
            Spacer()
        }
        .sheet(isPresented: $showSheet) {
            if #available(iOS 16.4, *) {
                BottomSheetView(selectedDetent: $selectedDetent)
                    .presentationDetents(
                        [.fraction(0.33), .large],
                        selection: $selectedDetent
                    )
                    .presentationBackground(Color("yellow-50"))
            } else {
                // Fallback on earlier versions
                BottomSheetView(selectedDetent: $selectedDetent)
                    .presentationDetents(
                        [.fraction(0.33), .large],
                        selection: $selectedDetent
                    )
            }
        }
    }
}

#Preview {
    Home()
}
