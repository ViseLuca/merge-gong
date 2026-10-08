# 🔔 Merge Gong

A macOS menu bar app that strikes a gong every time a pull request gets merged.

Because shipping deserves ceremony.

When a PR is merged on one of the repos you watch, Merge Gong plays a synthesized gong
(no audio files, pure math), drops a shaking **GONG!** popup at the top of the screen,
and lights up the menu bar. Click the popup to open the PR.

## Requirements

- macOS 13 or later (Apple Silicon or Intel)
- [GitHub CLI](https://cli.github.com) installed and logged in:

  ```sh
  brew install gh
  gh auth login
  ```

Merge Gong talks to GitHub only through `gh`, so it sees exactly the repos your `gh` login can see.
No tokens are stored by the app.

## Install

### From source

```sh
git clone https://github.com/ViseLuca/merge-gong.git
cd merge-gong
./build.sh install
```

This needs the Xcode Command Line Tools (`xcode-select --install`).

`build.sh` options:

| Command              | What it does                                              |
|----------------------|-----------------------------------------------------------|
| `./build.sh`         | Builds `build/Merge Gong.app` (universal binary)          |
| `./build.sh install` | Builds, copies to `~/Applications` and launches it        |
| `./build.sh dist`    | Builds and zips it into `build/MergeGong.zip` for sharing |

### From a shared zip

The app is ad-hoc signed, not notarized, so macOS will refuse to open a downloaded copy.
After unzipping, either right-click the app → **Open**, or run:

```sh
xattr -dr com.apple.quarantine "Merge Gong.app"
```

## Usage

Everything lives in the 🔔 menu bar icon (the menu is in Italian, gong is universal):

| Menu item                   | Meaning                                                        |
|-----------------------------|----------------------------------------------------------------|
| **Repo da ascoltare**       | Tick the repos to watch. Lists your recent repos from GitHub.  |
| ↳ **Aggiungi altro repo…**  | Add any repo by name (`owner/name`).                           |
| **Filtra branch…**          | Only gong for merges into this base branch. Empty = all.       |
| **Suona il gong**           | Test strike (⌘G).                                              |
| **Ultimi merge**            | Latest merged PRs across watched repos. Click to open.         |
| **Esci**                    | Quit (⌘Q).                                                     |

Errors from `gh` (missing auth, unknown repo, …) show up in the menu with a ⚠️.

## How it works

- Every 30 seconds it runs `gh api repos/<owner>/<name>/pulls?state=closed…` for each watched repo.
- The first poll after a change only records existing merges, so you don't get a gong storm at startup.
- Merges arriving in the same poll across several repos produce a single gong.
- Each repo costs about 120 API calls per hour, well within GitHub's 5,000/hour authenticated limit.

The whole app is a single file: [`Sources/main.swift`](Sources/main.swift).

## Start at login

System Settings → General → Login Items → **+** → pick `Merge Gong.app`.
