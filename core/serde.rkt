#lang racket/base

(require (for-syntax racket/base
                     racket/syntax
                     syntax/parse)
         racket/contract
         racket/generic
         racket/match
         racket/port)

;; record ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(provide
 define-record
 record?
 read-record
 write-record)

(define-generics record
  {write-record record [out]})

(define (read-record [in (current-input-port)])
  (define id (read-field Symbol in))
  (unless (hash-has-key? record-infos id)
    (error 'read-record "unknown record type ~a" id))
  (define r (hash-ref record-infos id))
  (apply
   (record-info-constructor r)
   (for/list ([f (in-list (record-info-fields r))])
     (read-field (record-field-type f) in))))

(define (do-write-record r v [out (current-output-port)])
  (write-field Symbol (record-info-id r) out)
  (for ([f (in-list (record-info-fields r))])
    (write-field (record-field-type f) ((record-field-accessor f) v) out)))

(define record-infos (make-hasheq))
(struct record-info (id constructor fields))
(struct record-field (id type accessor))

(define-syntax (define-record stx)
  (define (id-stx->keyword stx)
    (datum->syntax stx (string->keyword (symbol->string (syntax-e stx)))))

  (define-syntax-class record-field
    (pattern [id:id ft:expr ctc:expr]
             #:with kwd (id-stx->keyword #'id)
             #:with arg #'id
             #:with opt? #f)
    (pattern [(id:id def:expr) ft:expr ctc:expr]
             #:with kwd (id-stx->keyword #'id)
             #:with arg #'[id def]
             #:with opt? #t))

  (syntax-parse stx
    [(_ id:id fld:record-field ...)
     #:with id? (format-id #'id "~a?" #'id)
     #:with record-id (format-id #'id "record:~a" #'id)
     #:with constructor-id (format-id #'id "make-~a" #'id)
     #:with (constructor-arg ...) (apply
                                   append
                                   (for/list ([kwd (in-list (syntax-e #'(fld.kwd ...)))]
                                              [arg (in-list (syntax-e #'(fld.arg ...)))])
                                     (list kwd arg)))
     #:with (required-ctor-arg-ctc ...) (apply
                                         append
                                         (for/list ([opt? (in-list (syntax->datum #'(fld.opt? ...)))]
                                                    [kwd  (in-list (syntax-e #'(fld.kwd ...)))]
                                                    [ctc  (in-list (syntax-e #'(fld.ctc ...)))]
                                                    #:unless opt?)
                                           (list kwd ctc)))
     #:with (optional-ctor-arg-ctc ...) (apply
                                         append
                                         (for/list ([opt? (in-list (syntax->datum #'(fld.opt? ...)))]
                                                    [kwd  (in-list (syntax-e #'(fld.kwd ...)))]
                                                    [ctc  (in-list (syntax-e #'(fld.ctc ...)))]
                                                    #:when opt?)
                                           (list kwd ctc)))
     #:with (accessor-id ...) (for/list ([fld (in-list (syntax-e #'(fld.id ...)))])
                                (format-id fld "~a-~a" #'id fld))
     #'(begin
         (struct id (fld.id ...) #:transparent
           #:methods gen:record
           [(define (write-record self [out (current-output-port)])
              (do-write-record record-id self out))])
         (define record-id
           (record-info 'id id (list (record-field 'fld.id fld.ft accessor-id) ...)))
         (hash-set! record-infos 'id record-id)
         (define/contract (constructor-id constructor-arg ...)
           (->* (required-ctor-arg-ctc ...)
                (optional-ctor-arg-ctc ...)
                id?)
           (id fld.id ...)))]))

(module+ test
  (require racket/port
           rackunit)

  (test-case "record serde"
    (define-record Human
      [name String string?]
      [age Varint (integer-in 0 100)])
    (define h (make-Human #:name "Bogdan" #:age 30))
    (define bs (with-output-to-bytes (λ () (write-record h))))
    (check-equal? h (read-record (open-input-bytes bs)))))


;; varint ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (write-varint v [out (current-output-port)])
  (define bs
    (let loop ([bs null] [n (bitwise-xor
                             (arithmetic-shift v 1)
                             (if (< v 0) -1 0))])
      (define-values (q r)
        (quotient/remainder n #x80))
      (if (zero? q)
          (apply bytes (reverse (cons r bs)))
          (loop (cons (bitwise-ior r #x80 r) bs) q))))
  (write-bytes bs out))

(define (read-varint [in (current-input-port)])
  (define n
    (let loop ([s 0])
      (define b (read-byte in))
      (if (zero? (bitwise-and b #x80))
          (arithmetic-shift b s)
          (+ (arithmetic-shift (bitwise-and b #x7F) s)
             (loop (+ s 7))))))
  (if (zero? (bitwise-and n 1))
      (arithmetic-shift n -1)
      (bitwise-not (arithmetic-shift n -1))))


;; field ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(provide
 Listof)

(struct field-type (read-proc write-proc swift-proc))

(define (read-field t [in (current-input-port)])
  ((field-type-read-proc t) in))

(define (write-field t v [out (current-output-port)])
  ((field-type-write-proc t) v out))

(define (swift-type t)
  ((field-type-swift-proc t)))

(define-syntax (define-field-type stx)
  (syntax-parse stx
    [(_ id:id
        {~alt
         {~optional {~seq #:read read-expr:expr}}
         {~optional {~seq #:write write-expr:expr}}
         {~optional {~seq #:swift swift-expr:expr}}} ...)
     #'(begin
         (define id (field-type read-expr write-expr (~? swift-expr (λ () (symbol->string 'id)))))
         (provide id))]))

(define-field-type Bool
  #:read (λ (in)
           (= (read-byte in) 1))
  #:write (λ (b out)
            (write-byte (if b 1 0) out)))

(define-field-type Bytes
  #:read (λ (in)
           (read-bytes (read-varint in) in))
  #:write (λ (bs out)
            (write-varint (bytes-length bs) out)
            (write-bytes bs out))
  #:swift (λ () "Data"))

(define-field-type String
  #:read (λ (in)
           (bytes->string/utf-8 (read-bytes (read-varint in) in)))
  #:write (λ (s out)
            (define bs (string->bytes/utf-8 s))
            (write-varint (bytes-length bs) out)
            (write-bytes bs out)))

(define-field-type Symbol
  #:read (λ (in)
           (define len (read-varint in))
           (string->symbol (bytes->string/utf-8 (read-bytes len in))))
  #:write (λ (s out)
            (define bs (string->bytes/utf-8 (symbol->string s)))
            (write-varint (bytes-length bs) out)
            (write-bytes bs out)))

(define-field-type Varint
  #:read read-varint
  #:write write-varint)

(define (Listof t)
  (define read-proc (field-type-read-proc t))
  (define write-proc (field-type-write-proc t))
  (define swift-type ((field-type-swift-proc t)))
  (field-type
   (λ (in)
     (for/list ([_ (in-range (read-varint in))])
       (read-proc in)))
   (λ (vs out)
     (write-varint (length vs) out)
     (for-each (λ (v) (write-proc v out)) vs))
   (λ ()
     (format "[~a]" swift-type))))

(define-field-type Record
  #:read read-record
  #:write write-record)

(module+ test
  (test-case "complex field serde"
    (define-record Example
      [b Bool boolean?]
      [i Varint integer?]
      [s String string?]
      [l (Listof Varint) list?])
    (define v (Example #t -1 "hello" '(0 1 2 #x-FF #x7F #xFFFF)))
    (define bs (with-output-to-bytes (λ () (write-field Record v))))
    (check-equal? v (read-field Record (open-input-bytes bs)))))


;; swift ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(provide
 write-Swift-code)

(define (case-id id)
  (define s (symbol->string id))
  (string-set! s 0 (char-downcase (string-ref s 0)))
  (string->symbol s))

(define (indirect? r)
  (for/first ([f (in-list (record-info-fields r))]
              #:when (eq? Record (record-field-type f)))
    #t))

(define (write-Swift-code [out (current-output-port)])
  (fprintf out "// This file was automatically generated.~n")
  (fprintf out "import Foundation~n~n")

  (fprintf out "public enum Record: Readable, Writeable {~n")
  (define sorted-ids (sort (hash-keys record-infos) symbol<?))
  (for ([id (in-list sorted-ids)])
    (define r (hash-ref record-infos id))
    (define maybe-indirect
      (if (indirect? r)
          " indirect"
          ""))
    (fprintf out " ~a case ~a(~a)~n" maybe-indirect (case-id id) id))

  (fprintf out "  public static func read(from inp: InputPort, using buf: inout Data) -> Record? {~n")
  (fprintf out "    guard let sym = Symbol.read(from: inp, using: &buf) else {~n")
  (fprintf out "      return nil~n")
  (fprintf out "    }~n")
  (fprintf out "    switch sym {~n")
  (for ([id (in-list sorted-ids)])
    (fprintf out "    case \"~a\":~n" id)
    (fprintf out "      return .~a(~a.read(from: inp, using: &buf)!)~n" (case-id id) id))
  (fprintf out "    default:~n")
  (fprintf out "      return nil~n")
  (fprintf out "    }~n")
  (fprintf out "  }~n")

  (fprintf out "  public func write(to out: OutputPort) {~n")
  (fprintf out "    switch self {~n")
  (for ([id (in-list sorted-ids)])
    (fprintf out "    case .~a(let r): r.write(to: out)~n" (case-id id)))
  (fprintf out "    }~n")
  (fprintf out "  }~n")
  (fprintf out "}~n")

  (for ([id (in-list sorted-ids)])
    (define r (hash-ref record-infos id))
    (write-record-code r out)))

(define (write-record-code r [out (current-output-port)])
  (match-define (record-info id _constructor fields) r)
  (fprintf out "public struct ~a: Readable, Writeable {~n" id)
  (for ([f (in-list fields)])
    (fprintf out
             "  public let ~a: ~a~n"
             (record-field-id f)
             (swift-type (record-field-type f))))

  (fprintf out "  public init(~n")
  (define len (length fields))
  (for ([(f idx) (in-indexed (in-list fields))])
    (define last? (= idx (sub1 len)))
    (define maybe-comma (if last? "" ","))
    (define id (record-field-id f))
    (define type (swift-type (record-field-type f)))
    (fprintf out "    ~a: ~a~a~n" id type maybe-comma))
  (fprintf out "  ) {~n")
  (for ([f (in-list fields)])
    (define id (record-field-id f))
    (fprintf out "    self.~a = ~a~n" id id))
  (fprintf out "  }~n")

  (fprintf out "  public static func read(from inp: InputPort, using buf: inout Data) -> ~a? {~n" id)
  (fprintf out "    return ~a(~n" id)
  (for ([(f idx) (in-indexed (in-list fields))])
    (define last? (= idx (sub1 len)))
    (define maybe-comma (if last? "" ", "))
    (define id (record-field-id f))
    (define type (swift-type (record-field-type f)))
    (fprintf out "      ~a: ~a.read(from: inp, using: &buf)!~a~n" id type maybe-comma))
  (fprintf out "    )~n")
  (fprintf out "  }~n")

  (fprintf out "  public func write(to out: OutputPort) {~n")
  (fprintf out "    Symbol(\"~a\").write(to: out)~n" id)
  (for ([f (in-list fields)])
    (fprintf out "    ~a.write(to: out)~n" (record-field-id f)))
  (fprintf out "  }~n")

  (fprintf out "}~n"))
