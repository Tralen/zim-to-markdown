# Versioning

The project follows the Package Version Policy with four components: `major.minor.patch.revision`. The current version is `0.3.1.0`.

## Source of truth

The version is defined only in the `version:` field of `zim-to-markdown.cabal`. Cabal generates `Paths_zim_to_markdown`, and `ZimToMarkdown.Version` exposes that value to the executable and the test suite. There is no separate version constant to keep in sync.

## Bump rules

| Change | Bump |
| --- | --- |
| Fixes and minor refinements | Patch |
| New user facing features or screens | Minor |
| Data model breaking changes | Major component 2 |
| Major release milestones | Major component 1 |

Every commit message starts with the application version and mentions the version bump in its summary.
