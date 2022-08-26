import SwiftUI

#if arch(x86_64)
let ARCH = "x86_64"
#elseif arch(arm64)
let ARCH = "arm64"
#endif

@main
struct NoiseBackendExampleApp: App {
  let b = Backend(
    withZo: Bundle.main.url(forResource: "resources/core-\(ARCH)", withExtension: ".zo")!,
    andMod: "main",
    andProc: "main"
  )

  var body: some Scene {
    WindowGroup {
      ContentView(
        pingAction: {
          print(b.ping().wait())
        }, statsAction: {
          print(b.impl.stats())
        }
      )
      .frame(width: 800.0, height: 600.0)
    }
  }
}
