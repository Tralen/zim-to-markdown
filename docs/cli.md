# Command line interface

## Usage

```text
zim-to-markdown [--direction DIRECTION] [--output PATH] [--images MODE] [--formatting MODE] INPUT
zim-to-markdown --help
zim-to-markdown --version
```

The examples use the installed `zim-to-markdown` executable. From a repository checkout, replace `zim-to-markdown` with `cabal run zim-to-markdown --`.

## Options

| Option | Meaning |
| --- | --- |
| `-d DIRECTION`, `--direction DIRECTION` | `zim-to-markdown` (default) or `markdown-to-zim`. |
| `-o PATH`, `--output PATH` | Output file for a single page; output directory for a notebook. |
| `--images MODE` | External images: `copy` (default), `symlink` or `relative`; notebook conversion only. |
| `--formatting MODE` | Inline formatting without a Markdown counterpart: `html` (default), `bold`, `italic` or `strike`; Zim to Markdown only. |
| `-h`, `--help` | Show usage information. |
| `-V`, `--version` | Show the application version. |

## Single pages

When `INPUT` is a file, the result goes to standard output unless `--output` is given. In that case `PATH` must be a file path.

```sh
zim-to-markdown page.txt
zim-to-markdown page.txt --output page.md
zim-to-markdown --direction markdown-to-zim page.md --output page.txt
```

## Notebooks

When `INPUT` is a directory, it is treated as a notebook. A file named `notebook.zim` is also accepted; its parent directory becomes the notebook root. In both cases `--output` is required and the whole tree is converted recursively:

- Page files are converted to the target extension (`.txt` to `.md`, or `.md` and `.markdown` to `.txt`).
- Other files are copied unchanged, preserving their relative paths.
- Images referenced outside the notebook with `~` or an absolute path follow `--images`: `copy` stores them in `_assets/`, `symlink` stores absolute symbolic links in `_assets/`, and `relative` links to the originals with `..` segments. Links are written relative to each page; missing images keep the cleaned path, without the display options.
- The root `notebook.zim` file is treated as metadata and is not copied.
- Internal links are resolved using every page found in the notebook.
- Hidden files and symbolic links are skipped.
- Empty directories are not recreated.
- The output directory must not be inside the input directory.

`symlink` and `relative` require a notebook input. `markdown-to-zim` accepts only `copy`. The generated `_assets/` directory is reserved for external images; assets inside the notebook keep their own paths.

`symlink` needs symbolic-link support: on Windows it requires Developer Mode or Administrator privileges, and backup or archive tools may dereference or skip the links. These modes read the paths written in the notebook, so only convert notebooks from a trusted source; the output can copy files from outside the notebook and the symlinks reveal absolute paths.

`--formatting` controls Zim underline, subscript and superscript, which have no Markdown syntax. `html` keeps `<u>`, `<sub>` and `<sup>`; `bold`, `italic` and `strike` collapse them into `**`, `*` and `~~` emphasis. Anchors such as `{{id: name}}` stay HTML in every mode, and `markdown-to-zim` accepts only `html`.

```sh
zim-to-markdown my-notebook --output my-notebook-markdown
zim-to-markdown my-notebook/notebook.zim --output my-notebook-markdown
zim-to-markdown --direction markdown-to-zim notes --output notes-zim
```

## Walkthrough

The following example converts a notebook called `my-notebook` into Markdown under `my-notebook-markdown`.

1. Run the conversion:

   ```sh
   zim-to-markdown my-notebook --output my-notebook-markdown
   ```

2. The program reads `my-notebook`, finds every page and asset, and creates `my-notebook-markdown`. A page such as `my-notebook/notes/page.txt` becomes `my-notebook-markdown/notes/page.md`; other files are copied unchanged.
3. Internal links are rewritten to point at the converted pages, and images referenced outside the notebook are copied to `_assets/` by default.
4. The command prints nothing on success and exits with status `0`. On failure it prints a message to standard error and exits with a non-zero status.
5. The result is the `my-notebook-markdown` directory. Delete it to undo the conversion; the input notebook is not modified.

For a single page, omit `--output` to print the Markdown to standard output:

```sh
zim-to-markdown page.txt
```

## Exit status

The process exits with `0` on success and with a non-zero status when the arguments are invalid or when an input or output operation fails.
