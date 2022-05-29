//
//  Backend.swift
//  NoiseBackendExample
//
//  Created by Bogdan Popa on 29.05.2022.
//

import Noise
import Foundation

#if arch(x86_64)
let ARCH = "x86_64"
#elseif arch(arm64)
let ARCH = "arm64"
#endif

class Backend {
  let ip = Pipe() // in  from Racket's perspective
  let op = Pipe() // out from Racket's perspective
  
  init() {
    Thread.detachNewThread {
      self.serve()
    }
  }
  
  func serve() {
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

  func ping() -> String {
    send("(ping)")
    return recv(6)
  }

  private func send(_ data: String) {
    let cstr = data.utf8CString
    cstr.withUnsafeBytes({ buf in
      try! ip.fileHandleForWriting.write(contentsOf: buf[..<(cstr.count-1)])
    })
  }

  private func recv(_ n: Int) -> String {
    String(data: try! op.fileHandleForReading.read(upToCount: n)!, encoding: .utf8)!
  }
}
