import SwiftUI

struct CommentDetail: View {
  let story: Story
  let comment: Comment

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
    .task {
      self.comments = try! await model.getComments(forItem: comment.id)
      self.commentsLoading = false
    }
  }
}
