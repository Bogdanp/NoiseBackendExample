#lang racket/base

(require net/http-easy
         noise/serde
         racket/date
         racket/format
         racket/promise
         racket/string)

(provide
 (record-out Story)
 (record-out Comment)
 get-top-stories
 get-comments)

(define (~url . args)
  (format "https://hacker-news.firebaseio.com/v0/~a" (string-join args "/")))

(define-record Story
  [id : UVarint]
  [title : String]
  [comments : (Listof UVarint)])

(define-record Comment
  [id : UVarint]
  [author : String]
  [timestamp : String]
  [text : String])

(define (get-item id)
  (define data
    (response-json
     (get (~url "item" (~a id ".json")))))
  (if (hash? data) data (hash)))

(define (get-story id)
  (define data
    (get-item id))
  (make-Story
   #:id (hash-ref data 'id)
   #:title (hash-ref data 'title)
   #:comments (hash-ref data 'kids null)))

(define (get-top-stories [limit 30])
  (define story-ids
    (response-json
     (get (~url "topstories.json"))))
  (for/list/concurrent ([id (in-list story-ids)]
                        [_ (in-range limit)])
    (get-story id)))

(define (get-comment id)
  (define data
    (get-item id))
  (and (not (hash-ref data 'deleted #f))
       (string=? (hash-ref data 'type "") "comment")
       (make-Comment
        #:id (hash-ref data 'id -1)
        #:author (hash-ref data 'by "<anon>")
        #:timestamp (date->string (seconds->date (hash-ref data 'time)) #t)
        #:text (expand-html (hash-ref data 'text "")))))

(define (get-comments item-id)
  (define data (get-item item-id))
  (filter values (for/list/concurrent ([id (in-list (hash-ref data 'kids null))])
                   (get-comment id))))

(define (expand-html text)
  (expand-html-entities
   (regexp-replace* #rx"<p>" text "\n")))

(define (expand-html-entities text)
  (regexp-replace* #rx"&([^;]+);" text (λ (all entity)
                                         (case entity
                                           [("amp")  "&"]
                                           [("gt")   ">"]
                                           [("lt")   "<"]
                                           [("quot") "\""]
                                           [else
                                            (define maybe-hex-num
                                              (and (string-prefix? entity "#x")
                                                   (string->number (substring entity 2) 16)))
                                            (if maybe-hex-num
                                                (string (integer->char maybe-hex-num))
                                                all)]))))
