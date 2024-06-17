import Dispatch
import Foundation
import NoiseBackend
import NoiseSerde
import SwiftUI

#if arch(x86_64)
let ARCH = "x86_64"
#elseif arch(arm64)
let ARCH = "arm64"
#endif

@MainActor
class Model: ObservableObject {
  let b = Backend(
    withZo: Bundle.main.url(forResource: "res/core-\(ARCH)", withExtension: ".zo")!,
    andMod: "main",
    andProc: "main"
  )

  @Published var stories = [Story]()

  init() {
    Task {
      self.stories = try! await b.getTopStories()
    }
  }

  func getComments(forItem id: UVarint) async throws -> [Comment] {
    return try await b.getComments(forItem: id)
  }
}
