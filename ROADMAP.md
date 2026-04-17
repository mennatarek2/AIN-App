# Project Roadmap

This roadmap assumes the UI pass is mostly complete and backend API work will be done last.

## Phase 1: App Foundation
- [x] Finalize app-wide state management with Riverpod.
- [x] Standardize navigation and screen flow.
- Set up shared loading, empty, error, and retry states.
- Review reusable widgets and remove duplicated UI patterns.

## Phase 2: Theme and Visual Consistency
- Finish dark mode support across all screens.
- Verify colors, text styles, icons, and surfaces in both themes.
- Check contrast and readability on small and large screens.
- Align the design system across shared components.

## Phase 3: Core Features Without API
- [x] Build Google Maps screens and flows with mock data.
- [x] Add push notification UI and local notification handling.
- [x] Add offline caching and local persistence for key app data.
- [x] Make sure features work cleanly without backend dependency.

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

Status note: local-first sync architecture is in place (repository abstraction + connectivity-triggered sync), while real API integration is pending.

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
- [x] Persist authenticated user session locally and hydrate it on startup.
- [x] Cache last known user location and use fallback when GPS is unavailable.
- [x] Implement offline to online report sync path with retry on reconnect.
- [x] Replace key report/profile image rendering with cached image handling.
- Verify clean behavior in offline mode across core user flows (auth, report submit, report sync, location, image cache).
- Add tests for high-priority Riverpod providers and offline report submission/sync flow.

## Offline Manual QA Checklist (Phase 4)
- [ ] Session hydration: login once, close app, relaunch without internet, confirm user remains authenticated and lands in app flow without re-login. (manual device validation)
- [x] Auth persistence integrity: verify cached user fields (id, name, email, token, profile image) are available after restart. (automated test)
- [x] Report submit offline: disable internet, create report, confirm report appears immediately with unsynced state. (automated test)
- [ ] Report persistence after restart: while still offline, restart app and confirm the unsynced report is still present. (manual device validation)
- [x] Offline to online sync: restore internet, wait for reconnect listener, confirm unsynced report transitions to synced. (automated test)
- [x] Sync retry behavior: simulate intermittent connectivity during sync and confirm failed sync retries on next reconnect. (automated test)
- [ ] Location fallback: deny GPS or make location unavailable, confirm app uses cached last known location. (manual device validation)
- [ ] Location cache refresh: enable GPS and move/update location, confirm cached location updates with latest coordinates/address. (manual device validation)
- [ ] Cached network image offline display: load report/profile images online once, go offline, confirm previously loaded images still display. (manual device validation)
- [ ] Notifications + offline cache coexistence: verify local notifications and cached notification list remain stable across offline/online transitions. (manual device validation)

Exit criteria for Phase 4 offline validation:
- [ ] All checklist items pass on Android test device.
- [ ] No blocker/critical regressions in report flow, auth flow, or location flow.
- [ ] Defects are documented and mapped to fixes before backend rollout.

Automated execution log (2026-04-17):
- Passed: test/features/auth/data/user_local_data_source_test.dart
- Passed: test/features/reports/data/report_repository_impl_test.dart