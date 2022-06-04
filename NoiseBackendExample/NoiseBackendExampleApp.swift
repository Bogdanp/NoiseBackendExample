import SwiftUI

@main
struct NoiseBackendExampleApp: App {
  let b = Backend()

  var body: some Scene {
    WindowGroup {
      ContentView(
        pingAction: {
          print(b.ping().wait()!)
        }, statsAction: {
          print(b.stats())
        }
      )
      .frame(width: 800.0, height: 600.0)
    }
  }
}
