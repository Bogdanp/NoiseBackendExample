// This file was automatically generated.

enum Record {
  case ping(Ping)
  case pong(Pong)
  indirect case request(Request)
  indirect case response(Response)
  static func read(from inp: InputPort) -> Record? {
    guard let sym = Symbol.read(from: inp) else {
      return nil
    }
    guard let _ = Varint.read(from: inp) else {
      return nil
    }
    switch sym {
      case "Ping":
        return .ping(Ping.read(from: inp))
      case "Pong":
        return .pong(Pong.read(from: inp))
      case "Request":
        return .request(Request.read(from: inp))
      case "Response":
        return .response(Response.read(from: inp))
      default:
        return nil
    }
  }
  func write(to out: OutputPort) {
    switch self {
      case .ping(let r): r.write(to: out)
      case .pong(let r): r.write(to: out)
      case .request(let r): r.write(to: out)
      case .response(let r): r.write(to: out)
    }
  }
}
struct Ping {
  static func read(from inp: InputPort) -> Ping {
    return Ping(
    )
  }
  func write(to out: OutputPort) {
    Symbol("Ping").write(to: out)
    Varint(0).write(to: out)
  }
}
struct Pong {
  static func read(from inp: InputPort) -> Pong {
    return Pong(
    )
  }
  func write(to out: OutputPort) {
    Symbol("Pong").write(to: out)
    Varint(0).write(to: out)
  }
}
struct Request {
  let id: Varint
  let data: Record
  static func read(from inp: InputPort) -> Request {
    return Request(
      id: Varint.read(from: inp)!, 
      data: Record.read(from: inp)!
    )
  }
  func write(to out: OutputPort) {
    Symbol("Request").write(to: out)
    Varint(0).write(to: out)
    id.write(to: out)
    data.write(to: out)
  }
}
struct Response {
  let id: Varint
  let data: Record
  static func read(from inp: InputPort) -> Response {
    return Response(
      id: Varint.read(from: inp)!, 
      data: Record.read(from: inp)!
    )
  }
  func write(to out: OutputPort) {
    Symbol("Response").write(to: out)
    Varint(0).write(to: out)
    id.write(to: out)
    data.write(to: out)
  }
}
