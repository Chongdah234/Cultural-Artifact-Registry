(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_ARTIFACT_NOT_FOUND (err u101))
(define-constant ERR_INSUFFICIENT_FUNDS (err u102))
(define-constant ERR_INVALID_METADATA (err u103))
(define-constant ERR_STORY_NOT_FOUND (err u104))
(define-constant ERR_ALREADY_EXISTS (err u105))
(define-constant ERR_ALREADY_FAVORITED (err u106))
(define-constant ERR_NOT_FAVORITED (err u107))
(define-constant ERR_COLLECTION_NOT_FOUND (err u108))
(define-constant ERR_ARTIFACT_NOT_IN_COLLECTION (err u109))
(define-constant ERR_ARTIFACT_ALREADY_IN_COLLECTION (err u110))

(define-data-var contract-owner principal tx-sender)
(define-data-var next-artifact-id uint u1)
(define-data-var next-collection-id uint u1)
(define-data-var total-donations uint u0)

(define-map artifacts
  { artifact-id: uint }
  {
    creator: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    location: (string-ascii 100),
    historical-period: (string-ascii 50),
    cultural-significance: (string-ascii 300),
    image-url: (string-ascii 200),
    created-at: uint,
    donation-total: uint,
    verified: bool
  }
)

(define-map artifact-stories
  { artifact-id: uint, story-id: uint }
  {
    narrator: principal,
    title: (string-ascii 100),
    content: (string-ascii 1000),
    audio-url: (optional (string-ascii 200)),
    created-at: uint,
    verified: bool
  }
)

(define-map artifact-story-count
  { artifact-id: uint }
  { count: uint }
)

(define-map community-roles
  { community: principal, member: principal }
  { role: (string-ascii 20) }
)

(define-map artifact-donations
  { artifact-id: uint, donor: principal }
  { amount: uint, timestamp: uint }
)

(define-map user-profiles
  { user: principal }
  {
    display-name: (string-ascii 50),
    bio: (string-ascii 200),
    total-artifacts: uint,
    total-stories: uint,
    reputation-score: uint
  }
)

(define-map artifact-favorites
  { user: principal, artifact-id: uint }
  { favorited-at: uint }
)

(define-map user-favorites-count
  { user: principal }
  { count: uint }
)

(define-map collections
  { collection-id: uint }
  {
    creator: principal,
    title: (string-ascii 100),
    description: (string-ascii 300),
    created-at: uint,
    artifact-count: uint
  }
)

(define-map collection-artifacts
  { collection-id: uint, artifact-id: uint }
  { added-at: uint }
)

(define-map user-collections-count
  { user: principal }
  { count: uint }
)

(define-public (mint-artifact 
  (title (string-ascii 100))
  (description (string-ascii 500))
  (location (string-ascii 100))
  (historical-period (string-ascii 50))
  (cultural-significance (string-ascii 300))
  (image-url (string-ascii 200)))
  (let 
    (
      (artifact-id (var-get next-artifact-id))
      (current-height (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
    )
    (asserts! (> (len title) u0) ERR_INVALID_METADATA)
    (asserts! (> (len description) u0) ERR_INVALID_METADATA)
    
    (map-set artifacts
      { artifact-id: artifact-id }
      {
        creator: tx-sender,
        title: title,
        description: description,
        location: location,
        historical-period: historical-period,
        cultural-significance: cultural-significance,
        image-url: image-url,
        created-at: current-height,
        donation-total: u0,
        verified: false
      }
    )
    
    (map-set artifact-story-count
      { artifact-id: artifact-id }
      { count: u0 }
    )
    
    (update-user-stats tx-sender u1 u0)
    (var-set next-artifact-id (+ artifact-id u1))
    (ok artifact-id)
  )
)

(define-public (add-story
  (artifact-id uint)
  (title (string-ascii 100))
  (content (string-ascii 1000))
  (audio-url (optional (string-ascii 200))))
  (let
    (
      (artifact (unwrap! (map-get? artifacts { artifact-id: artifact-id }) ERR_ARTIFACT_NOT_FOUND))
      (story-count-data (unwrap! (map-get? artifact-story-count { artifact-id: artifact-id }) ERR_ARTIFACT_NOT_FOUND))
      (story-id (+ (get count story-count-data) u1))
      (current-height (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
    )
    (asserts! (> (len title) u0) ERR_INVALID_METADATA)
    (asserts! (> (len content) u0) ERR_INVALID_METADATA)
    
    (map-set artifact-stories
      { artifact-id: artifact-id, story-id: story-id }
      {
        narrator: tx-sender,
        title: title,
        content: content,
        audio-url: audio-url,
        created-at: current-height,
        verified: false
      }
    )
    
    (map-set artifact-story-count
      { artifact-id: artifact-id }
      { count: story-id }
    )
    
    (update-user-stats tx-sender u0 u1)
    (ok story-id)
  )
)

(define-public (donate-to-artifact (artifact-id uint) (amount uint))
  (let
    (
      (artifact (unwrap! (map-get? artifacts { artifact-id: artifact-id }) ERR_ARTIFACT_NOT_FOUND))
      (current-height (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
    )
    (asserts! (> amount u0) ERR_INSUFFICIENT_FUNDS)
    
    (try! (stx-transfer? amount tx-sender (get creator artifact)))
    
    (map-set artifacts
      { artifact-id: artifact-id }
      (merge artifact { donation-total: (+ (get donation-total artifact) amount) })
    )
    
    (map-set artifact-donations
      { artifact-id: artifact-id, donor: tx-sender }
      { amount: amount, timestamp: current-height }
    )
    
    (var-set total-donations (+ (var-get total-donations) amount))
    (ok true)
  )
)

(define-public (verify-artifact (artifact-id uint))
  (let
    (
      (artifact (unwrap! (map-get? artifacts { artifact-id: artifact-id }) ERR_ARTIFACT_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_NOT_AUTHORIZED)
    
    (map-set artifacts
      { artifact-id: artifact-id }
      (merge artifact { verified: true })
    )
    (ok true)
  )
)

(define-public (verify-story (artifact-id uint) (story-id uint))
  (let
    (
      (story (unwrap! (map-get? artifact-stories { artifact-id: artifact-id, story-id: story-id }) ERR_STORY_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_NOT_AUTHORIZED)
    
    (map-set artifact-stories
      { artifact-id: artifact-id, story-id: story-id }
      (merge story { verified: true })
    )
    (ok true)
  )
)

(define-public (update-profile
  (display-name (string-ascii 50))
  (bio (string-ascii 200)))
  (let
    (
      (current-profile (default-to 
        { display-name: "", bio: "", total-artifacts: u0, total-stories: u0, reputation-score: u0 }
        (map-get? user-profiles { user: tx-sender })
      ))
    )
    (map-set user-profiles
      { user: tx-sender }
      (merge current-profile { display-name: display-name, bio: bio })
    )
    (ok true)
  )
)

(define-public (set-community-role (community principal) (member principal) (role (string-ascii 20)))
  (begin
    (asserts! (is-eq tx-sender community) ERR_NOT_AUTHORIZED)
    (map-set community-roles
      { community: community, member: member }
      { role: role }
    )
    (ok true)
  )
)

(define-public (favorite-artifact (artifact-id uint))
  (let
    (
      (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
      (current-count (get count (default-to { count: u0 } (map-get? user-favorites-count { user: tx-sender }))))
      (artifact-exists (is-some (map-get? artifacts { artifact-id: artifact-id })))
    )
    (asserts! artifact-exists ERR_ARTIFACT_NOT_FOUND)
    (asserts! (is-none (map-get? artifact-favorites { user: tx-sender, artifact-id: artifact-id })) ERR_ALREADY_FAVORITED)
    
    (map-set artifact-favorites
      { user: tx-sender, artifact-id: artifact-id }
      { favorited-at: current-time }
    )
    
    (map-set user-favorites-count
      { user: tx-sender }
      { count: (+ current-count u1) }
    )
    
    (ok true)
  )
)

(define-public (unfavorite-artifact (artifact-id uint))
  (let
    (
      (current-count (get count (default-to { count: u0 } (map-get? user-favorites-count { user: tx-sender }))))
      (favorite-exists (is-some (map-get? artifact-favorites { user: tx-sender, artifact-id: artifact-id })))
    )
    (asserts! favorite-exists ERR_NOT_FAVORITED)
    
    (map-delete artifact-favorites { user: tx-sender, artifact-id: artifact-id })
    
    (map-set user-favorites-count
      { user: tx-sender }
      { count: (if (> current-count u0) (- current-count u1) u0) }
    )
    
    (ok true)
  )
)

(define-public (create-collection
  (title (string-ascii 100))
  (description (string-ascii 300)))
  (let
    (
      (collection-id (var-get next-collection-id))
      (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
      (current-count (get count (default-to { count: u0 } (map-get? user-collections-count { user: tx-sender }))))
    )
    (asserts! (> (len title) u0) ERR_INVALID_METADATA)
    (asserts! (> (len description) u0) ERR_INVALID_METADATA)
    
    (map-set collections
      { collection-id: collection-id }
      {
        creator: tx-sender,
        title: title,
        description: description,
        created-at: current-time,
        artifact-count: u0
      }
    )
    
    (map-set user-collections-count
      { user: tx-sender }
      { count: (+ current-count u1) }
    )
    
    (var-set next-collection-id (+ collection-id u1))
    (ok collection-id)
  )
)

(define-public (add-artifact-to-collection (collection-id uint) (artifact-id uint))
  (let
    (
      (collection (unwrap! (map-get? collections { collection-id: collection-id }) ERR_COLLECTION_NOT_FOUND))
      (artifact (unwrap! (map-get? artifacts { artifact-id: artifact-id }) ERR_ARTIFACT_NOT_FOUND))
      (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
    )
    (asserts! (is-eq tx-sender (get creator collection)) ERR_NOT_AUTHORIZED)
    (asserts! (is-none (map-get? collection-artifacts { collection-id: collection-id, artifact-id: artifact-id })) ERR_ARTIFACT_ALREADY_IN_COLLECTION)
    
    (map-set collection-artifacts
      { collection-id: collection-id, artifact-id: artifact-id }
      { added-at: current-time }
    )
    
    (map-set collections
      { collection-id: collection-id }
      (merge collection { artifact-count: (+ (get artifact-count collection) u1) })
    )
    
    (ok true)
  )
)

(define-public (remove-artifact-from-collection (collection-id uint) (artifact-id uint))
  (let
    (
      (collection (unwrap! (map-get? collections { collection-id: collection-id }) ERR_COLLECTION_NOT_FOUND))
      (artifact-in-collection (unwrap! (map-get? collection-artifacts { collection-id: collection-id, artifact-id: artifact-id }) ERR_ARTIFACT_NOT_IN_COLLECTION))
    )
    (asserts! (is-eq tx-sender (get creator collection)) ERR_NOT_AUTHORIZED)
    
    (map-delete collection-artifacts { collection-id: collection-id, artifact-id: artifact-id })
    
    (map-set collections
      { collection-id: collection-id }
      (merge collection { artifact-count: (if (> (get artifact-count collection) u0) (- (get artifact-count collection) u1) u0) })
    )
    
    (ok true)
  )
)

(define-read-only (get-artifact (artifact-id uint))
  (map-get? artifacts { artifact-id: artifact-id })
)

(define-read-only (get-story (artifact-id uint) (story-id uint))
  (map-get? artifact-stories { artifact-id: artifact-id, story-id: story-id })
)

(define-read-only (get-story-count (artifact-id uint))
  (default-to { count: u0 } (map-get? artifact-story-count { artifact-id: artifact-id }))
)

(define-read-only (get-user-profile (user principal))
  (map-get? user-profiles { user: user })
)

(define-read-only (get-donation (artifact-id uint) (donor principal))
  (map-get? artifact-donations { artifact-id: artifact-id, donor: donor })
)

(define-read-only (get-community-role (community principal) (member principal))
  (map-get? community-roles { community: community, member: member })
)

(define-read-only (get-next-artifact-id)
  (var-get next-artifact-id)
)

(define-read-only (get-total-donations)
  (var-get total-donations)
)

(define-read-only (get-contract-owner)
  (var-get contract-owner)
)

(define-read-only (is-artifact-favorited (user principal) (artifact-id uint))
  (is-some (map-get? artifact-favorites { user: user, artifact-id: artifact-id }))
)

(define-read-only (get-user-favorite (user principal) (artifact-id uint))
  (map-get? artifact-favorites { user: user, artifact-id: artifact-id })
)

(define-read-only (get-user-favorites-count (user principal))
  (default-to { count: u0 } (map-get? user-favorites-count { user: user }))
)

(define-read-only (get-collection (collection-id uint))
  (map-get? collections { collection-id: collection-id })
)

(define-read-only (get-next-collection-id)
  (var-get next-collection-id)
)

(define-read-only (is-artifact-in-collection (collection-id uint) (artifact-id uint))
  (is-some (map-get? collection-artifacts { collection-id: collection-id, artifact-id: artifact-id }))
)

(define-read-only (get-collection-artifact (collection-id uint) (artifact-id uint))
  (map-get? collection-artifacts { collection-id: collection-id, artifact-id: artifact-id })
)

(define-read-only (get-user-collections-count (user principal))
  (default-to { count: u0 } (map-get? user-collections-count { user: user }))
)

(define-private (update-user-stats (user principal) (artifacts-delta uint) (stories-delta uint))
  (let
    (
      (current-profile (default-to 
        { display-name: "", bio: "", total-artifacts: u0, total-stories: u0, reputation-score: u0 }
        (map-get? user-profiles { user: user })
      ))
      (new-artifacts (+ (get total-artifacts current-profile) artifacts-delta))
      (new-stories (+ (get total-stories current-profile) stories-delta))
      (new-reputation (+ (get reputation-score current-profile) (* artifacts-delta u10) (* stories-delta u5)))
    )
    (map-set user-profiles
      { user: user }
      (merge current-profile { 
        total-artifacts: new-artifacts, 
        total-stories: new-stories,
        reputation-score: new-reputation
      })
    )
  )
)
