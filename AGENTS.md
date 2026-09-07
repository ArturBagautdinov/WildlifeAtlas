# Wildlife Atlas — Engineering Guidelines

## Source of Truth

`ios-trainee-assignment-autumn-2026.md` contains the original take-home assignment and is the authoritative source of product requirements.

Before planning or implementing any feature:

1. Read `ios-trainee-assignment-autumn-2026.md`.
2. Read this `AGENTS.md`.
3. Inspect the current repository and existing implementation.
4. Inspect the current git branch and working tree.

Never intentionally:

* omit a requirement;
* weaken a requirement;
* silently reinterpret a requirement;
* replace a required behavior with a technically easier alternative.

If an architectural decision conflicts with the assignment, the assignment wins.

---

# Project

The application is **Wildlife Atlas**, an iOS application for browsing public wildlife observations using the iNaturalist API.

The application is implemented as a production-quality take-home project while keeping the architecture proportional to its size.

Avoid both under-engineering and unnecessary enterprise-level abstraction.

---

# Technology Constraints

Use:

* Swift
* UIKit
* URLSession
* Swift Concurrency (`async/await`)
* XCTest
* Apple SDK frameworks only
* Auto Layout
* Programmatic UIKit unless an existing project decision explicitly requires otherwise

Do not introduce third-party libraries.

Do not use:

* Alamofire
* Kingfisher
* SnapKit
* RxSwift
* Swinject
* external persistence libraries
* external networking libraries
* external image-loading libraries

---

# Architecture

Use:

* MVVM
* lightweight Coordinator-based navigation
* dependency injection through initializers
* protocol-based abstractions where they improve testability or clearly separate responsibilities

The architecture should remain simple enough for a two-screen take-home application.

Do not introduce abstractions purely for architectural aesthetics.

---

# Responsibility Boundaries

## ViewController

A `UIViewController` is responsible for:

* creating and configuring UIKit views;
* rendering ViewModel state;
* forwarding user actions to the ViewModel or Coordinator;
* collection view and UIKit-specific behavior;
* accessibility configuration;
* navigation callbacks where appropriate.

A ViewController must not:

* perform network requests;
* directly use URLSession;
* construct API URLs;
* decode API responses;
* contain domain business rules;
* directly access persistence.

---

## ViewModel

A ViewModel is responsible for:

* screen presentation state;
* feature orchestration;
* reacting to user intents;
* calling repositories or stores;
* transforming domain data into presentation-friendly state;
* coordinating loading/content/empty/error transitions.

UI-facing ViewModels should normally be isolated to `@MainActor`.

A ViewModel must not:

* import UIKit unless there is a strong documented reason;
* construct raw HTTP requests;
* directly use URLSession;
* depend on concrete persistence implementations.

---

## Repository

Repositories provide domain-facing access to remote data.

Examples:

* `ObservationsRepository`
* `TaxaRepository`

Repositories may use the API client but should not contain UIKit logic.

ViewModels should depend on repository abstractions rather than concrete network implementations when this improves testability.

---

## Networking

The networking layer is responsible for:

* constructing requests;
* query parameters;
* HTTP transport;
* status-code validation;
* decoding;
* network error mapping.

Use `URLSession`.

Prefer:

* `URL`
* `URLComponents`
* `URLQueryItem`

Do not manually concatenate query strings.

---

# DTO and Domain Separation

Network DTOs and domain models are separate concepts.

Example flow:

```text
JSON
 ↓
ObservationDTO
 ↓ Mapper
Observation
 ↓
ViewModel
 ↓
ViewState / presentation model
 ↓
ViewController
```

DTOs represent the external API.

Domain models represent data used by application features.

Do not pass API DTOs directly into ViewControllers or cells.

Do not make domain models depend on networking implementation details.

---

# iNaturalist API Rules

Use the current iNaturalist API required by the assignment.

Observation-list requests must always include:

```text
captive=false
```

Treat this as a networking invariant.

Do not rely on individual ViewModels remembering to add it.

Selected taxa should be sent using their taxon identifier where applicable.

Observation sorting must follow the assignment requirement and be based on observation date.

Filters must map correctly to API parameters.

Do not add authentication unless required by an assignment feature.

The application works only with public read-only data.

---

# Filters

The Explore screen contains three independent filters:

* taxon;
* observation quality;
* sort order.

Represent the complete filter selection as one value whenever practical.

Example concept:

```swift
struct ObservationFilters: Equatable {
    var taxon: Taxon?
    var quality: QualityFilter
    var order: ObservationOrder
}
```

Changing one filter must preserve the other two.

Changing any filter must:

1. cancel or invalidate obsolete loading work;
2. reset pagination;
3. load page 1 using the complete current filter state.

Results belonging to obsolete filters must never overwrite newer results.

---

# Pagination

Pagination must be safe against duplicate requests.

Before requesting another page, validate at least:

* another page is available;
* another pagination request is not already running.

Existing content must remain visible while loading the next page.

Do not replace the entire screen with a full-screen loading state during pagination.

A next-page failure must not discard already loaded observations.

---

# Taxon Search

Taxon autocomplete must support dynamic searching.

Implement appropriate:

* debounce;
* request cancellation;
* stale-response protection.

If the user types:

```text
f
fo
fox
```

a late response for `fo` must never replace results already received for `fox`.

Do not perform remote autocomplete requests for an empty search query.

When the optional recent-taxa feature is implemented:

* store at most five;
* keep them unique;
* selecting an existing item moves it to the most recent position.

Persistence must be behind an abstraction such as `RecentTaxaStore`.

---

# Screen State

Every remotely loaded screen must correctly support:

* loading;
* content;
* empty;
* error with retry.

Prefer explicit state modeling over multiple unrelated Boolean properties.

Example concept:

```swift
enum ViewState {
    case loading
    case content
    case empty
    case error
}
```

Pagination loading should be represented separately from the screen's initial loading state.

Do not allow contradictory states such as:

```text
isLoading = true
hasError = true
isEmpty = true
```

---

# Observation Detail

The observation detail screen must open using the selected observation identifier.

Preferred flow:

```text
Explore
 ↓ observation ID
Coordinator
 ↓
ObservationDetailViewModel(id:)
 ↓
ObservationsRepository
 ↓
GET observation by ID
```

Do not make an object already loaded by Explore the authoritative source for detail data if the assignment explicitly requires loading the screen by identifier.

Returning from Detail must preserve the Explore screen's:

* previously loaded observations;
* selected filters;
* selected list/grid mode;
* scroll position.

Do not unnecessarily recreate the Explore ViewController.

Do not automatically reload Explore in `viewWillAppear` if doing so destroys this state.

---

# Location and Privacy

This requirement is critical.

Never display exact observation coordinates.

Do not use Core Location.

Do not request the user's location.

Do not display location information for observations where location is private, hidden, or otherwise unsafe to expose according to the assignment/API response.

Prefer approximate server-provided textual location information.

If safe approximate location information is unavailable, omit the location UI completely.

Never create a textual latitude/longitude fallback.

---

# Missing Data

API fields may be optional.

If information required for a UI element is missing:

* omit the UI element;
* collapse unnecessary spacing;
* avoid misleading placeholder information.

Do not invent values such as:

```text
Unknown
N/A
-
No data
```

unless there is a deliberate UX reason consistent with the assignment.

---

# Image Loading

Use Apple APIs only.

Implement an in-memory image cache using `NSCache`.

The image-loading dependency should be injectable.

Reusable collection-view cells must be protected against image reuse races.

Scenario to prevent:

```text
Cell represents Fox
 ↓
fox.jpg begins downloading
 ↓
cell reused for Bear
 ↓
bear.jpg begins downloading
 ↓
fox.jpg finishes later
 ↓
cell incorrectly displays Fox
```

Use cancellation and/or represented-item identity checking.

Cancel unnecessary image tasks during cell reuse where appropriate.

Do not introduce disk image caching unless there is a demonstrated requirement.

---

# UICollectionView

Prefer `UICollectionView` for the Explore screen.

Prefer `UICollectionViewDiffableDataSource` when it simplifies state updates.

The list/grid requirement should preferably use the same collection view with different layouts rather than two unrelated screens.

Use modern UIKit APIs where they provide a concrete benefit.

Do not introduce complicated abstractions around UICollectionView without a reason.

---

# Concurrency

Prefer Swift structured concurrency.

Use:

* `async/await`
* `Task`
* cancellation
* `@MainActor`

when appropriate.

Do not introduce detached tasks without a specific reason.

Do not ignore task cancellation where obsolete work can occur.

Avoid race conditions involving:

* search;
* filter changes;
* pagination;
* image loading;
* screen lifecycle.

Never update UIKit from an unsafe background execution context.

---

# Dependency Injection

Use initializer-based dependency injection whenever practical.

The application composition root may create concrete implementations.

Example:

```text
AppContainer
 ↓
APIClient
 ↓
RemoteObservationsRepository
 ↓
ExploreViewModel
 ↓
ExploreViewController
```

Avoid:

* global mutable state;
* feature code reaching into `AppDelegate`;
* service locator calls from ViewModels;
* unnecessary singleton dependencies.

---

# Persistence

Persistence must be hidden behind small abstractions.

Examples:

```text
FavoritesStore
RecentTaxaStore
```

Keep persistence proportional to the amount and complexity of stored data.

Do not introduce Core Data solely to store a small set of identifiers or five recent taxa unless there is a concrete reason.

---

# Favorites

Favorites are local application data.

Feature code should not directly access persistence APIs.

Favorites must support:

* adding;
* removing;
* duplicate-safe behavior;
* persistence across application launches;
* empty state.

Opening a favorite observation should navigate to Observation Detail using its observation ID.

---

# Testing

Testing is part of each feature implementation.

Do not postpone all tests until the end of the project.

Use repository mocks for ViewModel tests.

Use configurable `URLSession` and `URLProtocol` stubs for networking tests where appropriate.

Prioritize tests for behavior and business rules over implementation details.

Important test areas include:

* request construction;
* `captive=false`;
* filtering;
* filter independence;
* pagination;
* duplicate pagination protection;
* network errors;
* retry;
* loading/content/empty/error states;
* stale search protection;
* recent taxa;
* DTO decoding;
* optional/missing API fields;
* location privacy;
* favorites persistence;
* ViewModel state transitions.

Do not add large brittle UI-test suites without a concrete reason.

A small number of valuable smoke tests is preferable.

---

# Accessibility

Use UIKit accessibility APIs where appropriate.

Interactive controls should have meaningful accessibility information.

Images should have useful accessibility behavior where appropriate.

Do not sacrifice normal UIKit semantics with unnecessarily custom controls.

---

# Error Handling

Do not swallow errors.

Avoid:

```swift
try? ...
```

when failure materially affects feature behavior.

Map technical errors into user-presentable state at an appropriate layer.

Retry actions must actually retry the failed operation.

Do not expose raw technical error descriptions directly to users unless appropriate.

---

# Memory Management

Review escaping closures for retain cycles.

Use `[weak self]` where retaining `self` would create an ownership cycle.

Do not mechanically add `[weak self]` to every closure.

Understand the ownership relationship before choosing capture semantics.

Collection-view cells must not retain obsolete image-loading tasks indefinitely.

---

# Code Quality

Prefer:

* small focused types;
* descriptive names;
* explicit responsibilities;
* readable code;
* predictable control flow.

Avoid:

* massive ViewControllers;
* massive ViewModels;
* generic abstractions without current consumers;
* duplicate API request-building logic;
* unused code;
* force unwraps without a guaranteed invariant;
* unexplained magic values;
* unrelated refactoring in feature branches.

Do not create a protocol for every concrete type merely for stylistic symmetry.

Protocols should provide a real benefit such as:

* testing;
* interchangeable implementations;
* architectural boundary.

---

# Git / Branch Scope

Each feature branch should contain one coherent engineering change.

Do not opportunistically modify unrelated components.

Before implementation:

1. verify the current branch;
2. inspect the diff against `main`;
3. understand existing code.

After implementation:

1. build;
2. run relevant tests;
3. inspect `git diff`;
4. verify the branch against the assignment;
5. check for unintended files or unrelated changes.

Do not commit or merge unless explicitly requested.

---

# AI Development Workflow

AI is an engineering assistant, not the source of truth.

For every substantial task, follow:

```text
Requirement
 ↓
AI planning
 ↓
Human review
 ↓
AI-assisted implementation
 ↓
Build and tests
 ↓
AI code review
 ↓
Human review
 ↓
Merge request
```

---

# Planning Rules for AI Agents

Before modifying code:

1. Read `ios-trainee-assignment-autumn-2026.md`.
2. Read `AGENTS.md`.
3. Inspect relevant existing code.
4. Inspect git status and current branch.
5. State your understanding of the branch requirement.
6. Identify affected files/components.
7. Present an implementation plan.
8. Identify important edge cases.
9. Identify tests that should be added.

For significant changes, stop after planning and wait for approval before editing files when explicitly requested by the task prompt.

---

# Implementation Rules for AI Agents

During implementation:

* stay within the branch scope;
* preserve existing architecture unless there is a demonstrated problem;
* do not silently add features;
* do not remove assignment requirements;
* do not perform unrelated refactors;
* do not add dependencies;
* update or add tests together with behavior;
* use existing components before creating equivalent replacements.

After implementation:

1. build the project;
2. run relevant tests;
3. inspect the resulting diff;
4. verify requirements against `ios-trainee-assignment-autumn-2026.md`;
5. report changed files;
6. report architectural decisions;
7. report tests executed and their actual results;
8. report remaining risks or unverified behavior.

Never claim that a build or test passed unless it was actually executed successfully.

---

# AI Review Rules

When reviewing AI-generated or human-generated code:

Prioritize:

1. assignment compliance;
2. correctness;
3. privacy;
4. concurrency;
5. state consistency;
6. memory management;
7. test coverage;
8. maintainability;
9. unnecessary complexity.

Classify findings as:

* CRITICAL
* IMPORTANT
* MINOR

Do not suggest unrelated refactoring merely to produce more review comments.

---

# Documentation

Maintain:

* `README.md`
* `AI_USAGE.md`
* key AI prompts where useful

Recommended structure:

```text
docs/
└── ai/
    └── prompts/
```

Important decisions should explain both:

* what was chosen;
* why it was chosen.

`AI_USAGE.md` must truthfully describe actual AI usage.

Do not claim:

* a model version that was not actually used;
* tests that were not run;
* human decisions that were actually accepted automatically.

Document meaningful rejected AI suggestions and the reason they were rejected.

---

# Definition of Done

A feature is not considered complete merely because code was generated.

A feature is complete when:

* the relevant assignment requirements are satisfied;
* the code builds;
* relevant tests pass;
* important manual behavior has been verified where appropriate;
* loading/content/empty/error behavior remains correct;
* privacy requirements remain satisfied;
* no unintended regressions are apparent;
* the branch contains no unrelated changes;
* the implementation remains understandable and proportional to the project.

