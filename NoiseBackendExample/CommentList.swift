import NoiseSerde
import SwiftUI

struct CommentList: View {
  let story: Story
  
  @State var loading: Bool
  @State var comments: [Comment]
  @State var stack: [UVarint]
  
  @EnvironmentObject var model: Model
  
  init(story: Story, comments: [Comment]) {
    self.story = story
    self.loading = false
    self.comments = comments
    self.stack = [story.id]
  }
  
  var body: some View {
    if loading {
      Text("Loading...")
    } else {
      VStack(alignment: .leading) {
        if stack.count > 1 {
          Button("Back...") {
            self.loading = true
            Task {
              self.comments = try! await model.getComments(forItem: stack[1])
              self.stack = [UVarint](stack.dropFirst())
              self.loading = false
            }
          }
          .padding()
        }
        List(comments, id: \.id) { c in
          CommentRow(story: story, comment: c)
            .onTapGesture(count: 2) {
              self.loading = true
              Task {
                self.comments = try! await model.getComments(forItem: c.id)
                self.stack = [c.id] + stack
                self.loading = false
              }
            }
        }
      }
    }
  }
}
