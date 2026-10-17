# Architecture

The project is split into a pure library and a thin executable. All effects
live in `app/Main.hs`; the library only transforms immutable values.

## Modules

| Module | Responsibility |
| --- | --- |
| `ZimToMarkdown.Domain` | Domain types: `ZimPage` and `MarkdownDocument`. |
| `ZimToMarkdown.Converter` | Pure conversion from `ZimPage` to `MarkdownDocument`. |
| `ZimToMarkdown.Options` | Pure command line parsing and user facing messages. |
| `ZimToMarkdown.Version` | Application version and its rendering. |
| `Main` | Effect boundary: reads arguments and files, writes output, sets the exit code. |

## Data flow

```text
argv -> parseOptions -> ConversionRequest
                              |
                              v
file bytes -> decodeUtf8' -> ZimPage -> convertPage -> MarkdownDocument
                              |
                              v
                encodeUtf8 -> stdout or output file
```

## Purity boundary

Parsing, conversion, and rendering are pure functions. Reading, writing, and
exiting are confined to `Main`, which turns failures into `Text` messages and
a non-zero exit code instead of throwing exceptions.

## Evolution

New Zim markup rules belong in `ZimToMarkdown.Converter`. New command line
options belong in `ZimToMarkdown.Options`. Shared behavior should be extracted
into a reusable module rather than duplicated between call sites.
