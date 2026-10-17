# Domain model

## Directions

A `ConversionDirection` is either `ZimToMarkdown` or `MarkdownToZim`. The
constructor determines which parser reads the input and which extension is
used for output pages.

## Documents

A `ZimPage` is the immutable text of one page read from a Zim wiki notebook.
It still contains Zim markup and has not been interpreted. A
`MarkdownDocument` is the immutable text produced by a successful conversion
to Markdown.

## Notebook paths

A `RelativePath` is a path relative to the root of a notebook. It identifies a
page or asset independently of the notebook location on disk. `RelativePath`
derives `Ord` so it can be stored in a `Set` for link resolution.

## Link context

`LinkContext` records the current page and every known page in the notebook.
It allows the converter to resolve Zim link semantics:

- `[[page]]` searches the current namespace and then its parents.
- `[[:page]]` targets the notebook root.
- `[[+page]]` targets a child of the current page.

The resolved target is rendered relative to the current page and with the
output extension, so the generated Markdown links remain valid.

## Notebook items

A discovered file is classified as either a `PageItem` or an `AssetItem`.
Pages are converted. Assets are copied verbatim to preserve images and
attachments referenced by the pages.

## Requests and errors

A `ConversionRequest` records the input path, the optional output path, and the
direction. Command line failures are modeled by `OptionsError`. Input and
output failures are reported by `Main` as `Text` messages because they describe
effects at the boundary.
