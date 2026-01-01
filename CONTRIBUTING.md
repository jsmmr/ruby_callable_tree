# Commit Message Convention

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification.

## Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

## Header

The header is mandatory and must not exceed 72 characters.

### Type

Must be one of the following:

- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation only changes
- **style**: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)
- **refactor**: A code change that neither fixes a bug nor adds a feature
- **perf**: A code change that improves performance
- **test**: Adding missing tests or correcting existing tests
- **build**: Changes that affect the build system or external dependencies (example scopes: gulp, broccoli, npm)
- **ci**: Changes to our CI configuration files and scripts (example scopes: Travis, Circle, BrowserStack, SauceLabs)
- **chore**: Other changes that don't modify src or test files
- **revert**: Reverts a previous commit

### Scope

The scope is optional and should be a phrase describing the section of the codebase affected.

### Subject

The subject contains a succinct description of the change:

- Use the imperative, present tense: "change" not "changed" nor "changes"
- Don't capitalize the first letter
- No dot (.) at the end

## Body

The body is optional and should include the motivation for the change and contrast this with previous behavior.

## Footer

The footer is optional and should contain any information about **Breaking Changes** and is also the place to reference GitHub issues that this commit closes.

## Branch Naming

We generally use the following prefixes for branch names:

- `feature/`: New features (e.g., `feature/login-screen`)
- `fix/`: Bug fixes (e.g., `fix/memory-leak`)
- `docs/`: Documentation only changes (e.g., `docs/update-readme`)
- `style/`: Changes that do not affect the meaning of the code (e.g., `style/rubocop-fixes`)
- `refactor/`: Code changes that neither fix a bug nor add a feature (e.g., `refactor/extract-method`)
- `test/`: Adding or correcting tests (e.g., `test/add-rspec-cases`)
- `chore/`: Changes to the build process or auxiliary tools and libraries (e.g., `chore/update-gems`)

Use kebab-case for the branch name (e.g., `feature/my-new-feature`).

