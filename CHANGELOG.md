# Changelog

## [0.8.0](https://github.com/mkappworks-dev/code-bench-app/compare/v0.7.2...v0.8.0) (2026-05-05)


### Features

* **github:** revocation-aware disconnect, app installations, refined Create PR flow ([#79](https://github.com/mkappworks-dev/code-bench-app/issues/79)) ([89ba2c6](https://github.com/mkappworks-dev/code-bench-app/commit/89ba2c6efac438d6a159cd6dca20c669fb730793))

## [0.7.2](https://github.com/mkappworks-dev/code-bench-app/compare/v0.7.1...v0.7.2) (2026-05-04)


### Bug Fixes

* **onboarding:** sign out GitHub on wipe + align button heights across all steps ([#77](https://github.com/mkappworks-dev/code-bench-app/issues/77)) ([e496c62](https://github.com/mkappworks-dev/code-bench-app/commit/e496c6257ed171ad1e928613d98cf2b2bf88a74a))

## [0.7.1](https://github.com/mkappworks-dev/code-bench-app/compare/v0.7.0...v0.7.1) (2026-05-04)


### Bug Fixes

* **update:** use open -n to force new app instance on relaunch ([#75](https://github.com/mkappworks-dev/code-bench-app/issues/75)) ([bd4e5c0](https://github.com/mkappworks-dev/code-bench-app/commit/bd4e5c00450bfc46d0302bd62537a813dd9521d1))

## [0.7.0](https://github.com/mkappworks-dev/code-bench-app/compare/v0.6.1...v0.7.0) (2026-05-04)


### Features

* **providers:** redesign provider & onboarding UI with collapsible cards ([#67](https://github.com/mkappworks-dev/code-bench-app/issues/67)) ([d1c9d4e](https://github.com/mkappworks-dev/code-bench-app/commit/d1c9d4e0634af7c726b4916b15fddde8cbb370d7))

## [0.6.1](https://github.com/mkappworks-dev/code-bench-app/compare/v0.6.0...v0.6.1) (2026-05-04)


### Bug Fixes

* **release:** chain release.yml from release-please.yml to publish ([#69](https://github.com/mkappworks-dev/code-bench-app/issues/69)) ([5725934](https://github.com/mkappworks-dev/code-bench-app/commit/572593465aa44ad79f355a98aeeb8803b4bf8def))

## [0.6.0](https://github.com/mkappworks-dev/code-bench-app/compare/v0.5.0...v0.6.0) (2026-05-04)


### Features

* **update:** add Ready to Restart deferred-restart flow ([#66](https://github.com/mkappworks-dev/code-bench-app/issues/66)) ([5f8394c](https://github.com/mkappworks-dev/code-bench-app/commit/5f8394c6094f279d3b538b8bd6e9447b3aec0597))


### Bug Fixes

* **release:** publish release only after artifacts are uploaded ([#64](https://github.com/mkappworks-dev/code-bench-app/issues/64)) ([353d2e2](https://github.com/mkappworks-dev/code-bench-app/commit/353d2e202bc1fe2a3c29905f487d6a7d2a2c748f))

## [0.5.0](https://github.com/mkappworks-dev/code-bench-app/compare/v0.4.2...v0.5.0) (2026-05-03)


### Features

* **github-auth:** replace GitHub auth with Device Flow on GitHub App ([#62](https://github.com/mkappworks-dev/code-bench-app/issues/62)) ([211126b](https://github.com/mkappworks-dev/code-bench-app/commit/211126befabccb413ed36bddb30e7e16036e0c75))

## [0.4.2](https://github.com/mkappworks-dev/code-bench-app/compare/v0.4.1...v0.4.2) (2026-05-02)


### Bug Fixes

* **update:** allow in-bundle symlinks during update install ([#59](https://github.com/mkappworks-dev/code-bench-app/issues/59)) ([31feaca](https://github.com/mkappworks-dev/code-bench-app/commit/31feaca03df30a677997628954f99617b33d279d))

## [0.4.1](https://github.com/mkappworks-dev/code-bench-app/compare/v0.4.0...v0.4.1) (2026-05-02)


### Bug Fixes

* **2026-05-02:** install Developer ID provisioning profile in CI ([#55](https://github.com/mkappworks-dev/code-bench-app/issues/55)) ([6a18ef8](https://github.com/mkappworks-dev/code-bench-app/commit/6a18ef844bc2c8376c50bfa3b97404edc6f01449))
* **2026-05-02:** resolve claude/codex CLI via login shell for release ([#51](https://github.com/mkappworks-dev/code-bench-app/issues/51)) ([f782d6d](https://github.com/mkappworks-dev/code-bench-app/commit/f782d6dab04980882410598dc003acc4a3171ac7))
* **2026-05-02:** use TeamIdentifierPrefix in Release keychain-access-groups ([#53](https://github.com/mkappworks-dev/code-bench-app/issues/53)) ([5925842](https://github.com/mkappworks-dev/code-bench-app/commit/5925842df00f66eb0405d69b21839a4ac89ccd4b))
* **2026-05-03:** strip pod code signing and revert version to 0.4.0 ([#57](https://github.com/mkappworks-dev/code-bench-app/issues/57)) ([b42c191](https://github.com/mkappworks-dev/code-bench-app/commit/b42c191962e162090dc1ebebbbef63c6d71eb2e4))

## [0.4.0](https://github.com/mkappworks-dev/code-bench-app/compare/v0.3.0...v0.4.0) (2026-05-02)


### Features

* **update:** show UpdateChip in settings sidebar ([#49](https://github.com/mkappworks-dev/code-bench-app/issues/49)) ([877b7b1](https://github.com/mkappworks-dev/code-bench-app/commit/877b7b1b8b52a3fead5beb24af6e90768475a39a))


### Bug Fixes

* **update:** package macOS release zip with ditto, not plain zip ([#48](https://github.com/mkappworks-dev/code-bench-app/issues/48)) ([e4864b4](https://github.com/mkappworks-dev/code-bench-app/commit/e4864b40055c3bd2fb761d9e5b163b7301147ad1))

## [0.3.0](https://github.com/mkappworks-dev/code-bench-app/compare/v0.2.1...v0.3.0) (2026-05-02)


### Features

* **provider:** add multi-provider SDK inference transport with unified provider UI ([#34](https://github.com/mkappworks-dev/code-bench-app/issues/34)) ([73ed491](https://github.com/mkappworks-dev/code-bench-app/commit/73ed491681f2f5813f4286280ec4c17b07b4cc20))


### Bug Fixes

* **2026-05-02:** bump feat as minor in 0.x release-please runs ([#47](https://github.com/mkappworks-dev/code-bench-app/issues/47)) ([4612abd](https://github.com/mkappworks-dev/code-bench-app/commit/4612abd8c35903287d3e8ad7c7b49a63ad2f1e31))

## [0.2.1](https://github.com/mkappworks-dev/code-bench-app/compare/v0.2.0...v0.2.1) (2026-05-02)


### Bug Fixes

* **2026-05-02:** allow api.github.com for update metadata fetch ([#44](https://github.com/mkappworks-dev/code-bench-app/issues/44)) ([b9b88ee](https://github.com/mkappworks-dev/code-bench-app/commit/b9b88ee27762e6233f958ab00f72834e912875e2))

## [0.2.0](https://github.com/mkappworks-dev/code-bench-app/compare/v0.1.0...v0.2.0) (2026-05-02)


### Continuous Integration

* **2026-05-02:** enforce conventional commits and trigger v0.2.0 ([#41](https://github.com/mkappworks-dev/code-bench-app/issues/41)) ([25320c2](https://github.com/mkappworks-dev/code-bench-app/commit/25320c262340900b52836cf2c8f1112f6de65dd0))
