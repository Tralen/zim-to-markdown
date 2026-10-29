# Architecture

The project is split into a pure library and a thin executable. All effects live in `app/Main.hs`; the library only transforms immutable values.

## Modules

| Module | Responsibility |
| --- | --- |
| `ZimToMarkdown.Domain` | Core types: directions, documents, and relative paths. |
| `ZimToMarkdown.Zim` | Pure Zim to Markdown block and inline conversion. |
| `ZimToMarkdown.Markdown` | Pure Markdown to Zim block and inline conversion. |
| `ZimToMarkdown.Converter` | Direction specific entry points used by the executable. |
| `ZimToMarkdown.Links` | Pure resolution of internal Zim links using notebook context. |
| `ZimToMarkdown.Inline` | Shared inline scanning helpers. |
| `ZimToMarkdown.Table` | Shared pipe table detection and normalization. |
| `ZimToMarkdown.Notebook` | Pure classification of notebook files and destination paths. |
| `ZimToMarkdown.Paths` | Pure relative path calculation. |
| `ZimToMarkdown.Options` | Pure command line parsing and user facing messages. |
| `ZimToMarkdown.Version` | Application version sourced from the Cabal package metadata. |
| `Main` | Effect boundary: filesystem discovery, reading, writing, and exit codes. |

## Data flow

```text
argv -> parseOptions -> ConversionRequest
                              |
                              v
discoverFiles -> classifyNotebookItems -> pages and assets
                              |
                              v
file bytes -> decodeUtf8' -> ZimPage or MarkdownDocument
                              |
                              v
convertZimPage or convertMarkdownDocument
                              |
                              v
encodeUtf8 -> stdout or output file
```

## Purity boundary

Parsing, conversion, link resolution, path calculation, table normalization, and notebook classification are pure functions. Reading, writing, directory discovery, asset copying, and exiting are confined to `Main`, which turns failures into `Text` messages and a non-zero exit code instead of throwing exceptions.

## Notebook behavior

For a notebook, the executable discovers every file and classifies it as a page or an asset. The input can be the notebook directory or its `notebook.zim` file; the definition file itself is never copied. Pages are converted to the target extension and assets are copied unchanged. Images that pages reference outside the notebook with `~` or an absolute path are copied into an `assets` directory in the output and the links are rewritten relative to each page; missing images are left as written. Internal links are resolved against the set of discovered pages, so links keep pointing to the converted pages. Hidden files, symbolic links, and empty directories are skipped.

## Evolution

New markup rules belong in `ZimToMarkdown.Zim` or `ZimToMarkdown.Markdown`. Shared syntax helpers belong in `ZimToMarkdown.Inline` and `ZimToMarkdown.Table`. Path and link behavior must remain pure and free of filesystem access.
