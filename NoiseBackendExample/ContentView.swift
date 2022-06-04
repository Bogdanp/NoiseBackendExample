import SwiftUI

struct ContentView: View {
  let pingAction: () -> Void
  let statsAction: () -> Void

  var body: some View {
    HStack {
      Button("Ping") {
        pingAction()
      }
      Button("Stats") {
        statsAction()
      }
    }
  }
}
