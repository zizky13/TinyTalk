import SwiftUI

@main
struct MyApp: App {
    init() {
        registerFontIfNeeded(name: "Quicksand-Bold", extension: "ttf", postScriptName: "Quicksand-Bold")
        registerFontIfNeeded(name: "Quicksand-Regular", extension: "ttf", postScriptName: "Quicksand-Regular")
        registerFontIfNeeded(name: "OpenSans-Bold", extension: "ttf", postScriptName: "OpenSans-Bold")
        registerFontIfNeeded(name: "OpenSans-Regular", extension: "ttf", postScriptName: "OpenSans-Regular")
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(Color("white-400"))
        }
    }
}
