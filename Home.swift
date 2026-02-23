//
//  SwiftUIView.swift
//  TinyTalk
//
//  Created by Zikar Nurizky on 20/02/26.
//

import Foundation
import SwiftUI

struct Home: View {
    @StateObject private var vm = HomeViewModel()
    @State private var scale = 1.0

    private func startAnimation(isListening: Bool) {
        withAnimation(.none) { scale = 1.0 }
        if isListening {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: true)) { scale = 0.8 }
        } else {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: true)) { scale = 1.1 }
        }
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
                if vm.isProcessing {
                    FancySpinner()
                } else {
                    ZStack {
                        Circle()
                            .fill(vm.isListening ? Color("violet-50") : Color("violet-200"))
                            .frame(width: 250, height: 250)
                            .scaleEffect(scale)
                            .onAppear { startAnimation(isListening: vm.isListening) }
                            .onChange(of: vm.isListening) { newVal in
                                startAnimation(isListening: newVal)
                            }

                        Image("ear")
                            .resizable()
                            .frame(width: 84, height: 84)
                            .aspectRatio(contentMode: .fit)
                    }
                }
                Text(vm.isListening ? "Hold the phone close to your little one..." : "Waiting for sound...")
                    .font(.custom("OpenSans-Regular", size: 11))
                    .padding(10)
            }
            Spacer()
            Button(vm.isListening || vm.isProcessing ? "Stop" : "Hear them") {
                vm.toggleListening()
            }
            .buttonStyle(PrimaryButtonStyle(isListening: vm.isListening))
            Spacer()
        }
        .sheet(isPresented: $vm.showSheet) {
            // Safely unwrap result with a lightweight fallback to avoid crashes
            let fallback = Result(
                headline: "Analyzing",
                icon: "ear",
                reason: "Processing audio...",
                solution: "Please wait a moment."
            )
            let unwrapped = vm.result ?? fallback
            if #available(iOS 16.4, *) {
                BottomSheetView(selectedDetent: $vm.selectedDetent, result: unwrapped)
                    .presentationDetents([.fraction(0.33), .large], selection: $vm.selectedDetent)
            } else {
                BottomSheetView(selectedDetent: $vm.selectedDetent, result: unwrapped)
                    .presentationDetents([.fraction(0.33), .large], selection: $vm.selectedDetent)
            }
        }
    }
}

#Preview { Home() }
