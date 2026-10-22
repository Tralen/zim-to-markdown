# Releasing

This guide follows the global release skill. It covers Hackage publication and the GitHub release with prebuilt binaries.

## Version source

The version is defined only in the `version:` field of `zim-to-markdown.cabal`. Cabal generates `Paths_zim_to_markdown`, and `ZimToMarkdown.Version` exposes it to the executable and tests. Update `CHANGELOG.md` before releasing.

The tag convention in use is an annotated tag named `v<version>`, for example `v0.3.0.1`.

## Pre-flight checks

Work from a clean tree and make sure local commits are pushed before tagging. Run:

```sh
cabal check
cabal build all
cabal test all
cabal haddock --haddock-for-hackage
cabal sdist
fourmolu --mode check src app test
hlint src app test
gitleaks git --redact --log-opts="--all"
```

Check that `dist-newstyle/sdist/` and `dist-newstyle/` contain the expected source and documentation tarballs.

## Candidate

Upload a candidate and inspect it before publishing:

```sh
cabal upload dist-newstyle/sdist/zim-to-markdown-*.tar.gz
```

Wait for explicit authorization before publishing. The candidate URL is printed by Cabal.

## Checksums

Generate and verify checksums for the exact candidate artifacts:

```sh
sha256sum dist-newstyle/sdist/zim-to-markdown-*.tar.gz dist-newstyle/zim-to-markdown-*-docs.tar.gz > dist-newstyle/SHA256SUMS
sha256sum -c dist-newstyle/SHA256SUMS
```

## Publish on Hackage

After the candidate is approved:

```sh
cabal upload --publish dist-newstyle/sdist/zim-to-markdown-*.tar.gz
cabal upload --publish --documentation dist-newstyle/zim-to-markdown-*-docs.tar.gz
```

## Tag and GitHub release

Create and push the annotated tag, then create the GitHub release:

```sh
git tag -a v<version> -m "zim-to-markdown <version>"
git push origin main
git push origin v<version>
gh release create v<version> --verify-tag --generate-notes
```

Sign the tag with `git tag -s` when a signing key is configured. Do not rewrite or force-push an existing release tag.

## Verification

Install the published package in a clean environment and run the main command:

```sh
cabal install zim-to-markdown
zim-to-markdown --version
```

For the library, build a temporary consumer project pinned to the published version.

## Prebuilt binaries

Run the `Release binaries` workflow manually with the release tag and `publish` enabled:

```sh
gh workflow run release-binaries.yml -f release_tag=v<version> -f publish=true
```

The workflow builds Linux x86_64, macOS ARM64, and Windows x86_64 archives, attaches them to the release, adds provenance attestations, and publishes a `SHA256SUMS` file. A run with `publish=false` only builds and tests the artifacts.

## CI

Push `main` before tagging so the CI matrix runs on Linux, macOS, and Windows, including GHC 9.6.7, GHC 9.14.1, HLint, Fourmolu, and Gitleaks.

## Rules

Never publish, rewrite history, force-push, or create a repository without explicit authorization. If a check is blocked, stop and report the exact action needed.
