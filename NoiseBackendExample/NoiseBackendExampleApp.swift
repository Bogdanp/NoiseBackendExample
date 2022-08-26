import SwiftUI

@main
struct NoiseBackendExampleApp: App {
  @StateObject var model = Model()

  var body: some Scene {
    WindowGroup {
      ContentView(stories: model.stories)
      .frame(width: 800.0, height: 600.0)
      .environmentObject(model)
    }
  }
}
