#lang racket/base

(require ffi/unsafe/port
         racket/contract
         racket/match
         "serde.rkt")

(provide
 (rename-out [serve/fds serve]))

(define-record Request #x00
  [id UVarint integer?]
  [data Record any/c])

(define-record Response #x01
  [id UVarint integer?]
  [data Record any/c])

(define-record Ping #x02)
(define-record Pong #x03)

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
