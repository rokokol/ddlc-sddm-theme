# Zsh completion for ./install.sh of ddlc-sddm-theme. Sourced from the checkout, not
# installed:
#   source completions/install.sh.zsh
# Defines the function and registers it directly — no fpath, no rehash; needs compinit
# to have run, which every interactive zsh with completion already has.
#
# The flag list is written by hand on purpose and checked against install.sh by
# check-sh.sh -c in scripts-lint — same discipline as the bash file
_install_sh_completion() {
  _arguments \
    '(-h --help)'{-h,--help}'[show help and exit]' \
    '(-v --version)'{-v,--version}'[print the version and exit]' \
    '--prefix[install prefix]:directory:_files -/' \
    '--destdir[staging root]:directory:_files -/' \
    '--component[which component to install]:component:(theme cursors all)' \
    '--no-cursors[compatibility shorthand for --component theme]' \
    '--no-configure[do not touch /etc/sddm.conf.d]' \
    '--uninstall[remove a previous install by its manifest]'
}
compdef _install_sh_completion install.sh
