;; AI Model Marketplace Platform Smar Contract
;; A comprehensive blockchain-based marketplace for AI model distribution and monetization
;; Enables AI researchers and developers to securely publish, license, and generate revenue from their models
;; Features automated licensing, royalty distribution, version control, and decentralized access management

;; SYSTEM CONSTANTS AND ERROR DEFINITIONS

(define-constant contract-owner tx-sender)
(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-MODEL-NOT-FOUND (err u101))
(define-constant ERR-MODEL-ALREADY-EXISTS (err u102))
(define-constant ERR-INSUFFICIENT-PAYMENT (err u103))
(define-constant ERR-LICENSE-EXPIRED (err u104))
(define-constant ERR-ACCESS-DENIED (err u105))
(define-constant ERR-INVALID-PARAMETERS (err u106))
(define-constant ERR-MODEL-UNAVAILABLE (err u107))
(define-constant ERR-ACTIVE-LICENSE-EXISTS (err u108))

;; Platform configuration constants
(define-constant default-commission-rate u250) ;; 2.5% in basis points
(define-constant min-license-period u144) ;; Approximately 1 day in blocks
(define-constant max-license-period u52560) ;; Approximately 1 year in blocks
(define-constant max-commission-rate u1000) ;; 10% maximum commission
(define-constant max-file-size u999999999999) ;; Maximum model file size
(define-constant max-accuracy-score u10000) ;; 100% accuracy in basis points

;; DATA STRUCTURES AND STORAGE MAPS

;; Primary model registry storing core model information
(define-map model-registry
  { model-id: uint }
  {
    creator: principal,
    title: (string-ascii 64),
    description: (string-ascii 256),
    license-fee: uint,
    license-duration: uint,
    is-active: bool,
    created-at: uint,
    total-sales: uint
  }
)

;; License ownership and access control registry
(define-map license-registry
  { model-id: uint, licensee: principal }
  {
    expires-at: uint,
    purchased-at: uint,
    license-type: (string-ascii 32),
    amount-paid: uint
  }
)

;; Technical specifications and metadata storage
(define-map model-metadata
  { model-id: uint }
  {
    version: (string-ascii 16),
    file-hash: (string-ascii 64),
    file-size: uint,
    accuracy-score: uint,
    training-data-info: (string-ascii 128),
    hardware-requirements: (string-ascii 64),
    framework-compatibility: (string-ascii 128)
  }
)

;; Financial analytics and performance tracking
(define-map revenue-tracking
  { model-id: uint }
  {
    total-earnings: uint,
    active-licenses: uint,
    platform-fees-paid: uint,
    last-updated: uint
  }
)

;; SYSTEM STATE VARIABLES

(define-data-var next-model-id uint u1)
(define-data-var platform-commission-rate uint default-commission-rate)
(define-data-var minimum-license-duration uint min-license-period)
(define-data-var maximum-license-duration uint max-license-period)
(define-data-var platform-paused bool false)

;; READ-ONLY QUERY FUNCTIONS

(define-read-only (get-model-info (model-id uint))
  (map-get? model-registry { model-id: model-id })
)

(define-read-only (get-license-info (model-id uint) (user principal))
  (map-get? license-registry { model-id: model-id, licensee: user })
)

(define-read-only (get-model-metadata (model-id uint))
  (map-get? model-metadata { model-id: model-id })
)

(define-read-only (get-revenue-stats (model-id uint))
  (map-get? revenue-tracking { model-id: model-id })
)

(define-read-only (check-license-validity (model-id uint) (user principal))
  (match (get-license-info model-id user)
    license-data 
      (>= (get expires-at license-data) block-height)
    false
  )
)

(define-read-only (get-next-model-id)
  (var-get next-model-id)
)

(define-read-only (get-platform-commission-rate)
  (var-get platform-commission-rate)
)

(define-read-only (calculate-platform-fee (amount uint))
  (/ (* amount (var-get platform-commission-rate)) u10000)
)

(define-read-only (is-platform-operational)
  (not (var-get platform-paused))
)

(define-read-only (get-license-duration-limits)
  {
    minimum: (var-get minimum-license-duration),
    maximum: (var-get maximum-license-duration)
  }
)

;; PRIVATE VALIDATION AND UTILITY FUNCTIONS

(define-private (is-contract-owner)
  (is-eq tx-sender contract-owner)
)

(define-private (is-model-owner (model-id uint))
  (match (get-model-info model-id)
    model-data 
      (is-eq tx-sender (get creator model-data))
    false
  )
)

(define-private (is-valid-license-duration (duration uint))
  (and 
    (>= duration (var-get minimum-license-duration))
    (<= duration (var-get maximum-license-duration))
  )
)

(define-private (is-platform-active)
  (not (var-get platform-paused))
)

(define-private (validate-string-length (text (string-ascii 256)))
  (and 
    (> (len text) u0)
    (<= (len text) u256)
  )
)

(define-private (validate-short-string (text (string-ascii 64)))
  (and 
    (> (len text) u0)
    (<= (len text) u64)
  )
)

(define-private (validate-medium-string (text (string-ascii 128)))
  (and 
    (> (len text) u0)
    (<= (len text) u128)
  )
)

(define-private (validate-license-type (license-type (string-ascii 32)))
  (and 
    (> (len license-type) u0)
    (<= (len license-type) u32)
  )
)

(define-private (validate-version-string (version (string-ascii 16)))
  (and 
    (> (len version) u0)
    (<= (len version) u16)
  )
)

(define-private (validate-numeric-range (value uint) (min-val uint) (max-val uint))
  (and 
    (>= value min-val)
    (<= value max-val)
  )
)

(define-private (validate-hash-string (hash (string-ascii 64)))
  (and 
    (>= (len hash) u32)
    (<= (len hash) u64)
  )
)

(define-private (update-revenue-analytics 
    (model-id uint) 
    (payment-amount uint))
  (let (
    (current-stats (default-to 
      { 
        total-earnings: u0,
        active-licenses: u0,
        platform-fees-paid: u0,
        last-updated: u0
      }
      (get-revenue-stats model-id)))
    (platform-fee (calculate-platform-fee payment-amount))
  )
    (map-set revenue-tracking
      { model-id: model-id }
      {
        total-earnings: (+ (get total-earnings current-stats) payment-amount),
        active-licenses: (+ (get active-licenses current-stats) u1),
        platform-fees-paid: (+ (get platform-fees-paid current-stats) platform-fee),
        last-updated: block-height
      }
    )
  )
)

;; MODEL PUBLICATION AND REGISTRATION

(define-public (publish-model
    (title (string-ascii 64))
    (description (string-ascii 256))
    (license-fee uint)
    (license-duration uint)
    (version (string-ascii 16))
    (file-hash (string-ascii 64))
    (file-size uint)
    (accuracy-score uint)
    (training-info (string-ascii 128))
    (hardware-reqs (string-ascii 64))
    (frameworks (string-ascii 128)))
  (let (
    (new-model-id (var-get next-model-id))
  )
    ;; System operational checks
    (asserts! (is-platform-active) ERR-UNAUTHORIZED-ACCESS)
    
    ;; Input validation
    (asserts! (validate-short-string title) ERR-INVALID-PARAMETERS)
    (asserts! (validate-string-length description) ERR-INVALID-PARAMETERS)
    (asserts! (> license-fee u0) ERR-INVALID-PARAMETERS)
    (asserts! (is-valid-license-duration license-duration) ERR-INVALID-PARAMETERS)
    (asserts! (validate-version-string version) ERR-INVALID-PARAMETERS)
    (asserts! (validate-hash-string file-hash) ERR-INVALID-PARAMETERS)
    (asserts! (validate-numeric-range file-size u1 max-file-size) ERR-INVALID-PARAMETERS)
    (asserts! (validate-numeric-range accuracy-score u0 max-accuracy-score) ERR-INVALID-PARAMETERS)
    (asserts! (validate-medium-string training-info) ERR-INVALID-PARAMETERS)
    (asserts! (validate-short-string hardware-reqs) ERR-INVALID-PARAMETERS)
    (asserts! (validate-medium-string frameworks) ERR-INVALID-PARAMETERS)
    
    ;; Register model in primary registry
    (map-set model-registry
      { model-id: new-model-id }
      {
        creator: tx-sender,
        title: title,
        description: description,
        license-fee: license-fee,
        license-duration: license-duration,
        is-active: true,
        created-at: block-height,
        total-sales: u0
      }
    )
    
    ;; Store technical metadata
    (map-set model-metadata
      { model-id: new-model-id }
      {
        version: version,
        file-hash: file-hash,
        file-size: file-size,
        accuracy-score: accuracy-score,
        training-data-info: training-info,
        hardware-requirements: hardware-reqs,
        framework-compatibility: frameworks
      }
    )
    
    ;; Initialize revenue tracking
    (map-set revenue-tracking
      { model-id: new-model-id }
      {
        total-earnings: u0,
        active-licenses: u0,
        platform-fees-paid: u0,
        last-updated: block-height
      }
    )
    
    ;; Increment model counter
    (var-set next-model-id (+ new-model-id u1))
    
    (ok new-model-id)
  )
)

;; LICENSE ACQUISITION AND MANAGEMENT

(define-public (purchase-license 
    (model-id uint) 
    (license-type (string-ascii 32)))
  (let (
    (model-info (unwrap! (get-model-info model-id) ERR-MODEL-NOT-FOUND))
    (license-cost (get license-fee model-info))
    (platform-fee (calculate-platform-fee license-cost))
    (creator-payment (- license-cost platform-fee))
    (license-expiry (+ block-height (get license-duration model-info)))
  )
    ;; System and model validation
    (asserts! (is-platform-active) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (get is-active model-info) ERR-MODEL-UNAVAILABLE)
    (asserts! (validate-license-type license-type) ERR-INVALID-PARAMETERS)
    
    ;; Check for existing active license
    (asserts! (not (check-license-validity model-id tx-sender)) ERR-ACTIVE-LICENSE-EXISTS)
    
    ;; Process payments
    (try! (stx-transfer? creator-payment tx-sender (get creator model-info)))
    (try! (stx-transfer? platform-fee tx-sender contract-owner))
    
    ;; Create license record
    (map-set license-registry
      { model-id: model-id, licensee: tx-sender }
      {
        expires-at: license-expiry,
        purchased-at: block-height,
        license-type: license-type,
        amount-paid: license-cost
      }
    )
    
    ;; Update model statistics
    (map-set model-registry
      { model-id: model-id }
      (merge model-info 
        { total-sales: (+ (get total-sales model-info) u1) })
    )
    
    ;; Update revenue analytics
    (update-revenue-analytics model-id license-cost)
    
    (ok true)
  )
)

(define-public (renew-license (model-id uint))
  (let (
    (model-info (unwrap! (get-model-info model-id) ERR-MODEL-NOT-FOUND))
    (existing-license (unwrap! (get-license-info model-id tx-sender) ERR-MODEL-NOT-FOUND))
    (renewal-cost (get license-fee model-info))
    (platform-fee (calculate-platform-fee renewal-cost))
    (creator-payment (- renewal-cost platform-fee))
    (new-expiry (+ block-height (get license-duration model-info)))
  )
    ;; System validation
    (asserts! (is-platform-active) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (get is-active model-info) ERR-MODEL-UNAVAILABLE)
    
    ;; Process renewal payments
    (try! (stx-transfer? creator-payment tx-sender (get creator model-info)))
    (try! (stx-transfer? platform-fee tx-sender contract-owner))
    
    ;; Update license with new expiration
    (map-set license-registry
      { model-id: model-id, licensee: tx-sender }
      (merge existing-license 
        { expires-at: new-expiry })
    )
    
    ;; Update revenue tracking
    (update-revenue-analytics model-id renewal-cost)
    
    (ok true)
  )
)


;; MODEL MANAGEMENT FUNCTIONS


(define-public (update-model-info
    (model-id uint)
    (new-title (string-ascii 64))
    (new-description (string-ascii 256))
    (new-license-fee uint)
    (new-license-duration uint))
  (let (
    (model-info (unwrap! (get-model-info model-id) ERR-MODEL-NOT-FOUND))
  )
    ;; Authorization and validation
    (asserts! (is-platform-active) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-model-owner model-id) ERR-ACCESS-DENIED)
    (asserts! (validate-short-string new-title) ERR-INVALID-PARAMETERS)
    (asserts! (validate-string-length new-description) ERR-INVALID-PARAMETERS)
    (asserts! (> new-license-fee u0) ERR-INVALID-PARAMETERS)
    (asserts! (is-valid-license-duration new-license-duration) ERR-INVALID-PARAMETERS)
    
    ;; Update model information
    (map-set model-registry
      { model-id: model-id }
      (merge model-info {
        title: new-title,
        description: new-description,
        license-fee: new-license-fee,
        license-duration: new-license-duration
      })
    )
    
    (ok true)
  )
)

(define-public (update-model-metadata
    (model-id uint)
    (new-version (string-ascii 16))
    (new-file-hash (string-ascii 64))
    (new-file-size uint)
    (new-accuracy-score uint)
    (new-training-info (string-ascii 128))
    (new-hardware-reqs (string-ascii 64))
    (new-frameworks (string-ascii 128)))
  (begin
    ;; Authorization and validation
    (asserts! (is-platform-active) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-some (get-model-info model-id)) ERR-MODEL-NOT-FOUND)
    (asserts! (is-model-owner model-id) ERR-ACCESS-DENIED)
    (asserts! (validate-version-string new-version) ERR-INVALID-PARAMETERS)
    (asserts! (validate-hash-string new-file-hash) ERR-INVALID-PARAMETERS)
    (asserts! (validate-numeric-range new-file-size u1 max-file-size) ERR-INVALID-PARAMETERS)
    (asserts! (validate-numeric-range new-accuracy-score u0 max-accuracy-score) ERR-INVALID-PARAMETERS)
    (asserts! (validate-medium-string new-training-info) ERR-INVALID-PARAMETERS)
    (asserts! (validate-short-string new-hardware-reqs) ERR-INVALID-PARAMETERS)
    (asserts! (validate-medium-string new-frameworks) ERR-INVALID-PARAMETERS)
    
    ;; Update technical metadata
    (map-set model-metadata
      { model-id: model-id }
      {
        version: new-version,
        file-hash: new-file-hash,
        file-size: new-file-size,
        accuracy-score: new-accuracy-score,
        training-data-info: new-training-info,
        hardware-requirements: new-hardware-reqs,
        framework-compatibility: new-frameworks
      }
    )
    
    (ok true)
  )
)

(define-public (deactivate-model (model-id uint))
  (let (
    (model-info (unwrap! (get-model-info model-id) ERR-MODEL-NOT-FOUND))
  )
    (asserts! (is-platform-active) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-model-owner model-id) ERR-ACCESS-DENIED)
    
    (map-set model-registry
      { model-id: model-id }
      (merge model-info { is-active: false })
    )
    
    (ok true)
  )
)

(define-public (reactivate-model (model-id uint))
  (let (
    (model-info (unwrap! (get-model-info model-id) ERR-MODEL-NOT-FOUND))
  )
    (asserts! (is-platform-active) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-model-owner model-id) ERR-ACCESS-DENIED)
    
    (map-set model-registry
      { model-id: model-id }
      (merge model-info { is-active: true })
    )
    
    (ok true)
  )
)

;; PLATFORM ADMINISTRATION FUNCTIONS

(define-public (set-commission-rate (new-rate uint))
  (begin
    (asserts! (is-contract-owner) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (<= new-rate max-commission-rate) ERR-INVALID-PARAMETERS)
    (var-set platform-commission-rate new-rate)
    (ok true)
  )
)

(define-public (update-license-duration-limits 
    (new-minimum uint) 
    (new-maximum uint))
  (begin
    (asserts! (is-contract-owner) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (< new-minimum new-maximum) ERR-INVALID-PARAMETERS)
    (var-set minimum-license-duration new-minimum)
    (var-set maximum-license-duration new-maximum)
    (ok true)
  )
)

(define-public (pause-platform)
  (begin
    (asserts! (is-contract-owner) ERR-UNAUTHORIZED-ACCESS)
    (var-set platform-paused true)
    (ok true)
  )
)

(define-public (resume-platform)
  (begin
    (asserts! (is-contract-owner) ERR-UNAUTHORIZED-ACCESS)
    (var-set platform-paused false)
    (ok true)
  )
)

(define-public (admin-deactivate-model (model-id uint))
  (let (
    (model-info (unwrap! (get-model-info model-id) ERR-MODEL-NOT-FOUND))
  )
    (asserts! (is-contract-owner) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (> model-id u0) ERR-INVALID-PARAMETERS)
    
    (map-set model-registry
      { model-id: model-id }
      (merge model-info { is-active: false })
    )
    
    (ok true)
  )
)