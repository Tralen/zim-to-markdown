# Versioning

The project follows the Package Version Policy with four components:
`major.minor.patch.revision`. The current version is `0.1.0.0`.

## Source of truth

The version is stored in two places and they must stay in sync:

- `version:` in `zim-to-markdown.cabal`, used by Cabal.
- `appVersion` in `src/ZimToMarkdown/Version.hs`, used by the executable.

## Bump rules

| Change | Bump |
| --- | --- |
| Fixes and minor refinements | Patch |
| New user facing features or screens | Minor |
| Data model breaking changes | Major component 2 |
| Major release milestones | Major component 1 |

Every commit message starts with the application version and mentions the
version bump in its summary.
