# omz-search

> **TL;DR** `search` is an [Oh My Zsh](https://ohmyz.sh/) plugin that finds a phrase in your source files and lists every match as a clickable `path:line:column`. Add `-o review.md` and you also get a Markdown checklist for working through the matches one by one.

```console
$ search "search params"
Found 3 of "search params"
src/api/client.ts:14:9
src/components/Filter.tsx:42:17
src/components/Filter.tsx:57:5
```

---

## Installation

You need zsh, [Oh My Zsh](https://ohmyz.sh/), `grep` and `awk`. The `grep` and `awk` that ship with Linux and macOS both work.

1. Clone the plugin into the Oh My Zsh custom plugins folder. The folder must be named `search`.

   ```sh
   git clone https://github.com/Vilunki15/omz-search.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/search"
   ```

2. Add `search` to the plugin list in `~/.zshrc`:

   ```sh
   plugins=(git search)
   ```

3. Reload the shell and check that it works:

   ```sh
   exec zsh
   search -h
   ```

**Without Oh My Zsh:** add `source /path/to/omz-search/search.plugin.zsh` to `~/.zshrc`.

**Update:** `git -C "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/search" pull && exec zsh`

---

## Documentation

### Usage

```
search [-i] [-t ext,ext,...] [-o checklist.md] "phrase" [directory]
```

| Argument / flag | What it does |
| --- | --- |
| `"phrase"` | Text to find. Matched literally, so `.`, `*` and `(` are ordinary characters. Quote phrases with spaces. |
| `directory` | Where to search, subdirectories included. Defaults to the current directory. |
| `-i` | Ignore case. |
| `-t ext,ext` | Search only these file extensions on this run, e.g. `-t ts,tsx`. |
| `-o file.md` | Also save the matches as a Markdown checklist. |
| `-h` | Show the usage line. |

### Examples

```sh
search "useState"                   # current directory, default file types
search -i "todo" src                # case-insensitive, only inside src/
search -t scss,css "primary-color"  # stylesheets only
search -- "-webkit-"                # phrase that starts with a dash
search -o legacy.md "OldButton"     # also save a review checklist
```

### Output

- The first line is always `Found N of "phrase"`, where N counts every occurrence.
- Each following line is one occurrence as `path:line:column`, counted from 1. Two matches on one line are listed separately.
- Paths are relative to your current directory (`search foo src` prints `src/...`), so they stay clickable in the terminal. They are sorted by path.

### Review checklist

`search -o oldbutton-review.md "OldButton" src` prints the matches as usual and writes this file:

```markdown
# Search: "OldButton"

- Directory: `/home/me/project`
- Date: 2026-10-11 19:46
- Found 3 of "OldButton"

- [ ] `src/App.tsx:1:10`
- [ ] `src/App.tsx:2:2`
- [ ] `src/legacy/OldButton.tsx:1:14`
```

Tick items off as you go. Halfway through a review the list looks like this:

- [x] `src/App.tsx:1:10`
- [x] `src/App.tsx:2:2`
- [ ] `src/legacy/OldButton.tsx:1:14`

`search` never overwrites an existing checklist, so a re-run cannot wipe out your ticks. It exits with status 2 instead.

### Exit status

| Code | Meaning |
| --- | --- |
| `0` | At least one match |
| `1` | No matches |
| `2` | Bad arguments, missing directory, or the `-o` file exists or cannot be written |

This makes `search` usable in scripts:

```sh
search "console.log" src >/dev/null && echo "remove debug logs before committing"
```

### Configuration

Define either array in `~/.zshrc` to replace its default.

| Variable | Default | Example |
| --- | --- | --- |
| `SEARCH_EXTENSIONS` | Common source and text types: `ts tsx js css scss html json md py sh` and more | `SEARCH_EXTENSIONS=(ts tsx scss)` |
| `SEARCH_EXCLUDE_DIRS` | `.git node_modules dist build out coverage .next .nuxt .cache vendor` | add `tmp` to the list |

The `-t` flag overrides `SEARCH_EXTENSIONS` for a single run. The full default list is in the [README](https://github.com/Vilunki15/omz-search#search_extensions).

### Limitations

- A match cannot span lines.
- `.gitignore` is not read. Use `SEARCH_EXCLUDE_DIRS` for generated folders.
- Checklist line numbers do not update if you edit the files afterwards.
- A checklist saved inside the searched folder contains the phrase, so later searches will find it too.

---

Source code and full README: [github.com/Vilunki15/omz-search](https://github.com/Vilunki15/omz-search)
