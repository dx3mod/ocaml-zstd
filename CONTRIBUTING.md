# Contributing to `zstd`

Thanks for your interest in contributing! This document explains how to
build, test, and lint the project.

## Building

The project uses [Dune]. To build everything, run:

```sh
dune build
```

To run the test suite:

```sh
dune test
```

## Code style

- Follow the existing OCaml and C formatting conventions in the repository.
- Keep changes focused. A single pull request should address one issue or
  feature.
- Add documentation for any new public functions or types.

## Linting C/OCaml bindings

The project uses [ocaml-c-bindings-rules], a set of [Opengrep] rules that
check for common mistakes in C stubs that interface with OCaml (unrooted
values, mismatched argument counts, incorrect blocking sections, and
similar issues).

### Running the linter

From the repository root, run:

```sh
opengrep scan --config rules/ocaml-c-bindings-rules.yml .
```

The scan reports any violations of the rules. Fix all findings before
submitting a pull request.

## Submitting changes

1. Fork the repository and create a new branch.
2. Make your changes, run `dune build`, `dune test`, and the linter.
3. Open a pull request against the `master` branch.
4. Describe your change and reference any relevant issues.

We are always open to pull requests!

[Opengrep]: https://www.opengrep.dev
[ocaml-c-bindings-rules]: https://github.com/dx3mod/ocaml-c-bindings-rules
[Dune]: https://dune.build