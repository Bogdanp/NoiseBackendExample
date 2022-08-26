import SwiftUI

struct ContentView: View {
  var stories: [Story]

  var body: some View {
    StoryList(stories: stories)
  }
}
