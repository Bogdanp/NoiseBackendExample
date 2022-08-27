import SwiftUI

@main
struct NoiseBackendExampleApp: App {
  @StateObject var model = Model()

  var body: some Scene {
    WindowGroup {
      ContentView(stories: model.stories)
      .environmentObject(model)
    }
  }
}
