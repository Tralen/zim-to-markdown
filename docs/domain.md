# Domain model

## Zim page

A `ZimPage` is the immutable text of one page read from a Zim wiki notebook.
It still contains Zim markup and has not been interpreted.

## Markdown document

A `MarkdownDocument` is the immutable text produced by a successful
conversion. It is ready to be written to disk or standard output.

## Conversion request

A `ConversionRequest` records the command line intention: one `InputPath` and
an optional `OutputPath`. When the output path is absent, the result goes to
standard output.

## Paths

`InputPath` and `OutputPath` are newtypes over `FilePath`. They prevent input
and output paths from being mixed accidentally.

## Errors

Command line failures are modeled by `OptionsError`. Input and output failures
are reported by `Main` as `Text` messages because they describe effects at the
boundary. Conversion itself currently cannot fail; if it gains failure cases,
they must be modeled as an algebraic data type and returned in `Either`.
