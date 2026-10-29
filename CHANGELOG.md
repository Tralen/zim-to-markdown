# Changelog

All notable changes to this project are documented in this file. This project follows the Haskell Package Versioning Policy.

## [Unreleased]

## [0.3.0.4] - 2026-10-29

### Fixed

- Stripped Zim image display options such as `?width=512` from Markdown image targets.
- Copied images referenced outside the notebook with `~` or an absolute path into the output `assets` directory and rewrote the links relative to each page, so the images open in Markdown editors.

### Changed

- The converter exposes `convertZimPageWithAssets` so the executable can pass the collected image map, and `ZimToMarkdown.Zim` exports the image target scanner.

## [0.3.0.3] - 2026-10-23

### Changed

- Documented the planned domain smart constructors and the remaining conversion gaps in `docs/roadmap.md`.
- Added a test that fails when any link target in the README is relative, so the Hackage readme keeps working, and made `directory` a test dependency.
- Documented the installed executable in the README and CLI examples, keeping `cabal run` as the development form.
- Updated the cache, artifact, attestation, and Gitleaks actions to Node 24 releases.
- Documented the `libgmp-dev` build prerequisite on Debian and Ubuntu.

### Fixed

- Replaced the partial `maximum` call in table normalization with a total fold.
- Enabled `-Wincomplete-patterns` and `-Werror` in the shared build options, as `LANGUAGE.md` requires, and documented the single process failure boundary.
- Replaced the relative documentation links in the README with absolute GitHub URLs, because Hackage resolves relative links against the package URL and they return 404 on the package page. Recorded the rule in `LANGUAGE.md` and `docs/releasing.md`.
- Removed the stale "available after the first publication" note from the README.

## [0.3.0.2] - 2026-10-23

### Changed

- Adopted Fourmolu formatting with a pinned configuration.
- Added Fourmolu and Gitleaks checks to CI and pinned GitHub Actions by commit SHA.
- Added a dedicated release guide and made binary publication an explicit manual step.
- Added the HLint configuration and documented SSH tag signing, checksum basenames, and environment secret handling.
- Declared every compiler exercised by CI in `tested-with`.

### Fixed

- Removed partial `Text.head` calls from thematic break detection.

## [0.3.0.1] - 2026-10-21

### Fixed

- Removed leading Zim metadata headers such as `Content-Type`, `Wiki-Format`, `Creation-Date`, and `Modification-Date`.
- Normalized per-page heading levels into consecutive Markdown levels capped at `###`.
- Translated namespace colons in internal links, so `[[Sistema:cron]]` resolves to `Sistema/cron.md`.
- Rendered `user@host` pseudo-links as plain text instead of page links.
- Corrected the reported application version to `0.3.0.1`.

### Changed

- Added Hackage and GitHub package metadata, a changelog, and source repository information.
- Added prebuilt Linux, macOS, and Windows binaries to GitHub releases.

## [0.3.0.0] - 2026-10-20

### Added

- Pipe table conversion in both directions.
- Horizontal rules, blockquotes, setext headings, anchors, HTML inline tags, autolinks, image alt text, and additional task states.
- Recursive formatting inside link labels.
- Support for passing `notebook.zim` as an alternative notebook root.

### Changed

- Reflowed the README and documentation to avoid hard wrapped lines.
- Documented the supported conversion rules and known limitations.

## [0.2.0.0] - 2026-10-20

### Added

- Conversion of whole notebooks, preserving the folder structure.
- Asset copying and internal link resolution across notebooks.
- Markdown to Zim conversion.
- Initial formatting rules for headings, emphasis, lists, tasks, links, images, and code blocks.
- A dependency free test suite.

## [0.1.0.0] - 2026-10-20

### Added

- Initial Cabal project scaffold with a pure library and a thin executable.
- Command line parsing, domain types, versioning, and documentation.
