# Command line interface

## Usage

```text
zim-to-markdown [--output FILE] INPUT
zim-to-markdown --help
zim-to-markdown --version
```

## Options

| Option | Meaning |
| --- | --- |
| `-o FILE`, `--output FILE` | Write the Markdown document to `FILE`. Defaults to standard output. |
| `-h`, `--help` | Show usage information. |
| `-V`, `--version` | Show the application version. |

## Examples

```sh
# Print the converted page to standard output.
cabal run zim-to-markdown -- page.txt

# Write the converted page to a file.
cabal run zim-to-markdown -- page.txt --output page.md
```

## Exit status

The process exits with `0` on success and with a non-zero status when the
arguments are invalid or when an input or output operation fails.
