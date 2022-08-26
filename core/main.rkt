#lang racket/base

(require noise/backend
         noise/serde)

(provide
 main)

(define-record Pong)

(define-rpc (ping : Pong)
  (Pong))

(define (main in-fd out-fd)
  (module-cache-clear!)
  (collect-garbage)
  (define stop
    (serve in-fd out-fd))
  (with-handlers ([exn:break? (λ (_) (stop))])
    (sync never-evt)))
