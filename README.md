<h1 align="center">
  <img width="200" height="200" alt="Forest Fox Leaf Emblem" src="https://github.com/user-attachments/assets/fbbb0aba-3c23-4fa6-b9bb-b5dcc9e54337" />

</h1>

<h1 align="center">Wildlife Atlas</h1>

Wildlife Atlas is an iOS app for browsing public wildlife observations through the iNaturalist API.

## Features

- A feed of the latest public iNaturalist observations.
- Paginated observation loading.
- Switching between list and grid views.
- Taxon search using iNaturalist autocomplete.
- Independent filters for taxon, quality, and sort order.
- An observation detail screen opened by observation ID.
- A gallery of all available observation photos.
- Sharing the current observation.
- Locally saved favorite observations.
- An in-memory image cache.

## Requirements

- iOS: 26.0+
- Xcode: 26+
- Swift: 5
- UIKit
- URLSession
- XCTest / Swift Testing
- Apple SDK frameworks only
- No third-party dependencies

## Getting Started

Open the project:

```bash
open WildlifeAtlas/WildlifeAtlas.xcodeproj
```

Then:

1. Select the `WildlifeAtlas` scheme.
2. Select an iOS Simulator or a device.
3. Run the app with `Cmd + R`.

Build from the command line:

```bash
xcodebuild build-for-testing \
  -project WildlifeAtlas/WildlifeAtlas.xcodeproj \
  -scheme WildlifeAtlas \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO
```

Run the tests:

```bash
xcodebuild test \
  -project WildlifeAtlas/WildlifeAtlas.xcodeproj \
  -scheme WildlifeAtlas \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Explore

Explore is the app's main screen. When opened for the first time, it loads the first page of the latest public observations.

Each card displays the available observation data:

- a photo preview;
- the common name;
- the scientific name;
- the observation date;
- the quality grade;
- the favorite status.

If some data is missing from the API response, the corresponding UI element is hidden. The app does not display placeholder values such as `Unknown`, `N/A`, or `-`, because these values could mislead users.

<p align="center">
  <img
    width="300"
    alt="Simulator Screenshot - iPhone 17 Pro"
    src="https://github.com/user-attachments/assets/a26128e2-896b-40dd-952e-cf5ed70476da"
  />
</p>

## List / Grid

Explore uses a single `UICollectionView` and a single data source. Switching display modes changes the layout and cell type without recreating the screen or reloading observations.

This is a deliberate design choice:

- loaded pages remain in memory;
- filters are preserved;
- pagination state is preserved;
- scroll context is preserved as naturally as the change in layout geometry allows;
- the ViewModel is not recreated.

List and grid modes use different cells because their content composition genuinely differs. However, they share the same presentation model to avoid duplicating domain data formatting.

<p align="center">
  <img width="300" alt="Simulator Screenshot - iPhone 17 Pro" src="https://github.com/user-attachments/assets/e2ebf898-e475-4832-89b8-b8d45ff8c539" />
</p>

## Pagination

Explore supports paginated loading. The next page is requested when the user approaches the end of the currently loaded list.

The main pagination rules are:

- page 1 displays a standard full-screen loading state;
- page 2 and subsequent pages do not replace the current feed with a loading screen;
- existing observations remain visible and interactive;
- concurrent duplicate requests for the next page are blocked;
- no further request is made when there is no next page;
- a next-page failure displays a compact retry option near the bottom of the list;
- new observations are appended to the end;
- duplicate observation IDs are not added again.

Within the ViewModel, pagination tracks:

- `currentPage`;
- `canLoadMore`;
- `isLoadingNextPage`;
- the pagination error.

Duplicate requests are prevented with logic such as:

```swift
guard canLoadMore, !isLoadingNextPage else {
    return
}
```

Generation tracking and stale-response protection also prevent an older request from overwriting state after the filters change.

<p align="center">
  <img width="300" alt="Simulator Screenshot - iPhone 17 Pro" src="https://github.com/user-attachments/assets/41e89327-b086-49d2-b819-5d2d64fbca8b" />
  <img width="300" alt="Simulator Screenshot - iPhone 17 Pro" src="https://github.com/user-attachments/assets/7666bc55-96ee-4fdc-8607-20726dffbbf7" />
</p>

## Taxon Search

Taxon search is integrated into Explore. Tapping the search field opens a panel with autocomplete results or recent taxa.

The implementation includes:

- the iNaturalist taxon autocomplete endpoint;
- input debouncing;
- cancellation of superseded search tasks;
- protection against stale responses;
- no network requests for empty or whitespace-only queries;
- recent taxa displayed when the query is empty;
- a maximum of 5 recent taxa;
- unique recent taxa;
- moving a recent taxon to the top when it is selected again.

`TaxonSearchViewModel` owns the search state. The ViewController only forwards user actions and renders that state. This keeps network requests, debouncing, and recent-taxa logic out of the UIKit code.

<p align="center">
  <img width="300" alt="Simulator Screenshot - iPhone 17 Pro" src="https://github.com/user-attachments/assets/7d5982a9-2ed6-4967-84b5-99cc1a34b7c3" />
  <img width="300" alt="Simulator Screenshot - iPhone 17 Pro" src="https://github.com/user-attachments/assets/94255c7b-cb76-46c8-9dd1-6b233c7c8478" />
</p>

## Filters

Explore supports three independent filters:

- Taxon: all observations or a selected taxon;
- Quality: any quality grade or research grade;
- Order: newest first or oldest first.

The filters are represented by a single value:

```swift
ObservationFilters
```

This matters because changing one filter must preserve the other two. For example, selecting a taxon and then changing the sort order must not reset the selected taxon.

Every filter change:

- cancels or invalidates the previous load;
- resets pagination;
- loads page 1;
- uses the complete current set of filters;
- does not mix new results with old ones.

<p align="center">
  <img width="300" alt="Simulator Screenshot - iPhone 17 Pro" src="https://github.com/user-attachments/assets/7406265c-c618-4bb4-b6a2-4c55479d945d" />
</p>

## Observation Detail

The detail screen is opened by observation ID:

```text
Explore / Favorites
→ selected observation ID
→ AppCoordinator
→ ObservationDetailViewModel(observationID:)
→ ObservationsRepository
→ GET observation by ID
```

The detail screen does not use the object from Explore as its source of truth. Even if the list already contains some of the data, the detail screen makes a separate request by ID. This adds a small network cost, but it meets the assignment requirements and ensures that the detail screen displays current, complete information.

When available, the screen displays:

- a photo or photo gallery;
- the common name;
- the scientific name;
- the quality grade;
- the observation date;
- taxon information;
- an approximate location;
- the author;
- photo attribution;
- the photo license.

Optional fields are hidden along with their corresponding rows or sections. The layout ensures that missing data does not leave empty spaces.

<p align="center">
  <img width="300" alt="Simulator Screenshot - iPhone 17 Pro" src="https://github.com/user-attachments/assets/06fe13e0-0b79-4675-8ef4-2626d7c956af" />
  <img width="300" alt="Simulator Screenshot - iPhone 17 Pro" src="https://github.com/user-attachments/assets/98a92043-8676-4ff3-a0f6-15f04564ead8" />
</p>

## Photo Gallery

If an observation has multiple available photos, the detail screen displays an embedded horizontal gallery.

The implementation includes:

- a `UICollectionView` within the detail screen;
- horizontal paging;
- image loading that is safe for cell reuse;
- a `UIPageControl`;
- a background behind the page indicator to keep its dots readable over photos;
- the same `ImageLoader` used by Explore.

The gallery is integrated into the detail screen rather than presented on a separate screen.

<p align="center">
  <img width="300" alt="Screenshot 2026-09-08 at 22 48 11" src="https://github.com/user-attachments/assets/4dc244e8-a8ff-451d-bc57-0da91d31248d" />
  <img width="300" alt="Screenshot 2026-09-08 at 22 48 24" src="https://github.com/user-attachments/assets/11a26e02-7ad4-4a44-9923-53f60d03d982" />
</p>

## Sharing

The detail screen supports sharing through `UIActivityViewController`.

The share payload contains only safe, public information:

- the observation name;
- the observation date, if available;
- the public observation URL, if available.

Exact coordinates and private location data are not used.

<p align="center">
  <img width="300" alt="Simulator Screenshot - iPhone 17 Pro" src="https://github.com/user-attachments/assets/857e81bf-ed9a-4b40-85bf-685aaa0dbcec" />
</p>

## Favorites

The app supports locally saved favorite observations:

- adding and removing favorites;
- a visible favorite status in Explore, Detail, and Favorites;
- a separate Favorites tab;
- an empty state;
- opening the detail screen by observation ID;
- persistence across app launches.

Storage is handled by `FavoritesStore`, with `UserDefaultsFavoritesStore` as its concrete implementation.

Only observation IDs are stored locally, rather than full observation snapshots.

Why store IDs:

- remote API data is not duplicated;
- there is no need to manage outdated names, photos, licenses, or attribution;
- Favorites retrieves current data when it loads;
- the storage model remains small and easy to understand.

To avoid making one request per row, Favorites loads observations in a batched request using the list of IDs. Favorites retain the locally stored ID order.

Stale-load protection is also implemented: if the favorites list changes while a network request is still in progress, the older result cannot overwrite the current state.

<p align="center">
  <img width="300" alt="Simulator Screenshot - iPhone 17 Pro" src="https://github.com/user-attachments/assets/9690d630-77b0-4d13-99ea-521e758ac182" />
</p>

## Image Loading

Images are loaded through a custom `RemoteImageLoader`:

- `URLSession`;
- `NSCache`;
- cancellation;
- in-flight request deduplication;
- status and error mapping;
- an injectable dependency.

UIKit uses `RemoteImageView`, which protects against cell-reuse races:

```text
the cell displays a fox
→ loading fox.jpg begins
→ the cell is reused for a bear
→ fox.jpg finishes loading later
→ the image is not applied because the represented URL has changed
```

A disk cache was deliberately omitted. The assignment requires a memory cache, while a disk cache would introduce separate storage, cleanup, and invalidation policies that would be disproportionate to the project's scope.

## Networking Details

The networking layer consists of:

- `APIClient`;
- `APIEndpoint`;
- `INaturalistEndpoint`;
- `APIError`;
- DTO models.

`APIClient` is responsible for:

- constructing `URLRequest` instances;
- the base URL;
- the HTTP method;
- headers;
- the User-Agent;
- executing requests through `URLSession`;
- checking HTTP status codes;
- JSON decoding;
- error mapping.

`INaturalistEndpoint` provides specific endpoint definitions for:

- the observation list;
- observation details;
- batched observations by ID;
- taxon autocomplete.

DTOs and domain models are kept separate:

```text
JSON
→ ObservationDTO / TaxonDTO / PhotoDTO
→ Domain models
→ ViewModel
→ Presentation model
→ UIKit
```

This flow prevents the external API structure from dictating the app's internal architecture.

## State Management

Screens that load remote data use explicit enum states:

```swift
case loading
case content
case empty
case error
```

The detail screen also has a `notFound` state, because a request for a specific ID may not return an observation.

Enum-based state was chosen instead of a set of independent Boolean fields because it makes contradictory states impossible, such as:

```text
isLoading = true
hasError = true
isEmpty = true
```

## Persistence

Local storage is isolated behind store protocols:

- `FavoritesStore`;
- `RecentTaxaStore`.

ViewModels do not access `UserDefaults` directly. This preserves the separation of responsibilities and allows ViewModels to be tested with mock stores.

`UserDefaults` is sufficient for the current amount of data:

- favorite IDs are a small array of integers;
- recent taxa contain at most 5 items;
- there are no complex relationships;
- Core Data is not needed.

## Testing Strategy

The project includes unit tests for the main behaviors and edge cases:

- URL and query construction;
- `captive=false`;
- parameters for the batched favorites endpoint;
- network success and status, transport, and decoding failures;
- DTO decoding and mapping;
- optional or missing API fields;
- location privacy;
- image caching;
- duplicate image download prevention;
- Explore's initial loading, content, empty, and error states;
- pagination accumulation;
- duplicate next-page request protection;
- final-page behavior;
- next-page failure and retry;
- duplicate observation ID handling;
- display mode switching without reloading;
- filter independence;
- pagination resets when filters change;
- stale filter response protection;
- taxon search debouncing;
- taxon search cancellation;
- stale autocomplete response protection;
- recent taxa ordering, uniqueness, and limits;
- favorites persistence;
- Favorites ViewModel states;
- stale favorites load protection;
- Detail's loading, content, notFound, error, and retry states;
- Detail's favorite status;
- missing optional detail fields;
- gallery photo presentation;
- share payload safety.

The tests check logic rather than exact UIKit constants. This is deliberate: dimensions, spacing, and visual density are better checked visually against reference screenshots, while unit tests for layout constants tend to be fragile and poor indicators of user-facing quality.
