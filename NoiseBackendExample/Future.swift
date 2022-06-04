import Dispatch
import Foundation

enum FutureWaitResult<R> {
  case success(R)
  case timedOut
}

class Future<T> {
  private let mu = DispatchSemaphore(value: 1)
  private var waiters = [DispatchSemaphore]()
  private var data: T? = nil

  func resolve(with data: T) {
    mu.wait()
    defer { mu.signal() }
    self.data = data
    for w in waiters {
      w.signal()
    }
    waiters.removeAll()
  }

  func map<R>(_ proc: @escaping (T) -> R) -> Future<R> {
    let fut = Future<R>()
    DispatchQueue.global(qos: .default).async {
      fut.resolve(with: proc(self.wait()))
    }
    return fut
  }

  func wait() -> T {
    mu.wait()
    if let d = data {
      mu.signal()
      return d
    }
    let waiter = DispatchSemaphore(value: 0)
    waiters.append(waiter)
    mu.signal()
    waiter.wait()
    return data!
  }

  func wait(timeout t: DispatchTime) -> FutureWaitResult<T> {
    mu.wait()
    if let d = data {
      mu.signal()
      return .success(d)
    }
    let waiter = DispatchSemaphore(value: 0)
    waiters.append(waiter)
    mu.signal()
    switch waiter.wait(timeout: t) {
    case .success:
      return .success(data!)
    case .timedOut:
      mu.wait()
      waiters.removeAll { $0 == waiter }
      mu.signal()
      return .timedOut
    }
  }
}
