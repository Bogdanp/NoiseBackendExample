#lang racket/base

(require noise/backend
         noise/serde
         racket/match)

(provide
 main)

(define-record Ping)
(define-record Pong)

(define (app msg)
  (match msg
    [(Ping)
     (Pong)]

    [_
     (error 'app "unexpected message: ~e" msg)]))

(define (main in-fd out-fd)
  (module-cache-clear!)
  (collect-garbage)
  (define stop
    (serve in-fd out-fd app))
  (with-handlers ([exn:break? (λ (_) (stop))])
    (sync never-evt)))
