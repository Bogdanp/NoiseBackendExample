import Foundation

public protocol Readable where Self: Equatable {
  static func read(from inp: InputPort, using buf: inout Data) -> Self?
}

public protocol Writeable where Self: Equatable {
  func write(to out: OutputPort)
}

extension Bool: Readable, Writeable {
  public static func read(from inp: InputPort, using buf: inout Data) -> Bool? {
    return inp.readByte() == 1
  }

  public func write(to out: OutputPort) {
    out.write(contentsOf: Data([self ? 1 : 0]))
  }
}

extension Data: Readable, Writeable {
  public static func read(from inp: InputPort, using buf: inout Data) -> Data? {
    guard let vlen = Varint.read(from: inp, using: &buf) else {
      return nil
    }
    assert(vlen >= 0)
    if vlen == 0 {
      return Data(count: 0)
    }
    let len = Int(vlen)
    buf.reserveCapacity(len)
    if inp.read(&buf, count: len) < len {
      return nil
    }
    return buf[0..<len]
  }

  public func write(to out: OutputPort) {
    Varint(count).write(to: out)
    out.write(contentsOf: self)
  }
}

public typealias Varint = Int64

extension Varint: Readable, Writeable {
  public static func read(from inp: InputPort, using buf: inout Data) -> Varint? {
    var s = Varint(0)
    var n = Varint(0)
    while true {
      guard let b = inp.readByte() else {
        return nil
      }
      let x = Int64(b)
      if x & 0x80 == 0 {
        n += x << s
        break
      }
      n += (x & 0x7F) << s
      s += 7
    }
    if n & 1 == 0 {
      return n >> 1
    }
    return ~(n >> 1)
  }

  public func write(to out: OutputPort) {
    var data = Data(count: 0)
    var n = (self << 1) ^ (self < 0 ? -1 : 0)
    while true {
      let (q, r) = n.quotientAndRemainder(dividingBy: 0x80)
      if q == 0 {
        data.append(UInt8(truncatingIfNeeded: r))
        break
      } else {
        data.append(UInt8(truncatingIfNeeded: r|0x80))
        n = q
      }
    }
    out.write(contentsOf: data)
  }
}

extension String: Readable, Writeable {
  public static func read(from inp: InputPort, using buf: inout Data) -> String? {
    guard let vlen = Varint.read(from: inp, using: &buf) else {
      return nil
    }
    assert(vlen >= 0)
    if vlen == 0 {
      return ""
    }
    let len = Int(vlen)
    buf.reserveCapacity(len)
    if inp.read(&buf, count: len) < len {
      return nil
    }
    guard let str = String(data: buf[0..<len], encoding: .utf8) else {
      return nil
    }
    return str
  }

  public func write(to out: OutputPort) {
    let data = data(using: .utf8)!
    Varint(data.count).write(to: out)
    out.write(contentsOf: data)
  }
}

typealias Symbol = String

extension Array where Element: Readable, Element: Writeable {
  public static func read(from inp: InputPort, using buf: inout Data) -> [Element]? {
    guard let len = Varint.read(from: inp, using: &buf) else {
      return nil
    }
    assert(len >= 0)
    if len == 0 {
      return []
    }
    var res = [Element]()
    for _ in 0..<len {
      guard let r = Element.read(from: inp, using: &buf) else {
        return nil
      }
      res.append(r)
    }
    return res
  }

  public func write(to out: OutputPort) {
    Varint(count).write(to: out)
    for r in self {
      r.write(to: out)
    }
  }
}

public class InputPort {
  let fd: Int32
  let bufsize: Int
  var buf: Data!
  var cnt = 0
  var idx = 0

  public init(withHandle h: FileHandle, andBufSize bufsize: Int = 8192) {
    self.fd = h.fileDescriptor
    self.buf = Data(count: bufsize)
    self.bufsize = bufsize
  }

  public func read(_ data: inout Data, count n: Int) -> Int {
    var pos = 0
    var want = n
    while want > 0 {
      let nread = data[pos..<n].withUnsafeMutableBytes { read($0, count: want) }
      if nread == 0 {
        return pos
      }
      want -= nread
      pos += nread
    }
    return pos
  }

  public func read(_ out: UnsafeMutableRawBufferPointer, count want: Int) -> Int {
    more()
    if cnt == 0 {
      return 0
    }
    let have = cnt - idx
    if have >= want {
      out.copyBytes(from: buf[idx..<idx+want])
      idx += want
      return want
    }
    out.copyBytes(from: buf[idx..<cnt])
    idx += have
    return have
  }

  public func readByte() -> UInt8? {
    more()
    if cnt == 0 {
      return nil
    }
    let res = buf[idx]
    idx += 1
    return res
  }

  private func more() {
    if idx < cnt {
      return
    }
    cnt = buf.withUnsafeMutableBytes{ Darwin.read(fd, $0.baseAddress!, bufsize) }
    idx = 0
  }
}

public class OutputPort {
  let handle: FileHandle

  public init(withHandle h: FileHandle) {
    handle = h
  }

  public func write(contentsOf data: Data) {
    try! handle.write(contentsOf: data)
  }
}
