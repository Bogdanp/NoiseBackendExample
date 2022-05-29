#lang racket/base

(require ffi/unsafe/port
         racket/match)

(provide
 (rename-out [serve/fds serve]))

(define (serve/fds in-fd out-fd)
  (module-cache-clear!)
  (collect-garbage)
  (serve
   (unsafe-file-descriptor->port in-fd 'in '(read))
   (unsafe-file-descriptor->port out-fd 'out '(write))))

(define (serve in out)
  (let loop ()
    (define msg (read in))
    (match msg
      ['(ping)
       (write '(pong) out)
       (flush-output out)
       (loop)]
      [_
       (eprintf "unexpected message: ~e~n" msg)
       (loop)])))
