<p align="center">
  <a href="https://github.com/emmanuel-ferdman/gh-gonest">
    <picture>
      <img src="https://raw.githubusercontent.com/emmanuel-ferdman/gh-gonest/main/assets/logo-with-title.png" alt="gh-gonest" height="200px">
    </picture>
  </a>
</p>

---

`gh-gonest` is a [GitHub CLI extension][gh-extension] that automatically detects and removes phantom notifications from deleted repositories. When repositories create issues with mass @mentions and then get deleted, they leave behind "ghost" notifications due to a GitHub bug that prevents them from being cleared through the GitHub UI. This tool finds and cleans them up, restoring your notification sanity. See more information [here][github-discussion].

## 🎯 Problem

Spam repositories create issues, tag thousands of users via @mentions, then get deleted by GitHub. This leaves "phantom notifications" that:

- 🔵 Show persistent blue dot on notification bell
- 👻 Display "1-0 of X" in notification count
- 🚫 Cannot be cleared through GitHub UI
- 😤 Drive developers crazy

## ✨ Solution

`gh-gonest` automatically finds and removes these phantom notifications by:

1. **Scanning** all your notifications
2. **Detecting** phantom notifications from deleted repos (404 responses)
3. **Cleaning** them via read → done → unsubscribe sequence

## 👻 Why gh-gonest?

The `gh-gonest` extension approach focuses on:

- **Selective targeting**: Only marks ghost notifications as done, preserving all legitimate notifications
- **Automated detection**: Automatically identifies phantom notifications by checking for 404 repository responses - no manual notification ID lookup required
- **No manual token generation**: Leverages existing `gh auth login` setup without requiring manual GitHub token creation with specific permissions
- **Safe preview mode**: The `--dry-run` flag shows exactly what would be removed before taking action
- **Minimal dependencies**: Uses widely used tools (`gh` and `jq`) with simple shell scripting - no additional programming languages or unusual dependencies
- **Flexible date filtering**: Target specific time ranges with `--after` and `--before` flags for precise control

## ⚡ Getting Started

### 🛠️ Requirements

- [GitHub CLI][github-cli] (`gh`) - version 2.0+
- [jq][jq] - JSON processor
- GitHub authentication (`gh auth login`)

### 🚀 Installation

```bash
# Install the extension
gh extension install emmanuel-ferdman/gh-gonest

# Or manually install from source
git clone https://github.com/emmanuel-ferdman/gh-gonest.git
cd gh-gonest
gh extension install .
```

### 📖 Usage

```bash
# Preview what would be cleaned (safe)
gh gonest --dry-run

# Clean phantom notifications
gh gonest

# Only check notifications after a specific date
gh gonest --after 2025-09-01T00:00:00Z --dry-run

# Only check notifications before a specific date  
gh gonest --before 2025-09-30T23:59:59Z --dry-run

# Check notifications in a specific date range
gh gonest --after 2025-09-01T00:00:00Z --before 2025-09-30T23:59:59Z --dry-run
```

## 🛠️ Development

```bash
# Clone the repository
git clone https://github.com/emmanuel-ferdman/gh-gonest.git
cd gh-gonest

# Install development dependencies
make setup

# Run the tests suite
make test

# Run the linter
make lint

# Install extension locally
make install
```

## 🤝 Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## 📄 License

The library is freely distributable under the terms of the [MIT license][license].

<!-- Link references -->
[gh-extension]: https://cli.github.com/manual/gh_extension
[github-cli]: https://cli.github.com
[github-discussion]: https://github.com/orgs/community/discussions/6874
[jq]: https://jqlang.github.io/jq
[license]: LICENSE
