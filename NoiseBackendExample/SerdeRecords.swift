// This file was automatically generated.
import Foundation

public enum Record: Readable, Writeable {
  case ping(Ping)
  case pong(Pong)
  indirect case request(Request)
  indirect case response(Response)
  public static func read(from inp: InputPort, using buf: inout Data) -> Record? {
    guard let sym = Symbol.read(from: inp, using: &buf) else {
      return nil
    }
    switch sym {
    case "Ping":
      return .ping(Ping.read(from: inp, using: &buf)!)
    case "Pong":
      return .pong(Pong.read(from: inp, using: &buf)!)
    case "Request":
      return .request(Request.read(from: inp, using: &buf)!)
    case "Response":
      return .response(Response.read(from: inp, using: &buf)!)
    default:
      return nil
    }
  }
  public func write(to out: OutputPort) {
    switch self {
    case .ping(let r): r.write(to: out)
    case .pong(let r): r.write(to: out)
    case .request(let r): r.write(to: out)
    case .response(let r): r.write(to: out)
    }
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
    Symbol("Ping").write(to: out)
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
    Symbol("Pong").write(to: out)
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
    Symbol("Request").write(to: out)
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
    Symbol("Response").write(to: out)
    id.write(to: out)
    data.write(to: out)
  }
}
