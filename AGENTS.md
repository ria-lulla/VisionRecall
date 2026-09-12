# Repository Guidelines

## Project Structure & Module Organization

This repository is currently an empty Git project. As implementation begins, keep the layout predictable:

- `src/` for application or library source code.
- `tests/` for automated tests, mirroring paths under `src/` where practical.
- `assets/` for static, non-code resources.
- `docs/` for design notes and user-facing documentation.

Do not commit generated build output, local environment files, credentials, or dependency caches. Add appropriate entries to `.gitignore` when tooling is introduced.

## Build, Test, and Development Commands

No build system or package manager is configured yet. When adding one, document the canonical commands here and in the project README. At a minimum, provide commands for:

- installing dependencies;
- running the application locally;
- formatting and linting;
- running the complete test suite.

Prefer a small, repeatable command surface—for example, `npm test`, `npm run lint`, and `npm run build`, or equivalent commands for the selected language.

## Coding Style & Naming Conventions

Follow the formatter and linter selected for the project; commit their configuration files. Use spaces rather than tabs unless the language ecosystem strongly requires otherwise. Name files and directories consistently with the primary language convention, and use descriptive names such as `user-profile.ts` or `user_profile.py` rather than abbreviations.

Keep modules focused, avoid unrelated refactors in feature changes, and add comments only where intent is not clear from the code.

## Testing Guidelines

Add tests with each behavior change. Place them in `tests/` or alongside source files according to the chosen framework, and use names that describe expected behavior (for example, `returns_error_for_missing_token`). Run the full test suite and formatter/linter before opening a pull request.

## Commit & Pull Request Guidelines

There is no commit history yet. Use concise, imperative commit subjects, such as `Add session validation` or `Fix empty state rendering`. Keep commits focused and avoid committing secrets.

Pull requests should explain the change, note testing performed, link related issues when applicable, and include screenshots for visible UI changes. Flag configuration, migration, or security implications explicitly.
