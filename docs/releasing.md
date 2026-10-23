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

Check that `dist-newstyle/sdist/` and `dist-newstyle/` contain the expected source and documentation tarballs. Check that every link in `README.md` is absolute, because Hackage drops relative links when it renders the readme.

## Candidate

Upload a candidate and inspect it before publishing:

```sh
cabal upload dist-newstyle/sdist/zim-to-markdown-*.tar.gz
```

Wait for explicit authorization before publishing. The candidate URL is printed by Cabal.

## Checksums

Generate and verify checksums for the exact candidate artifacts. Use a staging directory so the `SHA256SUMS` file contains asset basenames, not repository paths:

```sh
mkdir -p dist-newstyle/checksums
cp dist-newstyle/sdist/zim-to-markdown-*.tar.gz dist-newstyle/zim-to-markdown-*-docs.tar.gz dist-newstyle/checksums/
cd dist-newstyle/checksums
sha256sum * > SHA256SUMS
sha256sum -c SHA256SUMS
```

The source tarball hash must match the registry tarball and any attached source archive.

## Publish on Hackage

After the candidate is approved:

```sh
cabal upload --publish dist-newstyle/sdist/zim-to-markdown-*.tar.gz
cabal upload --publish --documentation dist-newstyle/zim-to-markdown-*-docs.tar.gz
```

## Tag and GitHub release

Create, verify, and push the signed tag, then create the GitHub release:

```sh
git tag -s v<version> -m "zim-to-markdown <version>"
git tag -v v<version>
git push origin main
git push origin v<version>
gh release create v<version> --verify-tag --generate-notes
```

Do not rewrite or force-push an existing release tag. The existing `v0.3.0.1` tag predates the signing configuration and remains unsigned; sign the next tag.

### Tag signing

The repository uses SSH signing in the current setup. Configure it with:

```sh
git config gpg.format ssh
git config user.signingkey <path-to-public-key>
git config gpg.ssh.allowedSignersFile <path-to-allowed-signers>
git config tag.gpgSign true
```

Add the same public key to GitHub as a signing key and add the signer e-mail to the allowed signers file. For OpenPGP, use the long key ID as `user.signingkey` instead.

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

## Environment and secrets

The `release` environment exists and is used by the `Release binaries` workflow. If a registry upload is added to a workflow, store its token as an environment secret and map it to the environment variable read by the upload command. Do not use Actions variables for tokens. Hackage publication is currently performed locally with `HACKAGE_TOKEN` in the environment.

## Rules

Never publish, rewrite history, force-push, or create a repository without explicit authorization. If a check is blocked, stop and report the exact action needed.
