//
//  ContentView.swift
//  NoiseBackendExample
//
//  Created by Bogdan Popa on 29.05.2022.
//

import SwiftUI

struct ContentView: View {
  let action: () -> Void

  var body: some View {
    HStack {
      Button("Ping") {
        action()
      }
    }
  }
}
