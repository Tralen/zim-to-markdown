# Conversion rules

The conversion is line based for blocks and scanner based for inline markup. Rules that are not recognized are preserved as plain text.

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
| `<b>bold</b>` or `<strong>bold</strong>` | `**bold**` |
| `<i>italic</i>` or `<em>italic</em>` | `*italic*` |
| `{{id: name}}` | `<a id="name"></a>` |
| `* item` | `* item` |
| `1. item` or `a. item` | `1. item` |
| `[ ] task` | `- [ ] task` |
| `[*] task`, `[x] task`, `[>] task`, or `[<] task` | `- [x] task` |
| `[[page]]` | `[page](page.md)` |
| `[[page\|label]]` | `[label](page.md)` |
| `[[:page]]` | link to the notebook root |
| `[[+page]]` | link to a child of the current page |
| `[[https://example.com\|label]]` | `[label](https://example.com)` |
| `{{image.png}}` | `![image](image.png)` |
| `{{image.png\|alt text}}` | `![alt text](image.png)` |
| `'''` block delimiters | fenced code block |
| `-----` on its own line | `---` |
| Tab-indented block | `> blockquote` |
| `\| cell \| cell \|` pipe table | pipe table with an alignment row |

Zim heading levels one through five map to Markdown levels one through five. A pipe table without an alignment row receives a default alignment row.

## Markdown to Zim

| Markdown | Zim |
| --- | --- |
| `# Heading` through `##### Heading` | two through six `=` characters |
| `###### Heading` | clamped to Zim heading level five |
| Setext heading with `=` | Zim heading level one |
| Setext heading with `-` | Zim heading level two |
| `**bold**` or `__bold__` | `**bold**` |
| `*italic*` or `_italic_` | `//italic//` |
| `~~strike~~` | `~~strike~~` |
| `` `code` `` | `''code''` |
| `<u>underline</u>` or `<mark>marked</mark>` | `__underlined__` |
| `<sub>subscript</sub>` | `_{subscript}` |
| `<sup>superscript</sup>` | `^{superscript}` |
| `<strong>bold</strong>` or `<b>bold</b>` | `**bold**` |
| `<em>italic</em>` or `<i>italic</i>` | `//italic//` |
| `<a id="name"></a>` | `{{id: name}}` |
| `<https://example.com>` | `[[https://example.com]]` |
| `- item`, `* item`, or `+ item` | `* item` |
| `1. item` or `1) item` | `1. item` |
| `- [ ] task` | `[ ] task` |
| `- [x] task` | `[*] task` |
| `[label](page.md)` | `[[page\|label]]` |
| `[page](page.md)` | `[[page]]` |
| `![alt](image.png)` | `{{image.png\|alt}}` |
| fenced code block | `'''` block delimiters |
| `---`, `***`, or `___` on its own line | `-----` |
| `> quote` | tab-indented block |
| Pipe table with an alignment row | pipe table |

Internal Markdown link targets lose their page extension. Leading `./` and `../` segments are removed so Zim can resolve the link with its own upward search. Absolute Markdown links become root links such as `[[:page]]`. Inline markup inside link labels is converted recursively.

## Known limitations

- Reference links, footnotes, nested links, raw HTML blocks, and Markdown indented code blocks are not converted.
- Tables nested inside blockquotes or list items are not detected, and a Markdown table without body rows may not be recognized by Zim.
- Zim table objects stored in `{{{table: ...}}}` blocks are not read.
- Multiline list items are not joined.
- Code fence language hints are discarded.
- Markdown indentation is converted assuming two spaces per list level.
- A single page has no notebook index, so internal links can only resolve to a same-level target.
- Notebook metadata files and hidden files are not copied, and reverse conversion does not create a `notebook.zim` file.
- Existing destination files are overwritten without an additional prompt.
