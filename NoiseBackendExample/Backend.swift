import Dispatch
import Noise
import Foundation

#if arch(x86_64)
let ARCH = "x86_64"
#elseif arch(arm64)
let ARCH = "arm64"
#endif

fileprivate struct WrappedRequest {
  let id: Int64
  let fut: Future<Record>
  let time = DispatchTime.now()
}

struct BackendStats {
  let totalRequests: UInt64
  let totalWaitNanos: UInt64
}

class Backend {
  let ip = Pipe() // in  from Racket's perspective
  let op = Pipe() // out from Racket's perspective

  let out: OutputPort!
  let inp: InputPort!
  let mu = DispatchSemaphore(value: 1)
  var seq = Int64(0)
  fileprivate var pending = [Int64: WrappedRequest]()

  var totalRequests = UInt64(0)
  var totalWaitNanos = UInt64(0)

  init() {
    out = OutputPort(withHandle: ip.fileHandleForWriting)
    inp = InputPort(withHandle: op.fileHandleForReading)
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
    }
  }

  private func read() {
    while true {
      guard let res = Record.read(from: inp) else {
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
        continue
      default:
        continue
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