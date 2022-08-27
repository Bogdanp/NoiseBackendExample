// This file was automatically generated by noise-serde-lib.
import Foundation
import NoiseBackend
import NoiseSerde

public enum Record: Readable, Writable {
  case comment(Comment)
  case story(Story)

  public static func read(from inp: InputPort, using buf: inout Data) -> Record? {
    guard let id = UVarint.read(from: inp, using: &buf) else {
      return nil
    }
    switch id {
    case 0x0:
      return .comment(Comment.read(from: inp, using: &buf)!)
    case 0x1:
      return .story(Story.read(from: inp, using: &buf)!)
    default:
      return nil
    }
  }

  public func write(to out: OutputPort) {
    switch self {
    case .comment(let r): r.write(to: out)
    case .story(let r): r.write(to: out)
    }
  }
}

public struct Comment: Readable, Writable {
  public let id: UVarint
  public let author: String
  public let timestamp: String
  public let text: String

  public init(
    id: UVarint,
    author: String,
    timestamp: String,
    text: String
  ) {
    self.id = id
    self.author = author
    self.timestamp = timestamp
    self.text = text
  }

  public static func read(from inp: InputPort, using buf: inout Data) -> Comment? {
    return Comment(
      id: UVarint.read(from: inp, using: &buf)!,
      author: String.read(from: inp, using: &buf)!,
      timestamp: String.read(from: inp, using: &buf)!,
      text: String.read(from: inp, using: &buf)!
    )
  }

  public func write(to out: OutputPort) {
    UVarint(0x0).write(to: out)
    id.write(to: out)
    author.write(to: out)
    timestamp.write(to: out)
    text.write(to: out)
  }
}

public struct Story: Readable, Writable {
  public let id: UVarint
  public let title: String
  public let comments: [UVarint]

  public init(
    id: UVarint,
    title: String,
    comments: [UVarint]
  ) {
    self.id = id
    self.title = title
    self.comments = comments
  }

  public static func read(from inp: InputPort, using buf: inout Data) -> Story? {
    return Story(
      id: UVarint.read(from: inp, using: &buf)!,
      title: String.read(from: inp, using: &buf)!,
      comments: [UVarint].read(from: inp, using: &buf)!
    )
  }

  public func write(to out: OutputPort) {
    UVarint(0x1).write(to: out)
    id.write(to: out)
    title.write(to: out)
    comments.write(to: out)
  }
}

public class Backend {
  let impl: NoiseBackend.Backend!

  init(withZo zo: URL, andMod mod: String, andProc proc: String) {
    impl = NoiseBackend.Backend(withZo: zo, andMod: mod, andProc: proc)
  }

  public func getComments(forItem id: UVarint) -> Future<[Comment]> {
    return impl.send(
      writeProc: { (out: OutputPort) in
        UVarint(0x0).write(to: out)
        id.write(to: out)
      },
      readProc: { (inp: InputPort, buf: inout Data) -> [Comment] in
        return [Comment].read(from: inp, using: &buf)!
      }
    )
  }

  public func getTopStories() -> Future<[Story]> {
    return impl.send(
      writeProc: { (out: OutputPort) in
        UVarint(0x1).write(to: out)
      },
      readProc: { (inp: InputPort, buf: inout Data) -> [Story] in
        return [Story].read(from: inp, using: &buf)!
      }
    )
  }
}
