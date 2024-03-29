import SwiftUI

struct StoryDetail: View {
  let story: Story

  @EnvironmentObject var model: Model

  @State var commentsLoading = true
  @State var comments = [Comment]()

  var body: some View {
    VStack {
      if commentsLoading {
        Text("Loading...")
      } else {
        CommentList(story: story, comments: comments)
      }
    }
    .navigationTitle(story.title)
    .onAppear {
      model.getComments(forItem: story.id) { comments in
        self.comments = comments
        self.commentsLoading = false
      }
    }
  }
}
