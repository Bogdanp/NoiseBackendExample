import NoiseBackendExample
import XCTest

class SerdeTests: XCTestCase {
  func testInputPortBuffering() {
    let bufsizes = [1, 2, 4, 8, 1024]
    for bufsize in bufsizes {
      let p = Pipe()
      let inp = InputPort(withHandle: p.fileHandleForReading, andBufSize: bufsize)
      let out = OutputPort(withHandle: p.fileHandleForWriting)
      out.write(contentsOf: "hello".data(using: .utf8)!)
      out.flush()
      var buf = Data(count: 8192)
      let nread = inp.read(&buf, count: 5)
      XCTAssertEqual(5, nread)
      XCTAssertEqual("hello", String(data: buf[0..<5], encoding: .utf8))
    }
  }

  func testVarintRoundtrip() {
    let p = Pipe()
    let inp = InputPort(withHandle: p.fileHandleForReading)
    let out = OutputPort(withHandle: p.fileHandleForWriting)
    let tests: [Varint] = [
      0x0, 0x1, -0x1, 0x7F, -0x7F, 0x80, -0x80,
      0xFF, -0xFF, 0xFFF, -0xFFF, 0xFFFFF, -0xFFFFF,
    ]
    var buf = Data(count: 8192)
    for n in tests {
      n.write(to: out)
      out.flush()
      XCTAssertEqual(n, Varint.read(from: inp, using: &buf))
    }
  }

  func testUVarintRoundtrip() {
    let p = Pipe()
    let inp = InputPort(withHandle: p.fileHandleForReading)
    let out = OutputPort(withHandle: p.fileHandleForWriting)
    let tests: [UVarint] = [0x0, 0x1, 0x7F, 0x80, 0xFF, 0xFFF, 0xFFFFF]
    var buf = Data(count: 8192)
    for n in tests {
      n.write(to: out)
      out.flush()
      XCTAssertEqual(n, UVarint.read(from: inp, using: &buf))
    }
  }

  func testArrayRoundtrip() {
    let p = Pipe()
    let inp = InputPort(withHandle: p.fileHandleForReading)
    let out = OutputPort(withHandle: p.fileHandleForWriting)
    let data: [Record] = [
      .request(Request(id: 1, data: .ping(Ping()))),
      .response(Response(id: 2, data: .pong(Pong())))
    ]
    var buf = Data(count: 8192)
    data.write(to: out)
    out.flush()
    let res = [Record].read(from: inp, using: &buf)!
    XCTAssertEqual(data, res)
  }

  func testRecordRoundtripPerformance() {
    let p = Pipe()
    let req = Request(id: 1, data: .ping(Ping()))
    let inp = InputPort(withHandle: p.fileHandleForReading)
    let out = OutputPort(withHandle: p.fileHandleForWriting)
    var buf = Data(count: 8192)
    let opts = XCTMeasureOptions()
    opts.iterationCount = 1000
    measure(options: opts) {
      req.write(to: out)
      out.flush()
      let _ = Record.read(from: inp, using: &buf)
    }
  }

  func testStringSmallBuffer() {
    let p = Pipe()
    let s = "hello, world!"
    let inp = InputPort(withHandle: p.fileHandleForReading)
    let out = OutputPort(withHandle: p.fileHandleForWriting)
    var buf = Data(count: 5)
    s.write(to: out)
    out.flush()
    XCTAssertEqual(s, String.read(from: inp, using: &buf))
    XCTAssertEqual(s.count, buf.count)
  }

  func testStringRoundtripPerformance() {
    let p = Pipe()
    let s = "hello, world!"
    let inp = InputPort(withHandle: p.fileHandleForReading)
    let out = OutputPort(withHandle: p.fileHandleForWriting)
    var buf = Data(count: 8192)
    let opts = XCTMeasureOptions()
    opts.iterationCount = 1000
    measure(options: opts) {
      s.write(to: out)
      out.flush()
      let _ = String.read(from: inp, using: &buf)
    }
  }
}
