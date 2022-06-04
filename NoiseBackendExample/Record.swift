// This file was automatically generated.
import Foundation

public enum Record: Readable, Writeable {
  indirect case request(Request)
  indirect case response(Response)
  case ping(Ping)
  case pong(Pong)
  public static func read(from inp: InputPort, using buf: inout Data) -> Record? {
    guard let id = UVarint.read(from: inp, using: &buf) else {
      return nil
    }
    switch id {
    case 0x0:
      return .request(Request.read(from: inp, using: &buf)!)
    case 0x1:
      return .response(Response.read(from: inp, using: &buf)!)
    case 0x2:
      return .ping(Ping.read(from: inp, using: &buf)!)
    case 0x3:
      return .pong(Pong.read(from: inp, using: &buf)!)
    default:
      return nil
    }
  }
  public func write(to out: OutputPort) {
    switch self {
    case .request(let r): r.write(to: out)
    case .response(let r): r.write(to: out)
    case .ping(let r): r.write(to: out)
    case .pong(let r): r.write(to: out)
    }
  }
}
public struct Request: Readable, Writeable {
  public let id: Varint
  public let data: Record
  public init(
    id: Varint,
    data: Record
  ) {
    self.id = id
    self.data = data
  }
  public static func read(from inp: InputPort, using buf: inout Data) -> Request? {
    return Request(
      id: Varint.read(from: inp, using: &buf)!, 
      data: Record.read(from: inp, using: &buf)!
    )
  }
  public func write(to out: OutputPort) {
    UVarint(0x0).write(to: out)
    id.write(to: out)
    data.write(to: out)
  }
}
public struct Response: Readable, Writeable {
  public let id: Varint
  public let data: Record
  public init(
    id: Varint,
    data: Record
  ) {
    self.id = id
    self.data = data
  }
  public static func read(from inp: InputPort, using buf: inout Data) -> Response? {
    return Response(
      id: Varint.read(from: inp, using: &buf)!, 
      data: Record.read(from: inp, using: &buf)!
    )
  }
  public func write(to out: OutputPort) {
    UVarint(0x1).write(to: out)
    id.write(to: out)
    data.write(to: out)
  }
}
public struct Ping: Readable, Writeable {
  public init(
  ) {
  }
  public static func read(from inp: InputPort, using buf: inout Data) -> Ping? {
    return Ping(
    )
  }
  public func write(to out: OutputPort) {
    UVarint(0x2).write(to: out)
  }
}
public struct Pong: Readable, Writeable {
  public init(
  ) {
  }
  public static func read(from inp: InputPort, using buf: inout Data) -> Pong? {
    return Pong(
    )
  }
  public func write(to out: OutputPort) {
    UVarint(0x3).write(to: out)
  }
}
