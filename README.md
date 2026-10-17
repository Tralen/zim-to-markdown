# zim-to-markdown

Command line converter from Zim wiki pages to Markdown.

## Documentation

- [Architecture](docs/architecture.md)
- [Domain model](docs/domain.md)
- [Command line interface](docs/cli.md)
- [Versioning](docs/versioning.md)

## Requirements

- GHC 9.14.1
- cabal-install 3.18.1.0

## Build and run

```sh
cabal build
cabal run zim-to-markdown -- --help
cabal run zim-to-markdown -- page.txt --output page.md
```

## Status

The project is a scaffold. The converter currently preserves the page content
unchanged; Zim markup rules will be added incrementally.
