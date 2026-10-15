# 🔔 Merge Gong

A macOS menu bar app that strikes a gong every time a pull request gets merged.

Because shipping deserves ceremony.

Works with **GitHub**, **Bitbucket Cloud** and **Bitbucket Data Center**, alone or together.

When a PR is merged on one of the repos you watch, Merge Gong plays a synthesized gong
(no audio files, pure math), drops a shaking **GONG!** popup at the top of the screen,
and lights up the menu bar. Click the popup to open the PR.

## Requirements

- macOS 13 or later (Apple Silicon or Intel)
- For each service you want to connect:

| Service                   | What you need                                                                                                                              |
|---------------------------|--------------------------------------------------------------------------------------------------------------------------------------------|
| **GitHub**                | [GitHub CLI](https://cli.github.com) logged in: `brew install gh && gh auth login`. Merge Gong goes through `gh` and stores no GitHub token. |
| **Bitbucket Cloud**       | Your Atlassian email and an [API token with scopes](https://id.atlassian.com/manage-profile/security/api-tokens), choosing Bitbucket and the scopes `read:repository:bitbucket`, `read:pullrequest:bitbucket`, `read:workspace:bitbucket`, `read:user:bitbucket`. |
| **Bitbucket Data Center** | The server URL and an HTTP access token (profile → Manage account → HTTP access tokens) with repository read permission.                   |

Bitbucket tokens are kept in the macOS Keychain (service `merge-gong`). Instead of the token you can
enter a 1Password reference such as `op://Engineering/Bitbucket/token`: Merge Gong stores only the
reference and reads the secret with the [1Password CLI](https://developer.1password.com/docs/cli/) (`op`)
when it connects.

## Install

### Download (no Xcode needed)

1. Download **[MergeGong.zip](https://github.com/ViseLuca/merge-gong/releases/latest/download/MergeGong.zip)** from the [latest release](https://github.com/ViseLuca/merge-gong/releases/latest).
2. Unzip it and move `Merge Gong.app` to `Applications`.
3. The app is ad-hoc signed, not notarized, so macOS blocks it on first launch. Unblock it once with:

   ```sh
   xattr -dr com.apple.quarantine "/Applications/Merge Gong.app"
   ```

   or try to open it, then go to System Settings → Privacy & Security → **Open Anyway**.
4. Open it: a 🔔 appears in the menu bar and asks what to connect (GitHub, Bitbucket Cloud,
   Bitbucket Data Center, any mix). You can change it later from **Servizi collegati**.

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
| `./build.sh test`    | Runs the tests                                            |

## Usage

Everything lives in the 🔔 menu bar icon (the menu is in Italian, gong is universal):

| Menu item                   | Meaning                                                        |
|-----------------------------|----------------------------------------------------------------|
| **Repo da ascoltare**       | Tick the repos to watch. Lists your recent repos per service.  |
| ↳ **Aggiungi altro repo…**  | Add any repo by name (`owner/name`, `workspace/repo`, `PROJECT/repo`). |
| **Servizi collegati**       | Connect, reconfigure or disconnect GitHub and Bitbucket.       |
| **Filtra branch…**          | Only gong for merges into this base branch. Empty = all.       |
| **Suona il gong**           | Test strike (⌘G).                                              |
| **Ultimi merge**            | Latest merged PRs across watched repos. Click to open.         |
| **Esci**                    | Quit (⌘Q).                                                     |

Errors (missing `gh`, wrong token, unknown repo, …) show up in the menu with a ⚠️.

## How it works

- It polls each watched repo for recently merged pull requests:

  | Service               | Call                                                                 | Every | Limit                                 |
  |-----------------------|----------------------------------------------------------------------|-------|---------------------------------------|
  | GitHub                | `gh api repos/<owner>/<name>/pulls?state=closed…`                   | 30 s  | 5,000/h: ~120/h per repo, no worries  |
  | Bitbucket Cloud       | `GET /2.0/repositories/<workspace>/<repo>/pullrequests?state=MERGED` | 60 s  | 1,000/h: about 16 repos at most       |
  | Bitbucket Data Center | `GET /rest/api/1.0/projects/<KEY>/repos/<repo>/pull-requests?state=MERGED` | 30 s | set by your server            |

- The first poll after a change only records existing merges, so you don't get a gong storm at startup.
- Merges arriving in the same poll across several repos produce a single gong.
- Settings from the GitHub-only version are migrated: your watched repos keep working.
- The app is ad-hoc signed, so after installing a new build macOS may ask again to let it read its Keychain item.

## Project layout

A Swift package with no dependencies:

| Path                       | What                                                                    |
|----------------------------|-------------------------------------------------------------------------|
| `Sources/MergeGongCore`    | Services (`Providers/`), Keychain and 1Password, settings, merge tracking. No AppKit. |
| `Sources/MergeGong`        | The menu bar app: polling, menu, setup dialogs, popup, gong synth.      |
| `Tests/MergeGongCoreTests` | API decoding, merge tracking, settings migration.                       |

Adding a service means one new `Provider` in `Sources/MergeGongCore/Providers` and a case in `ProviderKind`.

## Start at login

System Settings → General → Login Items → **+** → pick `Merge Gong.app`.

## License

[MIT](LICENSE)
