# Contributing

Issues and pull requests are welcome. This is a small project, so nothing here is heavy — read the two sections below and open the thing

## AI assistance

Parts of this repository are written with AI assistance, and that is disclosed per commit. A commit whose diff is substantially machine-written carries a trailer naming the tool and the model:

```
Generated-by: Claude Code:claude-opus-5
Assisted-by: Claude Code:claude-opus-5 (mostly)
```

`Generated-by:` means the task was carried out without a hand in it — set, reviewed, accepted as it came. `Assisted-by:` means it was steered: `(mostly)` when most of the final diff came from the tool, `(partly)` when a substantial part did. Commits without a trailer are hand-written, dictated line by line, or mechanical — a formatter run, or a rename swept with grep

The same is expected of contributions. Name the tool and the model you used, in a trailer or in the pull request description. Do not use `Co-authored-by:` for a tool: it is reserved for human co-authors, and [nixpkgs](https://github.com/NixOS/nixpkgs/blob/master/CONTRIBUTING.md), [Mesa](https://gitlab.freedesktop.org/mesa/mesa/-/blob/main/docs/submittingpatches.rst) and the [kernel](https://docs.kernel.org/process/coding-assistants.html) all reject it as disclosure. Never sign off on a tool's behalf — only a human can certify a Developer Certificate of Origin

Whoever opens the pull request answers for it. Review what the tool wrote, understand it, and be ready to discuss it without forwarding the questions back to the tool. Undisclosed generated code is the one thing that gets a pull request closed unread

Where the split is genuinely unclear, a bare `Assisted-by:` with no suffix is the right answer — it stays true of anything worth arguing about. The convention and the upstream policies behind it are collected in [rokokol/ai-commit-trailers](https://github.com/rokokol/ai-commit-trailers)

## Before a pull request

```sh
nix flake check
```

One commit per logical change, and keep the formatting churn in its own commit — `nix fmt` before you push

Commit messages: a short imperative subject saying what changes, and a body for why, if the why is not obvious

By contributing you agree that your work is released under this repository's licence
