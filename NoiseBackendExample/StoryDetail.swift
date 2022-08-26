import SwiftUI

struct StoryDetail: View {
  var story: Story

  @EnvironmentObject var model: Model

  @State var commentsLoading = true
  @State var comments = [Comment]()

  var body: some View {
    VStack {
      if commentsLoading {
        Text("Loading...")
      } else {
        List(comments, id: \.id) { comment in
          Text(comment.text)
        }
      }
    }
    .navigationTitle(story.title)
    .onAppear {
      model.getComments(forStory: story.id) { comments in
        self.comments = comments
        self.commentsLoading = false
      }
    }
  }
}
