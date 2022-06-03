#lang racket/base

(require ffi/unsafe/port
         racket/contract
         racket/match
         "serde.rkt")

(provide
 (rename-out [serve/fds serve]))

(define-record Ping)
(define-record Pong)

(define-record Request
  [id Varint integer?]
  [data Record any/c])

(define-record Response
  [id Varint integer?]
  [data Record any/c])

(define (serve/fds in-fd out-fd)
  (module-cache-clear!)
  (collect-garbage)
  (serve
   (unsafe-file-descriptor->port in-fd 'in '(read))
   (unsafe-file-descriptor->port out-fd 'out '(write))))

(define (serve in out)
  (let loop ()
    (define msg
      (read-record in))
    (match msg
      [(Request id (Ping))
       (write-record (Response id (Pong)) out)
       (flush-output out)
       (loop)]

      [_
       (eprintf "unexpected message: ~e~n" msg)
       (loop)])))

(module+ main
  (write-Swift-code))
