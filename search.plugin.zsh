# search - find a literal phrase in source and text files.
#
#   search [-i] [-t ext,ext,...] [-o checklist.md] "phrase" [directory]
#
# Prints "Found N of "phrase"" followed by one path:line:column per match.
# With -o, the matches are also written to a Markdown checklist.
# See README.md for configuration.

# Default file extensions and skipped directories. Override either one by
# defining the array in ~/.zshrc (before or after Oh My Zsh is loaded).
(( ${+SEARCH_EXTENSIONS} )) || typeset -ga SEARCH_EXTENSIONS=(
  ts tsx js jsx mjs cjs vue svelte
  css scss sass less html htm
  json yml yaml toml xml ini
  md mdx txt csv
  sh bash zsh py rb php go rs java kt swift c h cpp hpp cs sql graphql
)
(( ${+SEARCH_EXCLUDE_DIRS} )) || typeset -ga SEARCH_EXCLUDE_DIRS=(
  .git node_modules dist build out coverage .next .nuxt .cache vendor
)

search() {
  emulate -L zsh

  local usage='Usage: search [-i] [-t ext,ext,...] [-o checklist.md] "phrase" [directory]'
  local ignore_case=0 outfile opt OPTIND OPTARG
  local -a exts

  while getopts ':it:o:h' opt; do
    case $opt in
      i) ignore_case=1 ;;
      t) exts=(${(s:,:)OPTARG}) ;;
      o) outfile=$OPTARG ;;
      h) print -r -- $usage; return 0 ;;
      *) print -ru2 -- $usage; return 2 ;;
    esac
  done
  shift $(( OPTIND - 1 ))

  if (( $# < 1 || $# > 2 )) || [[ -z $1 ]]; then
    print -ru2 -- $usage
    return 2
  fi

  local query=$1 dir=${2:-.}
  if [[ ! -d $dir ]]; then
    print -ru2 -- "search: no such directory: $dir"
    return 2
  fi
  # Never overwrite a checklist: it may already contain ticked items.
  if [[ -n $outfile && -e $outfile ]]; then
    print -ru2 -- "search: $outfile already exists, choose another file name"
    return 2
  fi
  (( $#exts )) || exts=($SEARCH_EXTENSIONS)

  # grep picks the files that contain the phrase (skipping binaries),
  # awk then reports every occurrence with its line and column.
  local -a grep_args=(-rlIF --null)
  (( ignore_case )) && grep_args+=(-i)
  local e d
  for e in $exts; do grep_args+=(--include="*.${e#.}"); done
  for d in $SEARCH_EXCLUDE_DIRS; do grep_args+=(--exclude-dir=$d); done

  local -a files
  files=(${(o0)"$(grep $grep_args -e $query -- $dir 2>/dev/null)"})

  local -a matches
  if (( $#files )); then
    matches=(${(f)"$(SEARCH_QUERY=$query SEARCH_ICASE=$ignore_case awk -- '
      BEGIN {
        q = ENVIRON["SEARCH_QUERY"]
        icase = ENVIRON["SEARCH_ICASE"] == 1
        if (icase) q = tolower(q)
        qlen = length(q)
      }
      FNR == 1 {
        path = FILENAME
        sub(/^\.\//, "", path)
      }
      {
        s = icase ? tolower($0) : $0
        off = 0
        while ((i = index(substr(s, off + 1), q)) > 0) {
          printf "%s:%d:%d\n", path, FNR, off + i
          off += i + qlen - 1
        }
      }
    ' $files)"})
  fi

  print -r -- "Found $#matches of \"$query\""
  (( $#matches )) && print -rl -- $matches

  if [[ -n $outfile ]]; then
    {
      print -r -- "# Search: \"$query\""
      print
      # Paths in the list are relative to the current directory, not to $dir.
      print -r -- "- Directory: \`$PWD\`"
      print -r -- "- Date: $(date '+%Y-%m-%d %H:%M')"
      print -r -- "- Found $#matches of \"$query\""
      print
      local m
      for m in $matches; do print -r -- "- [ ] \`$m\`"; done
    } > $outfile || return 2
    print -r -- "Checklist saved to $outfile"
  fi
  (( $#matches ))
}
