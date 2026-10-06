# Changelog

All notable changes to this project are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

### Changed

### Fixed

## [0.1.0] - 2026-10-06

### Added

- Project scaffolding: OpenSpec (repo-local), Beans board, `AGENTS.md` with
  `CLAUDE.md` as a symlink, `scripts/ship-change.sh`, and a `nix flake check`
  gate that evaluates the module against a fixture and checks formatting.
- Initial release of the `nivis-aws-amplify-site` nivis module: Amplify app,
  production branch, custom-domain association with subdomains, build service
  role, redirect rules (`preRules`, `redirects`) and an optional same-origin
  form proxy.
