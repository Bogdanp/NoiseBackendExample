import Foundation

extension Bool {
  static func read(from inp: InputPort) -> Bool? {
    var data = Data(count: 1)
    let _ = data.withUnsafeMutableBytes { inp.read($0, count: 1) }
    return data[0] == 1
  }
}

typealias Varint = Int64

extension Varint {
  static func read(from inp: InputPort) -> Varint? {
    var data = Data(count: 1)
    var s = Int64(0)
    var n = Int64(0)
    while true {
      let nread = data.withUnsafeMutableBytes { inp.read($0, count: 1) }
      if nread == 0 {
        return nil
      }
      let b = Int64(data[0])
      if b & 0x80 == 0 {
        n += b << s
        break
      } else {
        n += (b & 0x7F) << s
        s += 7
      }
    }
    if n & 1 == 0 {
      return Varint(n >> 1)
    }
    return Varint(~(n >> 1))
  }

  func write(to out: OutputPort) {
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

extension String {
  static func read(from inp: InputPort) -> String? {
    guard let len = Varint.read(from: inp) else {
      return nil
    }
    if len == 0 {
      return ""
    }
    var data = Data(count: Int(len))
    if data.withUnsafeMutableBytes({ inp.read($0, count: Int(len)) }) < len {
      return nil
    }
    guard let str = String(data: data, encoding: .utf8) else {
      return nil
    }
    return Symbol(str)
  }

  func write(to out: OutputPort) {
    let data = data(using: .utf8)!
    Varint(data.count).write(to: out)
    out.write(contentsOf: data[0..<(data.count)])
  }
}

typealias Symbol = String

class InputPort {
  let handle: FileHandle

  init(withHandle h: FileHandle) {
    handle = h
  }

  func read(_ out: UnsafeMutableRawBufferPointer, count n: Int) -> Int {
    guard let data = try! handle.read(upToCount: n) else {
      return 0
    }
    if data.count == 0 {
      return 0
    }
    out.copyBytes(from: data)
    return data.count
  }
}

class OutputPort {
  let handle: FileHandle

  init(withHandle h: FileHandle) {
    handle = h
  }

  func write(contentsOf data: Data) {
    try! handle.write(contentsOf: data)
  }
}
