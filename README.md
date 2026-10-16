# FOSSWire for Omarchy

Open source and open hardware news from [fosswire.org](https://fosswire.org) in the Omarchy top bar.

A native Omarchy shell plugin: it runs inside `omarchy-shell` (Quickshell), draws with the
shell's own components and theme tokens, and uses the shell font, which is JetBrains Mono
Nerd Font unless you changed it with `omarchy font set`. Switching themes recolors it live.

- **Bar:** a newspaper glyph and the newest headline. Left click opens the news panel,
  middle click refreshes, right click opens fosswire.org.
- **Panel:** the latest headlines with source and time; the highlighted story also shows its
  key takeaway. Enter or click opens the article in your browser.
- **All 17 site languages:** English, Türkçe, Deutsch, Español, Français, Italiano, Português,
  Русский, 日本語, 中文, 한국어, العربية (right to left), Nederlands, Polski, Svenska,
  Українська and हिन्दी. By default it follows Omarchy's display language and falls back to
  English. Articles open on the site in the same language.

## Install

```sh
omarchy plugin add https://github.com/ozdil/omarchy-fosswire.git --enable
```

From a checkout of the FOSSWire repository instead:

```sh
integrations/omarchy/install.sh
```

Move it on the bar with `omarchy bar move org.fosswire.news --section left` (or `center`,
`right`), or drag it. Remove it with `omarchy plugin remove org.fosswire.news`.

## Keys in the panel

| Key | Action |
|-----|--------|
| Up / Down, `j` / `k` | Move through the headlines |
| Enter | Open the highlighted article |
| `r` | Refresh |
| `o` | Open fosswire.org |
| `L` | Pick the language (Left / Right to change, Enter to close) |
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
| `language` | `auto` | A site language code, or `auto` for Omarchy's display language |
| `showHeadline` | `true` | Show the newest headline next to the glyph (never on a vertical bar) |
| `maxChars` | `42` | Longest headline shown on the bar |
| `count` | `12` | Headlines in the panel (3 to 30) |
| `refreshMinutes` | `30` | How often to fetch the news (at least 5) |

A language picked in the panel is saved in `~/.local/state/omarchy/settings/fosswire.json`
and wins over the `language` setting.

## How it works

The plugin reads the site's public JSON API with `curl`; there is no account and nothing is
sent besides the requests themselves:

- `https://fosswire.org/api/v1/feed.json`: the newest articles (English)
- `https://fosswire.org/api/v1/titles/<lang>.json` and `takeaways/<lang>.json`: translations

A title the site has not translated yet is shown in English, as on the site.

## Develop

```sh
omarchy plugin validate integrations/omarchy/fosswire
qmllint -I "$OMARCHY_PATH/shell" integrations/omarchy/fosswire/*.qml
python3 -m unittest tests.test_omarchy_plugin
```

`Model.js` and `Strings.js` hold no QML, so the tests run them under node.
