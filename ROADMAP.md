# Project Roadmap

This roadmap assumes the UI pass is mostly complete and backend API work will be done last.

## Phase 1: App Foundation
- [x] Finalize app-wide state management with Riverpod.
- Standardize navigation and screen flow.
- Set up shared loading, empty, error, and retry states.
- Review reusable widgets and remove duplicated UI patterns.

## Phase 2: Theme and Visual Consistency
- Finish dark mode support across all screens.
- Verify colors, text styles, icons, and surfaces in both themes.
- Check contrast and readability on small and large screens.
- Align the design system across shared components.

## Phase 3: Core Features Without API+
- [x] Build Google Maps screens and flows with mock data.
- [x] Add push notification UI and local notification handling.
- [x] Add offline caching and local persistence for key app data.
- Make sure features work cleanly without backend dependency.

## Phase 4: Quality and Validation
- Add tests for the most important user flows.
- Verify responsive behavior on different device sizes.
- Review performance, app startup, and navigation stability.
- Fix remaining UI and state bugs.

## Phase 5: Backend Integration Last
- Connect all screens to the real API.
- Replace mock data with live responses.
- Add sync, refresh, and API error handling.
- Validate authentication and data consistency.

## Phase 6: Release Prep
- Run full QA on Android and iOS.
- Verify permissions for maps, notifications, and storage.
- Prepare release configuration, assets, and final build checks.

## Immediate Next Steps
- [x] Pick the state management structure for the app.
- [x] Finish dark mode support in shared theme files.
- [x] Standardize primary tab navigation with named routes.
- [x] Start notifications layer with Riverpod mock data and local cache bootstrap.
- [x] Start maps flow with mock data and integrate it into report/location screens.
- [x] Add offline caching for key app data (notifications + reports) with local persistence.
- Verify clean behavior in offline mode across core user flows.
- Add tests for high-priority Riverpod providers and report submission flow.