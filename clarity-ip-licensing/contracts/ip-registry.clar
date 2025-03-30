;; IP Registry Smart Contract
;; Manages the registration and core metadata for intellectual property assets

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-ALREADY-EXISTS u101)
(define-constant ERR-INVALID-STATUS u102)
(define-constant ERR-NOT-FOUND u103)
(define-constant ERR-METADATA-TOO-LONG u104)
(define-constant ERR-INVALID-TYPE u105)
(define-constant ERR-TOO-MANY-IPS u106)

;; IP Status values - using string-ascii instead of string-utf8
(define-constant STATUS-ACTIVE "active")
(define-constant STATUS-DISPUTED "disputed")
(define-constant STATUS-ARCHIVED "archived")

;; IP Types - using string-ascii instead of string-utf8
(define-constant TYPE-MUSIC "music")
(define-constant TYPE-VIDEO "video")
(define-constant TYPE-TEXT "text")
(define-constant TYPE-SOFTWARE "software")
(define-constant TYPE-IMAGE "image")

;; Data structure for IP assets
(define-map ip-assets
  { ip-id: uint }
  {
    name: (string-ascii 100),
    description: (string-ascii 500),
    ip-type: (string-ascii 20),
    creator: principal,
    creation-date: uint,
    status: (string-ascii 20),
    metadata-uri: (optional (string-ascii 256))
  }
)

;; Map to track IP creators (for quick lookups)
(define-map creator-ips
  { creator: principal }
  { ip-ids: (list 100 uint) }
)

;; Counter for IP IDs
(define-data-var next-ip-id uint u1)

;; Get the next available IP ID and increment the counter
(define-private (get-next-ip-id)
  (let ((current-id (var-get next-ip-id)))
    (begin
      (var-set next-ip-id (+ current-id u1))
      current-id
    )
  )
)

;; Function to validate IP type
(define-private (valid-ip-type? (ip-type (string-ascii 20)))
  (or
    (is-eq ip-type TYPE-MUSIC)
    (is-eq ip-type TYPE-VIDEO)
    (is-eq ip-type TYPE-TEXT)
    (is-eq ip-type TYPE-SOFTWARE)
    (is-eq ip-type TYPE-IMAGE)
  )
)

;; Function to validate IP status
(define-private (valid-status? (status (string-ascii 20)))
  (or
    (is-eq status STATUS-ACTIVE)
    (is-eq status STATUS-DISPUTED)
    (is-eq status STATUS-ARCHIVED)
  )
)

;; Function to add an IP ID to a creator's list
(define-private (add-ip-to-creator (creator principal) (ip-id uint))
  (let (
        (current-ips (default-to { ip-ids: (list) } (map-get? creator-ips { creator: creator })))
        (current-list (get ip-ids current-ips))
      )
    ;; Check if we can safely add to the list
    (match (as-max-len? (append current-list ip-id) u100)
      success-list (begin
        (map-set creator-ips
          { creator: creator }
          { ip-ids: success-list }
        )
        (ok true))
      (err ERR-TOO-MANY-IPS))
  )
)

;; Register new IP
(define-public (register-ip
                (name (string-ascii 100))
                (description (string-ascii 500))
                (ip-type (string-ascii 20))
                (metadata-uri (optional (string-ascii 256)))
              )
  (let
    (
      (caller tx-sender)
      (ip-id (get-next-ip-id))
      (creation-time (get-block-info? time (- block-height u1)))
    )
    (asserts! (valid-ip-type? ip-type) (err ERR-INVALID-TYPE))
    (asserts! (is-some creation-time) (err u1)) ;; Fallback error if block info is unavailable
    
    ;; Register the IP
    (map-set ip-assets
      { ip-id: ip-id }
      {
        name: name,
        description: description,
        ip-type: ip-type,
        creator: caller,
        creation-date: (unwrap! creation-time (err u1)),
        status: STATUS-ACTIVE,
        metadata-uri: metadata-uri
      }
    )
    
    ;; Add IP to creator's list
    (unwrap! (add-ip-to-creator caller ip-id) (err ERR-TOO-MANY-IPS))
    
    ;; Return the new IP ID
    (ok ip-id)
  )
)

;; Get IP details
(define-read-only (get-ip (ip-id uint))
  (map-get? ip-assets { ip-id: ip-id })
)

;; Get all IPs created by a specific user
(define-read-only (get-creator-ips (creator principal))
  (default-to { ip-ids: (list) } (map-get? creator-ips { creator: creator }))
)

;; Update IP metadata
(define-public (update-ip-metadata
                (ip-id uint)
                (name (optional (string-ascii 100)))
                (description (optional (string-ascii 500)))
                (metadata-uri (optional (string-ascii 256)))
              )
  (let
    (
      (ip-data (unwrap! (map-get? ip-assets { ip-id: ip-id }) (err ERR-NOT-FOUND)))
      (caller tx-sender)
    )
    ;; Check if caller is the creator
    (asserts! (is-eq caller (get creator ip-data)) (err ERR-NOT-AUTHORIZED))
    
    ;; Update the metadata
    (map-set ip-assets
      { ip-id: ip-id }
      {
        name: (default-to (get name ip-data) name),
        description: (default-to (get description ip-data) description),
        ip-type: (get ip-type ip-data),
        creator: (get creator ip-data),
        creation-date: (get creation-date ip-data),
        status: (get status ip-data),
        metadata-uri: (if (is-some metadata-uri)
                          metadata-uri
                          (get metadata-uri ip-data))
      }
    )
    (ok true)
  )
)

;; Update IP status
(define-public (update-ip-status (ip-id uint) (new-status (string-ascii 20)))
  (let
    (
      (ip-data (unwrap! (map-get? ip-assets { ip-id: ip-id }) (err ERR-NOT-FOUND)))
      (caller tx-sender)
    )
    ;; Validate the new status
    (asserts! (valid-status? new-status) (err ERR-INVALID-STATUS))
    
    ;; Check if caller is the creator
    (asserts! (is-eq caller (get creator ip-data)) (err ERR-NOT-AUTHORIZED))
    
    ;; Update the status
    (map-set ip-assets
      { ip-id: ip-id }
      {
        name: (get name ip-data),
        description: (get description ip-data),
        ip-type: (get ip-type ip-data),
        creator: (get creator ip-data),
        creation-date: (get creation-date ip-data),
        status: new-status,
        metadata-uri: (get metadata-uri ip-data)
      }
    )
    (ok true)
  )
)

;; Check if IP exists
(define-read-only (ip-exists? (ip-id uint))
  (is-some (map-get? ip-assets { ip-id: ip-id }))
)

;; Initialize the contract
(begin
  (var-set next-ip-id u1)
)