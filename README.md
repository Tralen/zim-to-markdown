# zim-to-markdown

Command line converter between Zim wiki pages and Markdown. It handles single pages and whole notebooks in both directions.

## Stack

Haskell with Cabal. Stack is not used.

## Versioning

PVP, single-sourced from the `zim-to-markdown.cabal` file.

- Patch: fixes and minor refinements.
- Minor: new user-facing features or screens.
- Major 2: data model breaking changes.
- Major 1: major release milestones.

## Features

- Converts a single page to standard output or to a file.
- Converts a whole notebook recursively, reconstructing its folder structure.
- Accepts the notebook directory or its `notebook.zim` configuration file as input.
- Strips the leading Zim metadata header and normalizes heading levels to `#`, `##`, and `###`.
- Copies notebook assets and external images referenced with `~`, so images and attachments keep working.
- Resolves internal Zim links across the notebook.
- Converts Markdown back to Zim, including notebook structure.
- Supports headings, emphasis, lists, task lists, links, images, anchors, tables, blockquotes, horizontal rules, and code blocks.
- Keeps conversion pure and reports failures as data.

## Links

- Hackage: <https://hackage.haskell.org/package/zim-to-markdown>
- GitHub: <https://github.com/Tralen/zim-to-markdown>

## Documentation

- [Architecture](https://github.com/Tralen/zim-to-markdown/blob/main/docs/architecture.md)
- [Domain model](https://github.com/Tralen/zim-to-markdown/blob/main/docs/domain.md)
- [Command line interface](https://github.com/Tralen/zim-to-markdown/blob/main/docs/cli.md)
- [Conversion rules](https://github.com/Tralen/zim-to-markdown/blob/main/docs/conversion.md)
- [Release guide](https://github.com/Tralen/zim-to-markdown/blob/main/docs/releasing.md)
- [Roadmap](https://github.com/Tralen/zim-to-markdown/blob/main/docs/roadmap.md)
- [Versioning](https://github.com/Tralen/zim-to-markdown/blob/main/docs/versioning.md)
- [Changelog](https://github.com/Tralen/zim-to-markdown/blob/main/CHANGELOG.md)

## Installation

Install the published package from Hackage with:

```sh
cabal install zim-to-markdown
```

The executable is installed into the Cabal binary directory, usually `~/.cabal/bin`, which must be on `PATH`.

## Prebuilt binaries

Prebuilt Linux, macOS, and Windows binaries are attached to [GitHub releases](https://github.com/Tralen/zim-to-markdown/releases/latest). The release workflow builds Linux x86_64 on Ubuntu 22.04 (glibc 2.35 or newer), macOS ARM64, and Windows x86_64 archives. Build from source for other Linux distributions.

## Requirements

Building from source or installing with `cabal install` requires:

- GHC 9.14.1
- cabal-install 3.18.1.0

On Debian and Ubuntu, install the `libgmp-dev` package before building, because GHC links against GMP.

The prebuilt binaries attached to the GitHub releases do not need a Haskell toolchain.

## Build and test

```sh
cabal build
cabal test
```

## Development

Run the formatter and linter with:

```sh
fourmolu --mode check src app test
hlint src app test
```

Install the pre-commit hook to scan staged changes for secrets:

```sh
pre-commit install
```

The hook requires `gitleaks` to be installed. The equivalent manual command is:

```sh
gitleaks git --staged --redact
```

## Usage

The examples use the installed `zim-to-markdown` executable. From a repository checkout, replace `zim-to-markdown` with `cabal run zim-to-markdown --`.

Convert a single Zim page to standard output:

```sh
zim-to-markdown page.txt
```

Convert a single page to a Markdown file:

```sh
zim-to-markdown page.txt --output page.md
```

Convert a whole Zim notebook, preserving its folders:

```sh
zim-to-markdown my-notebook --output my-notebook-markdown
```

The notebook directory or its `notebook.zim` file can be used as input:

```sh
zim-to-markdown my-notebook/notebook.zim --output my-notebook-markdown
```

Convert Markdown back to Zim:

```sh
zim-to-markdown --direction markdown-to-zim notes --output notes-zim
```

Run `zim-to-markdown --help` for the complete option list.

## Releasing

Follow the [release guide](https://github.com/Tralen/zim-to-markdown/blob/main/docs/releasing.md).

## Status

The converter covers headings, emphasis, lists, task lists, links, images, anchors, tables, blockquotes, horizontal rules, and code blocks. Reference links, footnotes, nested links, raw HTML blocks, and Markdown indented code blocks are not converted yet. See [conversion rules](https://github.com/Tralen/zim-to-markdown/blob/main/docs/conversion.md) for details and known limitations, and the [roadmap](https://github.com/Tralen/zim-to-markdown/blob/main/docs/roadmap.md) for the planned work.

## License

BSD-3-Clause. See [LICENSE](https://github.com/Tralen/zim-to-markdown/blob/main/LICENSE).
