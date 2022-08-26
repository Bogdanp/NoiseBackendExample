import SwiftUI

struct StoryList: View {
  var stories: [Story]

  var body: some View {
    NavigationView {
      List(stories, id: \.id) { s in
        StoryRow(story: s)
      }

      Text("Select a Story")
    }
  }
}
