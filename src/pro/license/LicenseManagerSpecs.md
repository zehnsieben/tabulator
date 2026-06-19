# LicenseManager — Specs

## Summary

`LicenseManager` is now a compatibility boundary for the license-free build. It preserves the public API that existing UI and tests compile against, but it never contacts a remote licensing backend and always reports Pro availability.

## Behavior

- `initialize()` sets `state` to `.pro`.
- `refreshState()` keeps `state` at `.pro`.
- `isProAvailable` is true.
- `isProLocked` is false.
- Expired trial defaults and invalid cached validation data do not lock features.
- `activate(_:)`, `deactivate`, `deactivateInstance`, `scheduleAsyncRevalidationIfNeeded`, and `revalidateWithServer` are local no-ops from a networking perspective.
- `deactivate` may clear legacy local keychain/defaults data, but it does not change feature availability.

## Test scenarios

- **testInitializeAlwaysMakesProAvailableWithoutNetwork** — launch resolves to `.pro`; no activate/validate/deactivate API calls are made.
- **testExpiredTrialDataIsIgnored** — old trial defaults do not lock features.
- **testInvalidCachedLicenseDataIsIgnored** — invalid cached license data does not lock features.
- **testActivateIsLocalAndDoesNotCallApi** — activation completes locally and does not call the API.
- **testDeactivateKeepsFeaturesAvailableAndDoesNotCallApi** — deactivation clears legacy local records but keeps `.pro` and does not call the API.
- **testRevalidationIsNoop** — revalidation does not call the API and leaves `.pro` intact.
