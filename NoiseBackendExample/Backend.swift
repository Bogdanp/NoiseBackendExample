// This file was automatically generated by noise-serde-lib.
import Foundation
import NoiseBackend
import NoiseSerde

public struct Comment: Readable, Sendable, Writable {
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

  public static func read(from inp: InputPort, using buf: inout Data) -> Comment {
    return Comment(
      id: UVarint.read(from: inp, using: &buf),
      author: String.read(from: inp, using: &buf),
      timestamp: String.read(from: inp, using: &buf),
      text: String.read(from: inp, using: &buf)
    )
  }

  public func write(to out: OutputPort) {
    id.write(to: out)
    author.write(to: out)
    timestamp.write(to: out)
    text.write(to: out)
  }
}

public struct Story: Readable, Sendable, Writable {
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

  public static func read(from inp: InputPort, using buf: inout Data) -> Story {
    return Story(
      id: UVarint.read(from: inp, using: &buf),
      title: String.read(from: inp, using: &buf),
      comments: [UVarint].read(from: inp, using: &buf)
    )
  }

  public func write(to out: OutputPort) {
    id.write(to: out)
    title.write(to: out)
    comments.write(to: out)
  }
}

public final class Backend: Sendable {
  let impl: NoiseBackend.Backend!

  init(withZo zo: URL, andMod mod: String, andProc proc: String) {
    impl = NoiseBackend.Backend(withZo: zo, andMod: mod, andProc: proc)
  }

  public func getComments(forItem id: UVarint) -> Future<String, [Comment]> {
    return impl.send(
      writeProc: { (out: OutputPort) in
        UVarint(0x0000).write(to: out)
        id.write(to: out)
      },
      readProc: { (inp: InputPort, buf: inout Data) -> [Comment] in
        return [Comment].read(from: inp, using: &buf)
      }
    )
  }

  public func getComments(forItem id: UVarint) async throws -> [Comment] {
    return try await FutureUtil.asyncify(getComments(forItem: id))
  }

  public func getTopStories() -> Future<String, [Story]> {
    return impl.send(
      writeProc: { (out: OutputPort) in
        UVarint(0x0001).write(to: out)
      },
      readProc: { (inp: InputPort, buf: inout Data) -> [Story] in
        return [Story].read(from: inp, using: &buf)
      }
    )
  }

  public func getTopStories() async throws -> [Story] {
    return try await FutureUtil.asyncify(getTopStories())
  }

  public func installCallback(internalWithId id: UVarint, andAddr addr: Varint) -> Future<String, Void> {
    return impl.send(
      writeProc: { (out: OutputPort) in
        UVarint(0x0002).write(to: out)
        id.write(to: out)
        addr.write(to: out)
      },
      readProc: { (inp: InputPort, buf: inout Data) -> Void in }
    )
  }

  public func installCallback(internalWithId id: UVarint, andAddr addr: Varint) async throws -> Void {
    return try await FutureUtil.asyncify(installCallback(internalWithId: id, andAddr: addr))
  }
}
