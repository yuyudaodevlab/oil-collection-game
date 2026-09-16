import SwiftUI

@main
struct OilGardenApp: App {
    var body: some Scene {
        #if os(macOS)
        Window("油あつめ", id: "oil-garden") {
            ContentView().frame(minWidth: 390, minHeight: 620)
        }
        .defaultSize(width: 1100, height: 780)
        .windowStyle(.hiddenTitleBar)
        #else
        WindowGroup { ContentView() }
        #endif
    }
}
