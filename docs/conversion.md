# Conversion rules

The conversion is line based for blocks and scanner based for inline markup.
Rules that are not recognized are preserved as plain text.

## Zim to Markdown

| Zim | Markdown |
| --- | --- |
| `====== Heading ======` | `# Heading` |
| `===== Heading =====` | `## Heading` |
| `== Heading ==` | `##### Heading` |
| `**bold**` | `**bold**` |
| `//italic//` | `*italic*` |
| `__underline__` | `<u>underline</u>` |
| `''verbatim''` | `` `verbatim` `` |
| `~~strike~~` | `~~strike~~` |
| `_{subscript}` | `<sub>subscript</sub>` |
| `^{superscript}` | `<sup>superscript</sup>` |
| `* item` | `* item` |
| `1. item` or `a. item` | `1. item` |
| `[ ] task` | `- [ ] task` |
| `[*] task` or `[x] task` | `- [x] task` |
| `[[page]]` | `[page](page.md)` |
| `[[page|label]]` | `[label](page.md)` |
| `[[:page]]` | link to the notebook root |
| `[[+page]]` | link to a child of the current page |
| `[[https://example.com|label]]` | `[label](https://example.com)` |
| `{{image.png}}` | `![image](image.png)` |
| `'''` block delimiters | fenced code block |

Zim heading levels one through five map to Markdown levels one through five.

## Markdown to Zim

| Markdown | Zim |
| --- | --- |
| `# Heading` through `##### Heading` | two through six `=` characters |
| `###### Heading` | clamped to Zim heading level five |
| `**bold**` or `__bold__` | `**bold**` |
| `*italic*` or `_italic_` | `//italic//` |
| `~~strike~~` | `~~strike~~` |
| `` `code` `` | `''code''` |
| `<u>underline</u>` | `__underline__` |
| `<sub>subscript</sub>` | `_{subscript}` |
| `<sup>superscript</sup>` | `^{superscript}` |
| `- item`, `* item`, or `+ item` | `* item` |
| `1. item` or `1) item` | `1. item` |
| `- [ ] task` | `[ ] task` |
| `- [x] task` | `[*] task` |
| `[label](page.md)` | `[[page|label]]` |
| `[page](page.md)` | `[[page]]` |
| `![alt](image.png)` | `{{image.png}}` |
| fenced code block | `'''` block delimiters |

Internal Markdown link targets lose their page extension. Leading `./` and
`../` segments are removed so Zim can resolve the link with its own upward
search. Absolute Markdown links become root links such as `[[:page]]`.

## Known limitations

- Markdown indentation is converted assuming two spaces per list level.
- Code fence language hints are discarded.
- Tables, blockquotes, horizontal rules, footnotes, reference links, and raw
  HTML blocks are not converted.
- Text inside link labels is not recursively parsed.
- When converting a single page, internal links can only resolve to a
  same-level target because no notebook index is available.
- Notebook metadata files and hidden files are not copied.
- Existing destination files are overwritten without an additional prompt.
