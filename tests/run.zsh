#!/usr/bin/env zsh
# Tests for search.plugin.zsh. Run from anywhere: zsh tests/run.zsh
# Builds a small fixture tree in a temporary directory, runs search against it
# and compares the output and exit status. Exits non-zero if any test fails.

ROOT=${0:A:h:h}
source $ROOT/search.plugin.zsh

# :A resolves symlinks, e.g. /var -> /private/var on macOS, like search does.
TMP=${$(mktemp -d):A}
trap 'rm -rf $TMP' EXIT
passed=0
failed=0

# check NAME EXPECTED_STATUS EXPECTED_OUTPUT COMMAND...
# Runs COMMAND in a subshell, capturing stdout and stderr together.
check() {
  local name=$1 want_status=$2 want=$3 got got_status
  shift 3
  got=$("$@" 2>&1)
  got_status=$?
  if [[ $got_status == $want_status && $got == $want ]]; then
    (( ++passed ))
    print -r -- "ok   $name"
  else
    (( ++failed ))
    print -r -- "FAIL $name"
    print -r -- "  status: expected $want_status, got $got_status"
    print -r -- "  expected output:"
    print -r -- "$want" | sed 's/^/    /'
    print -r -- "  got output:"
    print -r -- "$got" | sed 's/^/    /'
  fi
}

# Fixture tree
cd $TMP
mkdir -p src "my dir" node_modules/pkg
print -l 'search params' 'nothing here' 'x search params search params' > src/a.ts
print -r -- '/* search params */' > src/style.scss
print -r -- 'Search Params' > "my dir/b.tsx"
print -l 'searchXparams' 'search.params' > src/regex.ts
print -r -- 'a { -webkit-box: 1 }' > src/dash.css
print -r -- 'search params' > src/notes.log
print -r -- 'search params' > node_modules/pkg/c.ts
printf 'search params\0\1\2' > src/blob.ts

check "lists every match with line and column, sorted by path" 0 \
'Found 4 of "search params"
src/a.ts:1:1
src/a.ts:3:3
src/a.ts:3:17
src/style.scss:1:4' \
  search "search params"

check "-i ignores case" 0 \
'Found 5 of "search params"
my dir/b.tsx:1:1
src/a.ts:1:1
src/a.ts:3:3
src/a.ts:3:17
src/style.scss:1:4' \
  search -i "search params"

check "-t limits the file extensions" 0 \
'Found 1 of "search params"
src/style.scss:1:4' \
  search -t scss "search params"

check "the phrase is matched literally, not as a regex" 0 \
'Found 1 of "search.params"
src/regex.ts:2:1' \
  search "search.params"

check "-- allows a phrase that starts with a dash" 0 \
'Found 1 of "-webkit-"
src/dash.css:1:5' \
  search -- "-webkit-"

with_log_extension() {
  local -a SEARCH_EXTENSIONS=(log)
  search "search params"
}
check "SEARCH_EXTENSIONS replaces the default extensions" 0 \
'Found 1 of "search params"
src/notes.log:1:1' \
  with_log_extension

check "no matches gives exit status 1" 1 \
'Found 0 of "no such phrase"' \
  search "no such phrase"

check "missing phrase gives usage and exit status 2" 2 \
'Usage: search [-i] [-t ext,ext,...] [-o checklist.md] "phrase" [directory]' \
  search

check "unknown directory gives exit status 2" 2 \
'search: no such directory: nowhere' \
  search "search params" nowhere

check "-o prints the matches and saves a checklist" 0 \
"Found 1 of \"search params\"
src/style.scss:1:4
Checklist saved to $TMP/review.md" \
  search -o $TMP/review.md -t scss "search params"

check "the checklist has a header and one unticked item per match" 0 \
"# Search: \"search params\"

- Directory: \`$TMP\`
- Found 1 of \"search params\"

- [ ] \`src/style.scss:1:4\`" \
  grep -v '^- Date: ' $TMP/review.md

check "-o refuses to overwrite an existing checklist" 2 \
"search: $TMP/review.md already exists, choose another file name" \
  search -o $TMP/review.md "search params"

check "with a directory argument, paths stay relative to the current directory" 0 \
'Found 1 of "search params"
src/style.scss:1:4' \
  search -t scss "search params" src

check "with a directory argument, the checklist header names the current directory" 0 \
"- Directory: \`$TMP\`
- [ ] \`src/style.scss:1:4\`" \
  eval 'search -o $TMP/review-src.md -t scss "search params" src >/dev/null && grep -e "^- Directory: " -e "^- \[ \]" $TMP/review-src.md'

print
print "$passed passed, $failed failed"
(( failed == 0 ))
