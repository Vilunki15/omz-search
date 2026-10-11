# omz-search

An [Oh My Zsh](https://ohmyz.sh/) plugin that adds a `search` command. It finds a phrase in your source and text files and lists every match as `path:line:column`.

```console
$ search "search params"
Found 3 of "search params"
src/api/client.ts:14:9
src/components/Filter.tsx:42:17
src/components/Filter.tsx:57:5
```

The `path:line:column` format is clickable in VS Code's terminal and in most editors.

## Requirements

- zsh with Oh My Zsh
- `grep` and `awk`. The versions that ship with macOS and Linux both work.

## Installation

1. Clone the repository into the Oh My Zsh custom plugins folder:

   ```sh
   git clone https://github.com/Vilunki15/omz-search.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/search"
   ```

   The target folder must be named `search`, because Oh My Zsh loads `<folder>/<folder>.plugin.zsh`.

2. Add `search` to the plugin list in `~/.zshrc`:

   ```sh
   plugins=(git search)
   ```

3. Reload the shell:

   ```sh
   exec zsh
   ```

4. Check that it works:

   ```sh
   search -h
   ```

### Without Oh My Zsh

Source the file directly in `~/.zshrc`:

```sh
source /path/to/omz-search/search.plugin.zsh
```

### Updating

```sh
git -C "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/search" pull
exec zsh
```

### Uninstalling

Remove `search` from `plugins=(...)` in `~/.zshrc`, delete the plugin folder and run `exec zsh`.

## Usage

```
search [-i] [-t ext,ext,...] [-o checklist.md] "phrase" [directory]
```

| Argument / option | Description |
| --- | --- |
| `"phrase"` | Text to look for. It is matched literally, so `.`, `*`, `(` and other regex characters have no special meaning. Quote phrases that contain spaces. |
| `directory` | Where to search. Defaults to the current directory. Subdirectories are included. |
| `-i` | Ignore case. |
| `-t ext,ext` | Search only these file extensions for this run, for example `-t ts,tsx`. |
| `-o file.md` | Also write the matches to a Markdown checklist. See [Review checklist](#review-checklist). |
| `-h` | Show the usage line. |

Examples:

```sh
search "useState"                  # current directory, default file types
search -i "todo" src               # case-insensitive, only inside src/
search -t scss,css "primary-color"  # only stylesheets
search -- "-webkit-"               # phrase that starts with a dash
search -o legacy.md "OldButton"    # also save a review checklist
```

### Output

- The first line is always `Found N of "phrase"`, where N is the total number of occurrences.
- Each following line is one occurrence: `path:line:column`. Line and column numbers start at 1. A line containing the phrase twice is listed twice, with different columns.
- Paths are relative to the directory you searched.

### Review checklist

`-o file.md` writes the matches to a Markdown file as a task list, in addition to printing them. Use it to work through a list of places that need attention, such as every use of a legacy component you are replacing.

```console
$ search -o oldbutton-review.md "OldButton" src
Found 3 of "OldButton"
App.tsx:1:10
App.tsx:2:2
legacy/OldButton.tsx:1:14
Checklist saved to oldbutton-review.md
```

`oldbutton-review.md`:

```markdown
# Search: "OldButton"

- Directory: `/home/me/project/src`
- Date: 2026-10-11 19:46
- Found 3 of "OldButton"

- [ ] `App.tsx:1:10`
- [ ] `App.tsx:2:2`
- [ ] `legacy/OldButton.tsx:1:14`
```

Change `- [ ]` to `- [x]` as you check each item. GitHub and VS Code's Markdown preview render the list as checkboxes. The paths are relative to the directory listed in the header.

`search` refuses to overwrite an existing file (exit status 2), so a re-run cannot wipe out ticked items. Pick a new file name or delete the old checklist first.

### Exit status

| Code | Meaning |
| --- | --- |
| `0` | At least one match was found |
| `1` | No matches |
| `2` | Invalid arguments, directory not found, or the `-o` file already exists or cannot be written |

So it can be used in scripts: `search "console.log" src >/dev/null && echo "remove debug logs"`.

## Configuration

Two arrays control what gets searched. Define them in `~/.zshrc` to replace the defaults; they are read each time `search` runs, so placement in the file does not matter.

### `SEARCH_EXTENSIONS`

File extensions to search, without the leading dot. Default:

```
ts tsx js jsx mjs cjs vue svelte
css scss sass less html htm
json yml yaml toml xml ini
md mdx txt csv
sh bash zsh py rb php go rs java kt swift c h cpp hpp cs sql graphql
```

Example, front-end files only:

```sh
SEARCH_EXTENSIONS=(ts tsx scss css html)
```

The `-t` option overrides this list for a single run.

### `SEARCH_EXCLUDE_DIRS`

Directory names that are skipped wherever they appear. Default:

```
.git node_modules dist build out coverage .next .nuxt .cache vendor
```

Example, keep the defaults and also skip `tmp`:

```sh
SEARCH_EXCLUDE_DIRS=(.git node_modules dist build out coverage .next .nuxt .cache vendor tmp)
```

## How it works

1. `grep -rlIF` lists the files that contain the phrase. It matches literally (`-F`), skips binary files (`-I`) and applies the extension and directory filters.
2. `awk` reads only those files and reports every occurrence with its line and column number.
3. The plugin prints the total count, then the list, sorted by path.

The phrase reaches `awk` through an environment variable rather than `awk -v`, so backslashes in the phrase are not treated as escape sequences.

## Limitations

- A match cannot span multiple lines.
- Columns are counted in characters on GNU awk and in bytes on some other awk implementations. They differ only on lines containing non-ASCII text before the match.
- A checklist saved inside the searched directory contains the phrase, so later searches with the default extensions list it as a match. Save checklists outside the project or delete them when done.
- Line numbers in a checklist are not updated when you edit the files afterwards.
- `.gitignore` is not read. Use `SEARCH_EXCLUDE_DIRS` to skip generated folders.
