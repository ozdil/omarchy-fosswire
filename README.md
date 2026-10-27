# FOSSWire for Omarchy

Open source and open hardware news from [fosswire.org](https://fosswire.org) in the Omarchy top bar.

A native Omarchy shell plugin: it runs inside `omarchy-shell` (Quickshell), draws with the
shell's own components and theme tokens, and uses the shell font, which is JetBrains Mono
Nerd Font unless you changed it with `omarchy font set`. Switching themes recolors it live.

- **Bar:** the fosswire.org logo, drawn in the bar's own color. It takes the theme's accent color while there are stories
  you have not seen in the panel yet, and hovering shows the newest headline. Left click opens
  the news panel, middle click refreshes, right click opens fosswire.org.
- **Panel:** the latest headlines with source and time; the highlighted story also shows its
  key takeaway. Enter or click opens the article in your browser.
- **About:** the 󰋽 button (or `a`) shows the version, developer and license straight from
  `manifest.json`, with links to the source code, GitHub Sponsors and Buy Me a Coffee.
- **Interface in 17 languages:** English, Türkçe, Deutsch, Español, Français, Italiano, Português,
  Русский, 日本語, 中文, 한국어, العربية (right to left), Nederlands, Polski, Svenska,
  Українська and हिन्दी. It picks the PC's language by itself (from `LANGUAGE`, `LC_ALL`, `LC_MESSAGES` or
  `LANG`, so `de_DE.UTF-8` gives German) and falls back to English for any other language. The news itself is in English, as on the site
  (fosswire.org is English only since 2026-10-26).

## Install

Needs Omarchy 4 (`omarchy-shell`), plus `curl` and `xdg-open` (xdg-utils), which Omarchy ships.

```sh
omarchy plugin add https://github.com/ozdil/omarchy-fosswire.git --enable
```

From a checkout of the FOSSWire repository instead:

```sh
integrations/omarchy/install.sh
```

After updating an installed copy, run `omarchy-restart-shell`: the running shell keeps the old
panel code until it restarts.

Move it on the bar with `omarchy bar move org.fosswire.news --section left` (or `center`,
`right`), or drag it. Remove it with `omarchy plugin remove org.fosswire.news`; the only file it leaves is its
saved language and last-seen story in `~/.local/state/omarchy/settings/fosswire.json`.

## Keys in the panel

| Key | Action |
|-----|--------|
| Up / Down, `j` / `k` | Move through the headlines |
| Enter | Open the highlighted article |
| `r` | Refresh |
| `o` | Open fosswire.org |
| `c` | Switch between the news and CVE Radar |
| `L` | Pick the language (Left / Right to change, Enter to close) |
| `a` | About: version, license and support links |
| Esc | Close |

To open the panel from a hotkey, bind a key to:

```sh
omarchy-shell shell toggle org.fosswire.news '{}'
```

## Settings

Set inline on the bar entry in `~/.config/omarchy/shell.json` (or with `omarchy bar set`),
for example `{ "id": "org.fosswire.news", "showHeadline": false }`:

| Key | Default | Meaning |
|-----|---------|---------|
| `language` | `auto` | An interface language code, or `auto` for the PC's language |
| `icon` | `logo` | `logo` for the fosswire.org mark, or any short text or Nerd Font glyph such as `󰮮` |
| `showHeadline` | `false` | Also write the newest headline on the bar (never on a vertical bar) |
| `maxChars` | `42` | Longest headline shown on the bar |
| `count` | `12` | Headlines in the panel (3 to 30) |
| `refreshMinutes` | `30` | How often to fetch the news (at least 5) |

A language picked in the panel is saved in `~/.local/state/omarchy/settings/fosswire.json`
and wins over the `language` setting. The same file remembers the newest story you have seen.

## How it works

The plugin reads the site's public JSON API with `curl`; there is no account and nothing is
sent besides the requests themselves:

- `https://fosswire.org/api/v1/feed.json`: the newest articles
- `https://fosswire.org/api/v1/security.json`: CVE Radar advisories

## Develop

```sh
omarchy plugin validate integrations/omarchy/fosswire
qmllint -I "$OMARCHY_PATH/shell" integrations/omarchy/fosswire/*.qml
python3 -m unittest tests.test_omarchy_plugin
```

`Model.js` and `Strings.js` hold no QML, so the tests run them under node.

## Support

If FOSSWire is useful to you: [GitHub Sponsors](https://github.com/sponsors/ozdil) ·
[Buy Me a Coffee](https://buymeacoffee.com/ozdil)
