# Command line interface

## Usage

```text
zim-to-markdown [--direction DIRECTION] [--output PATH] INPUT
zim-to-markdown --help
zim-to-markdown --version
```

## Options

| Option | Meaning |
| --- | --- |
| `-d DIRECTION`, `--direction DIRECTION` | `zim-to-markdown` (default) or `markdown-to-zim`. |
| `-o PATH`, `--output PATH` | Output file for a single page; output directory for a notebook. |
| `-h`, `--help` | Show usage information. |
| `-V`, `--version` | Show the application version. |

## Single pages

When `INPUT` is a file, the result goes to standard output unless `--output`
is given. In that case `PATH` must be a file path.

```sh
cabal run zim-to-markdown -- page.txt
cabal run zim-to-markdown -- page.txt --output page.md
cabal run zim-to-markdown -- --direction markdown-to-zim page.md --output page.txt
```

## Notebooks

When `INPUT` is a directory, it is treated as a notebook and `--output` is
required. The whole tree is converted recursively:

- Page files are converted to the target extension (`.txt` to `.md`, or
  `.md` and `.markdown` to `.txt`).
- Other files are copied unchanged, preserving their relative paths.
- Internal links are resolved using every page found in the notebook.
- Hidden files and symbolic links are skipped.
- Empty directories are not recreated.
- The output directory must not be inside the input directory.

```sh
cabal run zim-to-markdown -- my-notebook --output my-notebook-markdown
cabal run zim-to-markdown -- --direction markdown-to-zim notes --output notes-zim
```

## Exit status

The process exits with `0` on success and with a non-zero status when the
arguments are invalid or when an input or output operation fails.
