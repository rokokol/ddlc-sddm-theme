# Bash completion for ./install.sh of ddlc-sddm-theme. Sourced from the checkout, not
# installed:
#   source completions/install.sh.bash
# No dependency on the bash-completion package — everything used here is bash builtin.
#
# The flag list is written by hand on purpose and checked against install.sh by
# tests/check-completions.sh: a flag added to the installer fails the suite until it
# lands here and in the zsh file too
_install_sh_completion() {
  local cur prev
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD - 1]}"

  local flags=(-h --help -v --version --prefix --destdir --component
    --no-cursors --no-configure --uninstall)

  case "$prev" in
    --component)
      mapfile -t COMPREPLY < <(compgen -W "theme cursors all" -- "$cur")
      return
      ;;
    --prefix | --destdir)
      compopt -o dirnames 2>/dev/null || true
      COMPREPLY=()
      return
      ;;
  esac
  mapfile -t COMPREPLY < <(compgen -W "${flags[*]}" -- "$cur")
}
complete -F _install_sh_completion install.sh ./install.sh
