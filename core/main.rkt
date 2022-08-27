#lang racket/base

(require noise/backend
         noise/serde
         (prefix-in hn: "hn.rkt"))

(provide
 main)

(define-rpc (get-top-stories : (Listof hn:Story))
  (hn:get-top-stories))

(define-rpc (get-comments [for-item id : UVarint] : (Listof hn:Comment))
  (hn:get-comments id))

(define (main in-fd out-fd)
  (module-cache-clear!)
  (collect-garbage)
  (define stop
    (serve in-fd out-fd))
  (with-handlers ([exn:break? (λ (_) (stop))])
    (sync never-evt)))
