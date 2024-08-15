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
  (let/cc trap
    (parameterize ([exit-handler
                    (lambda (err-or-code)
                      (when (exn:fail? err-or-code)
                        ((error-display-handler)
                         (format "trap: ~a" (exn-message err-or-code))
                         err-or-code))
                      (trap))])
      (define stop (serve in-fd out-fd))
      (with-handlers ([exn:break? void])
        (sync never-evt))
      (stop))))
