import Dispatch
import Foundation
import Noise

#if arch(x86_64)
let ARCH = "x86_64"
#elseif arch(arm64)
let ARCH = "arm64"
#endif

struct BackendStats {
  let totalRequests: UInt64
  let totalWaitNanos: UInt64
}

class Backend {
  private let ip = Pipe() // in  from Racket's perspective
  private let op = Pipe() // out from Racket's perspective

  private let mu = DispatchSemaphore(value: 1) // mu guards everything below here
  private let out: OutputPort!
  private var seq = UInt64(0)
  fileprivate var pending = [UInt64: WrappedRequest]()
  private var totalRequests = UInt64(0)
  private var totalWaitNanos = UInt64(0)

  init() {
    out = OutputPort(withHandle: ip.fileHandleForWriting)
    Thread.detachNewThread {
      self.serve()
    }
    Thread.detachNewThread {
      self.read()
    }
  }

  private func serve() {
    let r = Racket()
    r.bracket {
      r.load(zo: Bundle.main.url(forResource: "resources/core-\(ARCH)", withExtension: "zo")!)
      let mod = Val.cons(Val.symbol("quote"), Val.cons(Val.symbol("main"), Val.null))
      let serve = r.require(Val.symbol("serve"), from: mod).car()!
      let ifd = Val.fixnum(Int(ip.fileHandleForReading.fileDescriptor))
      let ofd = Val.fixnum(Int(op.fileHandleForWriting.fileDescriptor))
      let _ = serve.apply(Val.cons(ifd, Val.cons(ofd, Val.null)))!
      preconditionFailure("Racket server exited")
    }
  }

  private func read() {
    let inp = InputPort(withHandle: op.fileHandleForReading)
    var buf = Data(count: 8*1024) // will grow as needed
    while true {
      guard let res = Record.read(from: inp, using: &buf) else {
        continue
      }
      switch res {
      case .response(let r):
        mu.wait()
        guard let req = pending[r.id] else {
          mu.signal()
          continue
        }
        pending.removeValue(forKey: r.id)
        mu.signal()
        req.fut.resolve(with: r.data)
        totalRequests += 1
        totalWaitNanos += DispatchTime.now().uptimeNanoseconds - req.time.uptimeNanoseconds
      default:
        preconditionFailure("received unexpected response data: \(res)")
      }
    }
  }

  func send(data: Record) -> Future<Record> {
    mu.wait()
    defer { mu.signal() }
    let id = seq
    let req = Request(id: id, data: data)
    seq += 1
    req.write(to: out)
    out.flush()
    let fut = Future<Record>()
    pending[id] = WrappedRequest(id: id, fut: fut)
    return fut
  }

  func ping() -> Future<Pong?> {
    return send(data: .ping(Ping())).map {
      switch $0 {
      case .pong(let p):
        return p
      default:
        return nil
      }
    }
  }

  func stats() -> BackendStats {
    return BackendStats(
      totalRequests: totalRequests,
      totalWaitNanos: totalWaitNanos
    )
  }
}

fileprivate struct WrappedRequest {
  let id: UInt64
  let fut: Future<Record>
  let time = DispatchTime.now()
}
