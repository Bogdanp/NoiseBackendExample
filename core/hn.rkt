#lang racket/base

(require net/http-easy
         noise/serde
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
  [id UVarint]
  [title String]
  [comments (Listof UVarint)])

(define-record Comment
  [id UVarint]
  [text String])

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

(define (get-top-stories [limit 10])
  (define story-ids
    (response-json
     (get (~url "topstories.json"))))
  (for/list/concurrent ([id (in-list story-ids)]
                        [_ (in-range limit)])
    (get-story id)))

(define (get-comment id)
  (define data
    (get-item id))
  (make-Comment
   #:id (hash-ref data 'id -1)
   #:text (hash-ref data 'text "[DELETED]")))

(define (get-comments story-id)
  (define story
    (get-story story-id))
  (for/list/concurrent ([id (in-list (Story-comments story))])
    (get-comment id)))
