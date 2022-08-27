import SwiftUI

struct CommentRow: View {
  let story: Story
  let comment: Comment

  var body: some View {
    VStack(alignment: .leading) {
      Text(comment.text)
      HStack {
        Text("By \(comment.author) on \(comment.timestamp).")
          .foregroundColor(.secondary)
      }
      .padding([.top], 1)
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 10)
        .fill(Color.init(red: 0.95, green: 0.95, blue: 0.95)))
  }
}
