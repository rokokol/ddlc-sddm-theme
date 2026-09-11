#!/usr/bin/env bash
# The gate a shell utility needs, in one file that travels. The help is the single source
# of truth for what a script accepts, so every subcommand its dispatcher has, every flag
# its parsers take, every variable it reads and every code it exits with must be in the
# help — and every document and completion that restates a list is held to the same code,
# in both directions. Each check is proven able to fail on every run, on a canonical
# script with one defect planted, so a copy of this file falsifies itself wherever it runs.
#
#   check-sh.sh [-n NAME] [-e PREFIX] [-d DOC]... [-m DOC]... [-c BASH ZSH] SCRIPT
#   check-sh.sh --template [script|bash|zsh]
#
#   -n NAME      what the help, the docs and the completions call the script (default:
#                the script's basename)
#   -e PREFIX    the script reads environment variables with this prefix; each must be
#                in the help
#   -d DOC       a document that lists the script's subcommands, checked both ways: every
#                subcommand named, and every `NAME word` it spells real; repeatable
#   -m DOC       a document that mentions only some of them and sends the reader to the
#                help for the rest: every `NAME word` it spells must be real; repeatable
#   -c BASH ZSH  the two completion files, checked both ways
#   --template   print the canonical script, or its bash or zsh completion, and exit
#
# The shapes it reads are the standard's own: a `case "$cmd"` dispatcher at the top level
# with `-h | --help | help)` and a `*)` arm that sends usage to stderr, flag arms such as
# `-n | --dry-run)` inside cmd_<sub>() functions or at the top level, literal `exit N`,
# and the help as the header of the file or a `help [SUB]` subcommand. They are spelled
# out in references/shape.md and help.md of
# https://github.com/rokokol/bash-best-practices-skill. A header line claiming
# "Needs bash 3.2" turns on a grep for constructs newer than 3.2 or absent from a BSD
# userland; a grep is a proxy, and the proof is a run under the real 3.2.
#
# Exit 0 when everything agrees, 1 with one `check-sh: <what>` line per finding, 2 on a
# usage error, an unreadable file, a --help that fails, or a script with nothing to check.
# Nothing here reaches the network. Needs bash 3.2 and POSIX tools only, so it runs on a
# macOS runner unchanged. It has no repo-specific part: another repository takes it
# through the vendoring cascade (references/bump-cascade.md in
# https://github.com/rokokol/ci-skill), never edits its copy in place, and calls it from
# its own gate.
set -euo pipefail

# The whole header, however long it grows: up to the first line that is not a comment
usage() { sed -n '2,/^[^#]/p' "${BASH_SOURCE[0]}" | sed '$d; s/^# \{0,1\}//'; }

self=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/$(basename -- "${BASH_SOURCE[0]}")

die() { # a usage error, never a finding
  printf 'check-sh: %s\n' "$1" >&2
  exit 2
}

# ---- the canonical script, and the completions that mirror it -------------------------
# The self-test below plants defects into this script, and `--template` prints it, so the
# shape the checker proves itself on and the shape it hands out are one text.

template_script() {
  cat <<'EOF'
#!/usr/bin/env bash
# script.sh — one line saying what it is, in the shape every script of the family has.
#
#   script.sh run [-n|--dry-run] [-l DIR]    do the thing, in DIR
#   script.sh stop                           stop doing it
#
#   -n, --dry-run   say what would be done and do nothing
#   -l DIR          the log directory (default: $SCRIPT_LOGDIR, else the current one)
#
# Environment: SCRIPT_LOGDIR is the log directory when -l is not given.
# Exit 0 done, 1 when the thing asked about is wrong, 2 on a usage error.
# Nothing here reaches the network. Needs bash 3.2 and POSIX tools only.
set -euo pipefail

# The whole header, however long it grows: up to the first line that is not a comment
usage() { sed -n '2,/^[^#]/p' "${BASH_SOURCE[0]}" | sed '$d; s/^# \{0,1\}//'; }

fail() { # the thing asked about is wrong
  printf 'script.sh: %s\n' "$1" >&2
  exit 1
}

die() { # the request itself is wrong
  printf 'script.sh: %s\n' "$1" >&2
  exit 2
}

HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

# >>> EXAMPLE: the subcommands, one cmd_<name>() each, with their parser inside
cmd_run() {
  local dry=0 logdir="${SCRIPT_LOGDIR:-.}"
  while (($#)); do
    case "$1" in
      -n | --dry-run)
        dry=1
        shift
        ;;
      -l)
        # Not ${2:?}: that exits 1 with bash's own message, and a usage error is 2
        (($# >= 2)) || die "-l needs a directory"
        logdir="$2"
        shift 2
        ;;
      -*) die "no such flag: $1" ;;
      *) break ;;
    esac
  done
  [[ -d "$logdir" ]] || fail "$logdir is not a directory"
  if ((dry)); then
    printf 'would run in %s\n' "$logdir"
  else
    printf 'ran in %s from %s\n' "$logdir" "$HERE"
  fi
}

cmd_stop() {
  printf 'stopped\n'
}
# <<< EXAMPLE

cmd="${1:-}"
(($# == 0)) || shift
case "$cmd" in
  run) cmd_run "$@" ;;
  stop) cmd_stop "$@" ;;
  -h | --help | help) usage ;;
  '')
    usage >&2
    exit 2
    ;;
  *)
    printf 'script.sh: no such subcommand: %s\n\n' "$cmd" >&2
    usage >&2
    exit 2
    ;;
esac
EOF
}

template_bash() {
  cat <<'EOF'
# shellcheck shell=bash
# Tab completion for script.sh in bash. Hand-written on purpose and drift-checked by
# machine: check-sh.sh -c holds every word here to the script's dispatcher and parsers.
# Builtins only, so it works without the bash-completion package and under the bash 3.2
# a stock macOS sources it with.
_script_sh() {
  local cur prev words
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD - 1]}"
  if ((COMP_CWORD == 1)); then
    words="run stop help"
  else
    case "${COMP_WORDS[1]}" in
      run)
        case "$prev" in
          -l)
            compopt -o dirnames 2>/dev/null || true
            return
            ;;
        esac
        words="-n --dry-run -l"
        ;;
      *) words="" ;;
    esac
  fi
  COMPREPLY=()
  while IFS= read -r word; do
    [[ -n "$word" ]] && COMPREPLY+=("$word")
  done < <(compgen -W "$words" -- "$cur")
}
complete -F _script_sh script.sh
EOF
}

template_zsh() {
  cat <<'EOF'
#compdef script.sh
# Tab completion for script.sh in zsh. Hand-written on purpose and drift-checked by
# machine: check-sh.sh -c holds every word here to the script's dispatcher and parsers.
# The #compdef line binds it when the file sits on $fpath as _script.sh, and the last
# line calls the function, which is the autoload convention.
_script_sh() {
  local -a subcommands
  subcommands=(
    'run:do the thing'
    'stop:stop doing it'
    'help:show the help'
  )
  _arguments -C \
    '1:subcommand:->subcommand' \
    '*::arguments:->arguments'
  case "$state" in
    subcommand) _describe 'subcommand' subcommands ;;
    arguments)
      case "${words[1]}" in
        run)
          _arguments \
            '(-n --dry-run)'{-n,--dry-run}'[say what would be done]' \
            '-l[the log directory]:directory:_directories'
          ;;
      esac
      ;;
  esac
}
_script_sh "$@"
EOF
}

# ---- arguments --------------------------------------------------------------------
name=""
prefix=""
docs=()
mentions=()
comp_bash=""
comp_zsh=""
script=""
while (($#)); do
  case "$1" in
    -n)
      (($# >= 2)) || die "-n needs a name"
      name="$2"
      shift 2
      ;;
    -e)
      (($# >= 2)) || die "-e needs a prefix"
      prefix="$2"
      shift 2
      ;;
    -d)
      (($# >= 2)) || die "-d needs a document"
      docs+=("$2")
      shift 2
      ;;
    -m)
      (($# >= 2)) || die "-m needs a document"
      mentions+=("$2")
      shift 2
      ;;
    -c)
      (($# >= 3)) || die "-c needs two files, the bash and the zsh completion"
      comp_bash="$2"
      comp_zsh="$3"
      shift 3
      ;;
    --template)
      case "${2:-script}" in
        script) template_script ;;
        bash) template_bash ;;
        zsh) template_zsh ;;
        *) die "no such template: $2 — script, bash or zsh" ;;
      esac
      exit 0
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*)
      usage >&2
      exit 2
      ;;
    *)
      [[ -z "$script" ]] || die "one script at a time"
      script="$1"
      shift
      ;;
  esac
done
[[ -n "$script" ]] || {
  usage >&2
  exit 2
}
[[ -r "$script" ]] || die "cannot read $script"
[[ -n "$name" ]] || name=$(basename -- "$script")
for f in "${docs[@]+"${docs[@]}"}" "${mentions[@]+"${mentions[@]}"}" "$comp_bash" "$comp_zsh"; do
  [[ -z "$f" || -r "$f" ]] || die "cannot read $f"
done

findings=0
finding() {
  printf 'check-sh: %s\n' "$1" >&2
  findings=$((findings + 1))
}

# With a template, because the BSD mktemp on macOS wants one
work=$(mktemp -d "${TMPDIR:-/tmp}/check-sh.XXXXXX")
trap 'rm -rf "$work"' EXIT

# The code, with every heredoc body blanked and its line numbers kept: a help text or a
# template inside a heredoc carries dispatchers, flag rows and exit lines of its own,
# which are not this script's. The opening line stays, since it can carry code
strip_heredocs() { # strip_heredocs FILE -> the file with heredoc bodies as empty lines
  awk '
    inhd {
      line = $0
      if (dash) sub(/^\t+/, "", line)
      if (line == term) inhd = 0
      print ""
      next
    }
    match($0, /<<-?['"'"'"]?[A-Za-z_][A-Za-z0-9_]*/) {
      w = substr($0, RSTART, RLENGTH)
      dash = (substr(w, 3, 1) == "-")
      sub(/^<<-?['"'"'"]?/, "", w)
      term = w
      inhd = 1
    }
    { print }
  ' "$1"
}

# ERE-quoted, so a name with a dot matches itself and nothing else
name_re=$(printf '%s' "$name" | sed 's/[][\\.*^$/+?(){}|]/\\&/g')

# Whole tokens only. A substring match let `-f` pass on a completion that offered only
# `--force`, and `grep -w` treats the hyphen as a separator, accepting `--help` inside
# `--help-all`. A `]` is literal only first in a bracket expression, and `\]` is not an
# escape there — GNU grep 3.12 read the escaped form as the bracket's end.
has_token() { # has_token TOKEN <<<TEXT -> 0 when TEXT holds TOKEN as a whole token
  grep -qE -- "(^|[^[:alnum:]_-])$1([^[:alnum:]_-]|\$)"
}

# What a completion file offers, without the prose around it. A word in a comment is not
# offered, and neither is one in a zsh description: the text in `[...]` after an option,
# the part after the colon of a `'sub:description'` entry, the message between the first
# colons of an `'N:message:action'` spec — whose action, `(run stop)`, is kept. Quotes are
# walked a line at a time, so a `#` inside them is not a comment.
offered_words() { # offered_words FILE 0|1 -> FILE with comments dropped, and zsh prose when 1
  awk -v zsh="$2" '
    function prose(s, n, f, i, out) {
      if (!zsh) return s
      gsub(/\[[^]]*\]/, "", s)
      n = split(s, f, ":")
      if (n < 2) return s
      if (n == 2) return f[1]
      out = f[1]
      for (i = 2; i <= n && f[i] == ""; i++) out = out ":"
      out = out ":"
      for (i++; i <= n; i++) out = out ":" f[i]
      return out
    }
    {
      line = $0; out = ""; q = ""; body = ""
      while (line != "") {
        c = substr(line, 1, 1)
        if (q == "") {
          if (c == "#" && (out == "" || out ~ /[ \t]$/)) break
          if (c == "\047" || c == "\"") { q = c; body = "" } else out = out c
          line = substr(line, 2)
        } else if (c == "\\" && q == "\"") {
          body = body substr(line, 1, 2); line = substr(line, 3)
        } else if (c == q) {
          out = out q prose(body) q; q = ""; line = substr(line, 2)
        } else {
          body = body c; line = substr(line, 2)
        }
      }
      if (q != "") out = out q body
      print out
    }
  ' "$1"
}

# ---- the truth: read out of the code ---------------------------------------------
# Subcommands, flags with the subcommand they belong to (`-` for a global one), the
# environment variables read, the exit codes returned. Extractors that find nothing are
# findings or refusals, because an empty list passes every loop.

subs=()
flags=() # "SUB<TAB>FLAG" per line, SUB is - for a global flag
open_set=0
proxy_only=0
{
  header=$(sed -n '2,/^[^#]/p' "$script" | sed '$d')
  claims_32=0
  ! printf '%s\n' "$header" | grep -q 'Needs bash 3\.2' || claims_32=1
  code="$work/code"
  strip_heredocs "$script" >"$code"

  # The dispatcher: the top-level `case "$cmd" in` … `esac`, one arm per subcommand,
  # `a | b)` split into two. The help arm and the refusal arms are not subcommands.
  # shellcheck disable=SC2016 # `$cmd` is matched literally, in the script's own text
  dispatch=$(sed -n '/^case "\$cmd" in$/,/^esac$/p' "$code")
  if [[ -n "$dispatch" ]]; then
    while IFS= read -r arm; do
      [[ -n "$arm" && "$arm" != help ]] || continue
      subs+=("$arm")
    done < <(printf '%s\n' "$dispatch" |
      sed -n 's/^  \([a-z][a-z0-9-]*\( *| *[a-z][a-z0-9-]*\)*\)).*/\1/p' | tr '|' '\n' | tr -d ' ')
    # The *) arm refuses, and a refusal is not output: a usage printed there goes to stderr.
    # A wrapper's *) arm passes the word through to another tool instead, and says so with
    # the comment `# pass-through` inside the arm; then the subcommand set is open — the
    # help and the docs may name commands the dispatcher never spells — and only the flags
    # stay closed. A declaration rather than a guess: whether an arm refuses is decided by
    # the helper it calls, which no grep can see
    refusal=$(printf '%s\n' "$dispatch" | sed -n '/^  \([^)]* | \)\{0,1\}\*)/,/;;/p')
    [[ -n "$refusal" ]] || finding "$name's dispatcher has no *) arm to refuse an unknown subcommand"
    [[ -z "$refusal" ]] || ! printf '%s\n' "$refusal" | grep -E '(^|[^[:alnum:]_])usage([^[:alnum:]_]|$)' | grep -qv '>&2' ||
      finding "$name's *) arm prints its usage to stdout rather than stderr"
    ! printf '%s\n' "$refusal" | grep -q '# pass-through' || open_set=1
  fi

  # The flags: every `-x | --long)` arm, attributed to the cmd_<sub>() function it sits
  # in, or global when it sits in no function. Arms in any other function are not a
  # parser of this script's own flags and are left alone. The function is found by its
  # opening line at column 0, so a nested case is read as its function's.
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    flags+=("$line")
  done < <(awk '
    # A one-line function, `usage() { …; }`, opens and closes on the same line
    /^[a-z_][a-z0-9_]*\(\) \{/ && !/\}[[:space:]]*$/ { fn = $0; sub(/\(\).*/, "", fn); next }
    /^}/ { fn = ""; next }
    match($0, /^ *(--?[a-zA-Z][a-zA-Z0-9-]*)( *\| *--?[a-zA-Z][a-zA-Z0-9-]*)*\)/) {
      line = substr($0, RSTART, RLENGTH)
      sub(/\)$/, "", line)
      gsub(/ /, "", line)
      n = split(line, parts, "|")
      owner = "-"
      if (fn != "") {
        if (substr(fn, 1, 4) == "cmd_") { owner = substr(fn, 5); gsub(/_/, "-", owner) } else next
      }
      for (i = 1; i <= n; i++) print owner "\t" parts[i]
    }' "$code")
  # A plain script with no dispatcher and no flag has no help for anything to agree with.
  # If its header claims bash 3.2 the proxy below is still worth running, and it is all
  # that runs; with no claim either there is nothing to check, which is a refusal
  if ((${#subs[@]} + ${#flags[@]} == 0)); then
    ((claims_32)) ||
      die "nothing to check in $script: no case \"\$cmd\" dispatcher, no flag arms and no bash 3.2 claim — see references/shape.md"
    proxy_only=1
  fi
  # The help arm is spelled one way, so a reader and a completion can count on all three.
  # A wrapper passes `help` through to the tool behind it, whose help is the better one,
  # so it may answer -h and --help as flags before the dispatcher instead
  if [[ -n "$dispatch" ]] && ! printf '%s\n' "$dispatch" | grep -qE '^  -h \| --help \| help\)'; then
    if ! { ((open_set)) && printf '%s\n' "${flags[@]+"${flags[@]}"}" | grep -qx -- $'-\t--help'; }; then
      finding "$name's dispatcher has no -h | --help | help arm"
    fi
  fi
}

known_sub() { # known_sub WORD -> 0 when the dispatcher has it, or it is the help, or the set is open
  local s
  [[ "$1" != help ]] || return 0
  ((open_set == 0)) || return 0
  for s in "${subs[@]+"${subs[@]}"}"; do [[ "$s" == "$1" ]] && return 0; done
  return 1
}
known_flag() { # known_flag FLAG [SUB] -> 0 when SUB (or any parser) accepts it, or it is the help
  local f owner want="${2:-}"
  case "$1" in -h | --help) return 0 ;; esac
  for f in "${flags[@]+"${flags[@]}"}"; do
    owner="${f%%	*}"
    [[ "${f#*	}" == "$1" ]] || continue
    [[ -z "$want" || "$owner" == "$want" || "$owner" == - ]] && return 0
  done
  return 1
}

# ---- the bash 3.2 claim: a proxy, honestly labelled ------------------------------
# Every literal below is split by a bracket expression so the pattern cannot match its
# own line. A grep is a proxy: it once let nine constructs through that the real 3.2
# rejects, which is why the claim is proven by a run under /bin/bash on a macOS runner
# and this is only the cheap first look. It runs before the help is asked for, since
# under a real 3.2 a script holding such a construct may not parse at all
if ((claims_32)); then
  bash4='\[\[[^]]*[-]v [A-Za-z_]|mapfil[e] |readarra[y] |declar[e] -A|loca[l] -A|declar[e] -n|loca[l] -n'
  bash4="$bash4"'|\$\{[A-Za-z_]+,[,]\}|\$\{[A-Za-z_]+\^[\^]\}|\$\{[A-Za-z_]+@[QEPAaKk]\}|;;[&]|[^|]\|[&][^&]|wai[t] -n'
  # A bare `mktemp -d` is fine on macOS, whose page says it "behaves as if -t tmp was
  # supplied"; the GNU flags are not, and -t means a prefix there and a template here
  bsd='sor[t] -[A-Za-z]*V|gre[p] -[A-Za-z]*P|readlin[k] -f|dat[e] -d|mktem[p] (-[dqu]+ )*(-[pt]|--tmpdir|--suffix)'
  while IFS= read -r hit; do
    [[ -n "$hit" ]] || continue
    finding "$name claims bash 3.2 but $script:$hit — a proxy grep; the proof is a run under 3.2"
  done < <(grep -nE "$bash4|$bsd" "$code" | grep -vE '^[0-9]+:[[:space:]]*#' | sed 's/^\([0-9]*\):[[:space:]]*/\1 has: /' || :)
fi

# ---- the help ---------------------------------------------------------------------
if ((! proxy_only)); then
  # Run under the bash running this checker, not the one the shebang finds: on a macOS
  # runner that is the 3.2 the claim is about
  help=$("$BASH" "$script" --help 2>&1) || die "$name --help exited $? rather than printing the help:"$'\n'"$help"
  [[ -n "$help" ]] || die "$name --help printed nothing"
  # A help printed from a fixed line range of the header stops short the day the header
  # grows; the open-ended form reads up to the first line that is not a comment
  if grep -qE 'sed -n '"'"'[0-9]+,[0-9]+p'"'"' "\$\{BASH_SOURCE' "$script"; then
    finding "$name's usage() prints a fixed line range of its header, which the header will outgrow"
  elif grep -qE '2,/\^\[\^#\]/p|!/\^#/ \{ exit \}' "$script"; then
    last=$(printf '%s\n' "$header" | tail -n 1 | sed 's/^# \{0,1\}//')
    [[ "$(printf '%s\n' "$help" | tail -n 1)" == "$last" ]] ||
      finding "$name --help stops before the end of its own header, whose last line is: $last"
  fi
  # Per-subcommand help, where the script has it: `help SUB` for each help_<sub>() it
  # defines. Its flags are then looked for there rather than in the general help
  corpus="$help"
  sub_help() { # sub_help SUB -> that subcommand's help, or nothing
    local fn="help_${1//-/_}"
    grep -q "^${fn}() {" "$script" || return 0
    "$BASH" "$script" help "$1" 2>/dev/null || return 0
  }
  for s in "${subs[@]+"${subs[@]}"}"; do
    text=$(sub_help "$s")
    [[ -z "$text" ]] || corpus="$corpus"$'\n'"$text"
  done
  # A `help codes` topic, when the script has one, is where the exit codes live
  ! grep -q '^help_codes() {' "$script" || corpus="$corpus"$'\n'"$("$BASH" "$script" help codes 2>/dev/null || :)"

  # help ⇐ dispatcher, and back
  # `NAME sub`, with any bracketed global options between — `NAME [--vault V] sub`
  for s in "${subs[@]+"${subs[@]}"}"; do
    printf '%s\n' "$help" | grep -qE -- "(^|[^[:alnum:]_./-])${name_re}( \[[^]]*\])* ${s}([^[:alnum:]_-]|\$)" ||
      finding "$name dispatches '$s' but its help never mentions '$name $s'"
  done
  while IFS= read -r s; do
    [[ -n "$s" ]] || continue
    known_sub "$s" || finding "$name's help lists '$name $s', which the dispatcher does not have"
  done < <(printf '%s\n' "$help" | grep -oE "(^|[^[:alnum:]_./-])${name_re} [a-z][a-z0-9-]*" |
    sed "s/^[^a-z]*${name_re} //" | sort -u)

  # help ⇐ flags, and back
  for f in "${flags[@]+"${flags[@]}"}"; do
    owner="${f%%	*}"
    flag="${f#*	}"
    case "$flag" in -h | --help) continue ;; esac
    if [[ "$owner" == - ]]; then
      has_token "$flag" <<<"$help" || finding "$name accepts $flag but its help never mentions it"
    else
      text=$(sub_help "$owner")
      [[ -n "$text" ]] || text="$help"
      has_token "$flag" <<<"$text" || finding "$name $owner accepts $flag but its help never mentions it"
    fi
  done
  while IFS= read -r flag; do
    [[ -n "$flag" ]] || continue
    known_flag "$flag" || finding "$name's help has a row for $flag, which no parser accepts"
  done < <(printf '%s\n' "$corpus" | grep -oE '^ +--?[a-zA-Z][a-zA-Z0-9-]*(, *--?[a-zA-Z][a-zA-Z0-9-]*)*' |
    tr ',' '\n' | tr -d ' ' | sort -u)

  # help ⇐ environment variables
  if [[ -n "$prefix" ]]; then
    variables=0
    while IFS= read -r var; do
      [[ -n "$var" ]] || continue
      variables=$((variables + 1))
      has_token "$var" <<<"$corpus" || finding "$name reads $var but its help never mentions it"
    done < <(grep -oE "(^|[^A-Za-z0-9_])${prefix}[A-Z0-9_]+" "$script" | sed 's/^[^A-Za-z0-9_]//' | sort -u)
    ((variables > 0)) || finding "$name reads no $prefix variable at all — the prefix is wrong, or the extractor is"
  fi

  # help ⇐ exit codes: every literal `exit N` outside a comment must be on a line of the
  # help that starts with Exit, or in a `  N  text` row. Only the bash shape counts — the
  # statement ends there — so an awk program's `{ exit 1 }` inside a quoted string is not
  # read as this script's code
  # The Exit sentence and the line after it, since a header wraps it; a `  N  text` row
  codes_listed=$(printf '%s\n' "$corpus" | awk '/Exit[ :]/ { print; getline; print; next } /^  [0-9]+  / { print }' |
    grep -oE '[0-9]+' | sort -u || :)
  while IFS= read -r n; do
    [[ -n "$n" ]] || continue
    printf '%s\n' "$codes_listed" | grep -qx -- "$n" ||
      finding "$name exits $n but its help never lists $n on an Exit line"
  done < <(grep -vE '^[[:space:]]*#' "$code" |
    grep -oE '(^|[;{(&|[:space:]])exit [1-9][0-9]*[[:space:]]*(;|&&|\|\||$)' | grep -oE '[0-9]+' | sort -u)
fi

# ---- the documents ----------------------------------------------------------------
# Back, for every document: each `NAME word` it spells is a subcommand, and each flag it
# attaches to one is parsed by it. This is the sharp direction — a document naming a
# subcommand that no longer exists is what the check exists to catch. Forward, only for
# a document given with -d, one that sets out to list them: every subcommand is named
# beside the script's name somewhere in it. A document given with -m mentions a few and
# sends the reader to the help for the rest, which is the help doing its job
doc_mentions_are_real() { # doc_mentions_are_real DOC -> a finding per mention that is not
  local doc="$1" span sub flag
  while IFS= read -r span; do
    [[ -n "$span" ]] || continue
    # shellcheck disable=SC2086 # the span is split into its words on purpose
    set -- $span
    shift # the name
    sub=""
    if [[ $# -gt 0 && "$1" =~ ^[a-z][a-z0-9-]*$ ]]; then
      sub="$1"
      known_sub "$sub" || finding "$doc names \`$name $sub\`, which $name does not have"
      shift
    fi
    while (($#)); do
      case "$1" in
        --) break ;;
        -[a-zA-Z]* | --[a-zA-Z]*)
          flag="${1%%=*}"
          known_flag "$flag" "$sub" ||
            finding "$doc gives \`$name${sub:+ $sub}\` the flag $flag, which it does not parse"
          ;;
      esac
      shift
    done
  done < <(grep -oE "\`${name_re}( [^\`]*)?\`" "$doc" | tr -d '`' | sort -u)
}
for doc in "${docs[@]+"${docs[@]}"}"; do
  for s in "${subs[@]+"${subs[@]}"}"; do
    grep -F -- "$name" "$doc" | has_token "$s" || finding "$doc never names $name $s"
  done
  doc_mentions_are_real "$doc"
done
for doc in "${mentions[@]+"${mentions[@]}"}"; do
  doc_mentions_are_real "$doc"
done

# ---- the completions --------------------------------------------------------------
if [[ -n "$comp_bash" ]]; then
  offered_words "$comp_bash" 0 >"$work/offered.bash"
  offered_words "$comp_zsh" 1 >"$work/offered.zsh"
  for f in "$comp_bash" "$comp_zsh"; do
    words="$work/offered.bash"
    [[ "$f" == "$comp_bash" ]] || words="$work/offered.zsh"
    for s in "${subs[@]+"${subs[@]}"}"; do
      has_token "$s" <"$words" || finding "$s is dispatched by $name but absent from $f"
    done
    for e in "${flags[@]+"${flags[@]}"}"; do
      flag="${e#*	}"
      case "$flag" in -h | --help) continue ;; esac
      has_token "$flag" <"$words" || finding "$flag is parsed by $name but absent from $f"
    done
  done
  offered=0
  while IFS= read -r flag; do
    [[ -n "$flag" ]] || continue
    offered=$((offered + 1))
    known_flag "$flag" || finding "$flag is offered by a completion but not parsed by $name"
  done < <(grep -ohE -- '--[a-z][a-z0-9-]+' "$work/offered.bash" "$work/offered.zsh" | sort -u)
  ((offered > 0)) || finding "neither completion offers a single --flag — the extractor is broken, or the files are"
fi

((findings == 0)) || exit 1

# ---- every check above is able to fail --------------------------------------------
# The canonical script above, its document and its completions pass as they are; then
# one copy per check gets one defect and this same script must go red for that defect's
# own reason, since a gate whose findings all come from one over-broad branch reads as
# thorough while testing one thing. A nested run skips this section.

if [[ -n "${CHECK_SH_NESTED:-}" ]]; then
  exit 0
fi

canon="$work/canon"
mkdir -p "$canon"
template_script >"$canon/script.sh"
template_bash >"$canon/script.sh.bash"
template_zsh >"$canon/_script.sh"
cat >"$canon/README.md" <<'EOF'
# script.sh

| Command | What it does |
|---|---|
| `script.sh run -n` | says what would be done |
| `script.sh stop` | stops it |

```
script.sh   the tool: run / stop
```
EOF

nested() { # nested DIR [ARGS...] -> this script on DIR's copy, falsification skipped
  local d="$1"
  shift
  CHECK_SH_NESTED=1 "$BASH" "$self" "$@"
}
copy() { # copy NAME -> a fresh copy of the canon
  local c="$work/$1"
  mkdir -p "$c"
  cp "$canon"/* "$c/"
  printf '%s\n' "$c"
}
full() { # full DIR -> the arguments that check everything in DIR
  printf -- '-n script.sh -e SCRIPT_ -d %s/README.md -c %s/script.sh.bash %s/_script.sh %s/script.sh\n' "$1" "$1" "$1" "$1"
}
planted=0
# The count lives here rather than beside each call, so a new planted case cannot be left
# out of the number the summary line reports
expect_red() { # expect_red DIR FRAGMENT WHAT [ARGS...]
  local d="$1" want="$2" what="$3" out
  shift 3
  if out=$(nested "$d" "$@" 2>&1); then
    die "self-test: a copy with $what passed — the check cannot catch it"
  fi
  case "$out" in
    *"$want"*) ;;
    *) die "self-test: a copy with $what was rejected for the wrong reason: $out" ;;
  esac
  planted=$((planted + 1))
}
# The constructs planted below are spelled in two halves, so this file's own claim of
# bash 3.2 is not contradicted by its own self-test
# Through the environment rather than -v: awk reads escape sequences in a -v value, so a
# planted line holding a backslash would arrive changed
plant() { # plant DIR AFTER-PATTERN LINE -> the line inserted after the first match
  PAT="$2" LINE="$3" awk '{ print } !done && index($0, ENVIRON["PAT"]) == 1 { print ENVIRON["LINE"]; done = 1 }' "$1/script.sh" >"$1/script.sh.new"
  mv "$1/script.sh.new" "$1/script.sh"
}
swap() { # swap DIR PATTERN LINE -> the first line starting with PATTERN replaced
  PAT="$2" LINE="$3" awk '!done && index($0, ENVIRON["PAT"]) == 1 { print ENVIRON["LINE"]; done = 1; next } { print }' "$1/script.sh" >"$1/script.sh.new"
  mv "$1/script.sh.new" "$1/script.sh"
}

c=$(copy faithful)
# shellcheck disable=SC2046 # full() prints the arguments, split on purpose
nested "$c" $(full "$c") >/dev/null 2>&1 ||
  die "self-test: the canonical script was rejected — the checker is broken, not the script:"$'\n'"$(nested "$c" $(full "$c") 2>&1 || :)"

c=$(copy nothing)
printf '#!/usr/bin/env bash\necho hi\n' >"$c/script.sh"
status=0
out=$(nested "$c" "$c/script.sh" 2>&1) || status=$?
((status == 2)) || die "self-test: a script with nothing to check was not refused (got $status): $out"
case "$out" in *"nothing to check"*) ;; *) die "self-test: a script with nothing to check was refused for the wrong reason: $out" ;; esac
planted=$((planted + 1))

c=$(copy plain-claimed)
# A plain script with no dispatcher and no flag, whose header claims bash 3.2, is checked
# by the proxy alone: clean it passes, with a bash 4 construct it goes red
printf '#!/usr/bin/env bash\n# Needs bash 3.2 and POSIX tools only.\necho hi\n' >"$c/plain.sh"
nested "$c" "$c/plain.sh" >/dev/null 2>&1 || die "self-test: a plain script claiming bash 3.2 was refused rather than checked by the proxy"
printf 'false && declar''e -A m\n' >>"$c/plain.sh"
expect_red "$c" "claims bash 3.2 but $c/plain.sh:" "a bash 4 construct in a plain script claiming 3.2" "$c/plain.sh"

c=$(copy helper-case)
# A case inside a helper function is not a parser of this script's flags
# shellcheck disable=SC2016 # the $1 belongs to the helper being written out
plant "$c" 'HERE=' 'helper() { case "$1" in --inner) : ;; esac; }'
# shellcheck disable=SC2046
nested "$c" $(full "$c") >/dev/null 2>&1 || die "self-test: a case in a helper function was read as a parser"

c=$(copy wrapper)
# A dispatcher whose *) arm passes the word through is a wrapper, and a wrapper's help may
# name the commands of the tool behind it
awk '/^  \*\)$/ { print "  *) printf '"'"'passing %s through\\n'"'"' \"$cmd\" ;; # pass-through"; skip = 1; next } skip && /^    ;;$/ { skip = 0; next } skip { next } { print }' "$c/script.sh" >"$c/s" && mv "$c/s" "$c/script.sh"
plant "$c" '#   script.sh stop' '#   script.sh anything                       passed through to the tool behind'
# shellcheck disable=SC2016 # the backticks are markdown, not a command substitution
printf '\nAlso `script.sh anything` goes through\n' >>"$c/README.md"
# shellcheck disable=SC2046
nested "$c" $(full "$c") >/dev/null 2>&1 || die "self-test: a wrapper's help naming a passed-through command was rejected:"$'\n'"$(nested "$c" $(full "$c") 2>&1 || :)"

c=$(copy bracketed)
# A global option in brackets between the name and the subcommand is still `NAME sub`
swap "$c" '#   script.sh stop' '#   script.sh [--quiet] stop                 stop doing it'
# shellcheck disable=SC2046
nested "$c" $(full "$c") >/dev/null 2>&1 || die "self-test: a help spelling 'script.sh [--quiet] stop' was read as not naming stop"

c=$(copy unclaimed)
# The proxy is gated on the claim: a script that does not claim 3.2 may use bash 4
sed 's/^# Nothing here reaches the network. Needs bash 3.2 and POSIX tools only.$/# Nothing here reaches the network./' "$c/script.sh" >"$c/s" && mv "$c/s" "$c/script.sh"
plant "$c" 'HERE=' 'false && declar'"e -A m"
# shellcheck disable=SC2046
nested "$c" $(full "$c") >/dev/null 2>&1 || die "self-test: a bash 4 construct was flagged in a script that claims no bash 3.2"

c=$(copy new-arm)
# shellcheck disable=SC2016 # the $cmd is the dispatcher's, matched literally
plant "$c" 'case "$cmd" in' '  planted) : ;;'
expect_red "$c" "dispatches 'planted' but its help never mentions 'script.sh planted'" "a subcommand missing from the help" -n script.sh "$c/script.sh"

c=$(copy ghost-sub)
plant "$c" '#   script.sh stop' '#   script.sh ghost                          a subcommand that is not there'
expect_red "$c" "help lists 'script.sh ghost', which the dispatcher does not have" "a subcommand the help invents" -n script.sh "$c/script.sh"

c=$(copy new-flag)
# shellcheck disable=SC2016 # the $1 is the parser's, matched literally
plant "$c" '    case "$1" in' '      --planted) shift ;;'
expect_red "$c" "script.sh run accepts --planted but its help never mentions it" "a flag missing from the help" -n script.sh "$c/script.sh"

c=$(copy ghost-flag)
plant "$c" '#   -l DIR' '#   --ghost         a flag no parser accepts'
expect_red "$c" "help has a row for --ghost, which no parser accepts" "a flag the help invents" -n script.sh "$c/script.sh"

c=$(copy new-variable)
# shellcheck disable=SC2016 # the expansion belongs to the script being written out
plant "$c" 'HERE=' ': "${SCRIPT_PLANTED:-}"'
expect_red "$c" "reads SCRIPT_PLANTED but its help never mentions it" "a variable missing from the help" -n script.sh -e SCRIPT_ "$c/script.sh"

c=$(copy no-variable)
expect_red "$c" "reads no NOPE_ variable at all" "a prefix nothing is read with" -n script.sh -e NOPE_ "$c/script.sh"

c=$(copy new-code)
plant "$c" 'HERE=' 'false && exi'"t 97"
expect_red "$c" "exits 97 but its help never lists 97" "an exit code missing from the help" -n script.sh "$c/script.sh"

c=$(copy fixed-range)
# shellcheck disable=SC2016 # the expansion belongs to the usage() being written out
swap "$c" 'usage() {' 'usage() { sed -n '"'"'2,3p'"'"' "${BASH_SOURCE[0]}" | sed '"'"'s/^# \{0,1\}//'"'"'; }'
expect_red "$c" "prints a fixed line range" "a usage() over a fixed line range" -n script.sh "$c/script.sh"

c=$(copy short-help)
# The header-extracted usage that stops early: the open-ended sed, then one line dropped
# shellcheck disable=SC2016 # the expansion belongs to the usage() being written out
swap "$c" 'usage() {' 'usage() { sed -n '"'"'2,/^[^#]/p'"'"' "${BASH_SOURCE[0]}" | sed '"'"'$d'"'"' | sed '"'"'$d; s/^# \{0,1\}//'"'"'; }'
expect_red "$c" "stops before the end of its own header" "a help that stops before the header's end" -n script.sh "$c/script.sh"

c=$(copy no-help-arm)
swap "$c" '  -h | --help | help) usage ;;' '  --help) usage ;;'
expect_red "$c" "has no -h | --help | help arm" "a dispatcher without a help arm" -n script.sh "$c/script.sh"

c=$(copy quiet-refusal)
# Every redirection inside the *) arm dropped, so the refusal goes to stdout
awk '/^  \*\)$/ { inarm = 1 } inarm { gsub(/ >&2/, "") } /;;/ { inarm = 0 } { print }' "$canon/script.sh" >"$c/script.sh"
expect_red "$c" "prints its usage to stdout rather than stderr" "a refusal that goes to stdout" -n script.sh "$c/script.sh"

c=$(copy doc-missing)
grep -v 'stop' "$canon/README.md" >"$c/README.md"
expect_red "$c" "README.md never names script.sh stop" "a document that lost a subcommand" -n script.sh -d "$c/README.md" "$c/script.sh"

c=$(copy doc-ghost)
# shellcheck disable=SC2016 # the backticks are markdown, not a command substitution
printf '\nAlso `script.sh ghost` for the thing that is not there\n' >>"$c/README.md"
expect_red "$c" "README.md names \`script.sh ghost\`, which script.sh does not have" "a document naming a subcommand that is not there" -n script.sh -d "$c/README.md" "$c/script.sh"

c=$(copy doc-ghost-flag)
# shellcheck disable=SC2016 # the backticks are markdown, not a command substitution
printf '\nAnd `script.sh run --ghost` for the flag that is not there\n' >>"$c/README.md"
expect_red "$c" "gives \`script.sh run\` the flag --ghost, which it does not parse" "a document attaching a flag that is not parsed" -n script.sh -d "$c/README.md" "$c/script.sh"

c=$(copy mention-partial)
# A document that mentions one subcommand and sends the reader to the help for the rest
# is not held to naming them all
# shellcheck disable=SC2016 # the backticks are markdown, not a command substitution
printf 'Run `script.sh stop` to stop it; `script.sh help` has the rest\n' >"$c/NOTE.md"
nested "$c" -n script.sh -m "$c/NOTE.md" "$c/script.sh" >/dev/null 2>&1 ||
  die "self-test: a document given with -m was held to naming every subcommand"

c=$(copy mention-ghost)
# shellcheck disable=SC2016 # the backticks are markdown, not a command substitution
printf 'Run `script.sh ghost` to stop it\n' >"$c/NOTE.md"
expect_red "$c" "NOTE.md names \`script.sh ghost\`, which script.sh does not have" "a mention of a subcommand that is not there" -n script.sh -m "$c/NOTE.md" "$c/script.sh"

c=$(copy comp-bash-missing)
sed 's/--dry-run//' "$canon/script.sh.bash" >"$c/script.sh.bash"
expect_red "$c" "--dry-run is parsed by script.sh but absent from $c/script.sh.bash" "a bash completion missing a flag" -n script.sh -c "$c/script.sh.bash" "$c/_script.sh" "$c/script.sh"

c=$(copy comp-zsh-missing)
grep -v "'stop:" "$canon/_script.sh" >"$c/_script.sh"
expect_red "$c" "stop is dispatched by script.sh but absent from $c/_script.sh" "a zsh completion missing a subcommand" -n script.sh -c "$c/script.sh.bash" "$c/_script.sh" "$c/script.sh"

c=$(copy comp-ghost)
sed 's/words="-n --dry-run -l"/words="-n --dry-run -l --ghost"/' "$canon/script.sh.bash" >"$c/script.sh.bash"
expect_red "$c" "--ghost is offered by a completion but not parsed by script.sh" "a completion offering a flag that is not parsed" -n script.sh -c "$c/script.sh.bash" "$c/_script.sh" "$c/script.sh"

c=$(copy comp-comment)
# A word that survives only in a comment is not offered
sed 's/words="-n --dry-run -l"/words="-n -l" # --dry-run is left out/' "$canon/script.sh.bash" >"$c/script.sh.bash"
expect_red "$c" "--dry-run is parsed by script.sh but absent from $c/script.sh.bash" "a flag named only in a comment of the bash completion" -n script.sh -c "$c/script.sh.bash" "$c/_script.sh" "$c/script.sh"

c=$(copy comp-description)
# A subcommand that survives only in another entry's description is not offered
grep -v "'stop:" "$canon/_script.sh" | sed "s/'run:do the thing'/'run:do the thing, or stop it'/" >"$c/_script.sh"
expect_red "$c" "stop is dispatched by script.sh but absent from $c/_script.sh" "a subcommand named only in a zsh description" -n script.sh -c "$c/script.sh.bash" "$c/_script.sh" "$c/script.sh"

c=$(copy comp-bracket)
# A flag that survives only in the [...] text of another option is not offered
sed "s/'(-n --dry-run)'{-n,--dry-run}'\[say what would be done\]'/'-n[say what would be done, as --dry-run does]'/" "$canon/_script.sh" >"$c/_script.sh"
expect_red "$c" "--dry-run is parsed by script.sh but absent from $c/_script.sh" "a flag named only in a zsh option description" -n script.sh -c "$c/script.sh.bash" "$c/_script.sh" "$c/script.sh"

c=$(copy comp-action)
# The action of an `N:message:action` spec is what zsh offers, and it counts
awk '/^  local -a subcommands$/ { skip = 1 } skip && /^  \)$/ { skip = 0; next } skip { next } { print }' "$canon/_script.sh" |
  sed "s/'1:subcommand:->subcommand'/'1:subcommand:(run stop help)'/; s/subcommand) _describe 'subcommand' subcommands ;;/subcommand) ;;/" >"$c/_script.sh"
nested "$c" -n script.sh -c "$c/script.sh.bash" "$c/_script.sh" "$c/script.sh" >/dev/null 2>&1 ||
  die "self-test: a zsh completion offering its subcommands as an action list was rejected:"$'\n'"$(nested "$c" -n script.sh -c "$c/script.sh.bash" "$c/_script.sh" "$c/script.sh" 2>&1 || :)"

c=$(copy claimed-bash4)
plant "$c" 'HERE=' 'false && declar'"e -A m"
expect_red "$c" "claims bash 3.2 but $c/script.sh:" "a bash 4 construct under a 3.2 claim" -n script.sh "$c/script.sh"

c=$(copy claimed-gnu-mktemp)
# shellcheck disable=SC2016 # the substitution belongs to the script being written out
plant "$c" 'HERE=' 'x=$(mktem'"p -d -p /tmp)"
expect_red "$c" "has: x=\$(mktem""p -d -p /tmp)" "a GNU mktemp flag under a 3.2 claim" -n script.sh "$c/script.sh"

printf 'check-sh: %s — %d subcommands, %d flags agree with the help; %d document(s), %s completions checked; %d planted defects caught\n' \
  "$name" "${#subs[@]}" "${#flags[@]}" "$((${#docs[@]} + ${#mentions[@]}))" "$([[ -n "$comp_bash" ]] && echo 2 || echo 0)" "$planted"
