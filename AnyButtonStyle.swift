//
//  AnyButtonStyle.swift
//  TinyTalk
//
//  Created by Zikar Nurizky on 21/02/26.
//

import SwiftUI

struct AnyButtonStyle: ButtonStyle {
    private let makeBodyClosure: (Configuration) -> AnyView
    
    init<S: ButtonStyle>(_ style: S) {
        makeBodyClosure = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        makeBodyClosure(configuration)
    }
}
