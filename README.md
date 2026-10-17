# zim-to-markdown

Command line converter between Zim wiki pages and Markdown. It handles single
pages and whole notebooks in both directions.

## Features

- Converts a single page to standard output or to a file.
- Converts a whole notebook recursively, reconstructing its folder structure.
- Copies notebook assets so images and attachments keep working.
- Resolves internal Zim links across the notebook.
- Converts Markdown back to Zim, including notebook structure.
- Supports an initial set of formatting rules in both directions.
- Keeps conversion pure and reports failures as data.

## Documentation

- [Architecture](docs/architecture.md)
- [Domain model](docs/domain.md)
- [Command line interface](docs/cli.md)
- [Conversion rules](docs/conversion.md)
- [Versioning](docs/versioning.md)

## Requirements

- GHC 9.14.1
- cabal-install 3.18.1.0

## Build and test

```sh
cabal build
cabal test
```

## Usage

Convert a single Zim page to standard output:

```sh
cabal run zim-to-markdown -- page.txt
```

Convert a single page to a Markdown file:

```sh
cabal run zim-to-markdown -- page.txt --output page.md
```

Convert a whole Zim notebook, preserving its folders:

```sh
cabal run zim-to-markdown -- my-notebook --output my-notebook-markdown
```

Convert Markdown back to Zim:

```sh
cabal run zim-to-markdown -- --direction markdown-to-zim notes --output notes-zim
```

Run `cabal run zim-to-markdown -- --help` for the complete option list.

## Status

The converter covers headings, inline emphasis, lists, task lists, links,
images, and code blocks. Tables, blockquotes, footnotes, and other advanced
Markdown features are not converted yet. See
[conversion rules](docs/conversion.md) for details and known limitations.
