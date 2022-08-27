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

class Model: ObservableObject {
  let b = Backend(
    withZo: Bundle.main.url(forResource: "resources/core-\(ARCH)", withExtension: ".zo")!,
    andMod: "main",
    andProc: "main"
  )

  @Published var stories = [Story]()

  init() {
    b.getTopStories().onComplete { stories in
      self.stories = stories
    }
  }

  func getComments(forItem id: UVarint, onComplete proc: @escaping ([Comment]) -> Void) {
    b.getComments(forItem: id).onComplete(proc)
  }
}
