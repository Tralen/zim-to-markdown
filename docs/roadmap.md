# Roadmap

Planned work that is not part of the current release. An item ships when its prerequisites are clear and the tests cover the new behavior.

## Domain smart constructors

`ZimToMarkdown.Domain` exports the constructors of `ZimPage`, `MarkdownDocument` and `RelativePath`, so code outside the module can build a `RelativePath` that holds an absolute path. The planned change exports the types without their constructors, adds smart constructors such as `mkRelativePath :: FilePath -> Either DomainError RelativePath`, and threads the results through the executable, the link resolver and the tests. It changes the public API, so it ships in a minor release.

## Remaining conversion gaps

Reference links, footnotes, nested links, raw HTML blocks, and Markdown indented code blocks are still not converted. The [conversion rules](conversion.md) describe the supported syntax and the current behavior for each gap.
