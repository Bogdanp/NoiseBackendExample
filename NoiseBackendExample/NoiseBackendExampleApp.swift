//
//  NoiseBackendExampleApp.swift
//  NoiseBackendExample
//
//  Created by Bogdan Popa on 29.05.2022.
//

import SwiftUI

@main
struct NoiseBackendExampleApp: App {
  let b = Backend()

  var body: some Scene {
    WindowGroup {
      ContentView {
        print(b.ping())
      }
      .frame(width: 800.0, height: 600.0)
    }
  }
}
