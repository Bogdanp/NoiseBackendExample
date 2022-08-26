import SwiftUI

struct StoryRow: View {
  var story: Story

  var body: some View {
    NavigationLink(destination: StoryDetail(story: story)) {
      HStack {
        Text(story.title)
        Spacer()
        Text("\(story.comments.count)")
          .foregroundColor(.secondary)
      }
    }
  }
}
