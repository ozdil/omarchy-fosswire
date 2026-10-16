// Pure data helpers for the FOSSWire plugin. No QML here, so the functions
// can be checked outside the shell (tests/test_omarchy_plugin.py runs them
// under node).

var SITE = "https://fosswire.org"

// Every language of the site's language menu, in the site's order.
var LANGUAGES = ["en", "tr", "de", "es", "fr", "it", "pt", "ru", "ja", "zh", "ko", "ar", "nl", "pl", "sv", "uk", "hi"]

// Native names, shown in the panel's language picker.
var LANGUAGE_NAMES = {
  en: "English", tr: "Türkçe", de: "Deutsch", es: "Español", fr: "Français", it: "Italiano",
  pt: "Português", ru: "Русский", ja: "日本語", zh: "中文", ko: "한국어", ar: "العربية",
  nl: "Nederlands", pl: "Polski", sv: "Svenska", uk: "Українська", hi: "हिन्दी"
}

function isLanguage(code) {
  return LANGUAGES.indexOf(String(code || "")) !== -1
}

// "pt-BR", "zh_CN.UTF-8" and "tr" all name a site language by their first
// two letters; anything else is not one.
function languageFromLocale(locale) {
  var code = String(locale || "").toLowerCase().slice(0, 2)
  return isLanguage(code) ? code : ""
}

// The reading language: the one picked in the panel, else the widget's
// `language` setting, else Omarchy's display language, else English.
function pickLanguage(saved, setting, shellLanguage) {
  if (isLanguage(saved)) return saved
  if (isLanguage(setting)) return setting
  return languageFromLocale(shellLanguage) || "en"
}

function isRightToLeft(lang) {
  return lang === "ar"
}

function feedUrl() {
  return SITE + "/api/v1/feed.json"
}

// Translated titles and takeaways keyed by slug. English has none: the feed
// itself is English.
function titlesUrl(lang) {
  return SITE + "/api/v1/titles/" + encodeURIComponent(lang) + ".json"
}

function takeawaysUrl(lang) {
  return SITE + "/api/v1/takeaways/" + encodeURIComponent(lang) + ".json"
}

// The ?lang= parameter makes the page open in the plugin's language even
// when the browser last read the site in another one.
function articleUrl(slug, lang) {
  return SITE + "/news/" + encodeURIComponent(slug) + ".html?lang=" + encodeURIComponent(lang || "en")
}

function homeUrl(lang) {
  return SITE + "/?lang=" + encodeURIComponent(lang || "en")
}

function decodeEntities(text) {
  var s = String(text || "")
  if (s.indexOf("&") === -1) return s
  var named = { amp: "&", lt: "<", gt: ">", quot: "\"", apos: "'", nbsp: " " }
  return s.replace(/&(#x[0-9a-fA-F]+|#[0-9]+|[a-zA-Z]+);/g, function(whole, ref) {
    if (ref.charAt(0) === "#") {
      var code = ref.charAt(1) === "x" || ref.charAt(1) === "X" ? parseInt(ref.slice(2), 16) : parseInt(ref.slice(1), 10)
      return isNaN(code) ? whole : String.fromCodePoint(code)
    }
    return named.hasOwnProperty(ref) ? named[ref] : whole
  })
}

function parseObject(raw) {
  try {
    var data = JSON.parse(String(raw || ""))
    return data && typeof data === "object" && !Array.isArray(data) ? data : null
  } catch (e) {
    return null
  }
}

// The newest `limit` articles of feed.json, in `lang`. A title the site has
// not translated yet stays English, as it does on the site; a missing
// translated takeaway is left out rather than shown in English.
function buildItems(feed, titles, takeaways, lang, limit) {
  var articles = feed && Array.isArray(feed.articles) ? feed.articles.slice() : []
  var english = lang === "en"
  titles = titles || {}
  takeaways = takeaways || {}

  articles.sort(function(a, b) {
    return (Date.parse(b.published_at || "") || 0) - (Date.parse(a.published_at || "") || 0)
  })

  var out = []
  for (var i = 0; i < articles.length && out.length < (limit || 12); i++) {
    var art = articles[i]
    if (!art || !art.slug) continue
    var title = english ? art.title : (titles[art.slug] || art.title)
    var takeaway = english ? art.takeaway : takeaways[art.slug]
    out.push({
      slug: String(art.slug),
      title: decodeEntities(title),
      takeaway: decodeEntities(takeaway || ""),
      source: decodeEntities(art.source || ""),
      publishedAt: String(art.published_at || ""),
      url: articleUrl(art.slug, lang)
    })
  }
  return out
}

// Clips a bar label to `max` characters, never mid-surrogate-pair.
function truncate(text, max) {
  var chars = Array.from(String(text || ""))
  if (!max || chars.length <= max) return chars.join("")
  return chars.slice(0, Math.max(1, max - 1)).join("").replace(/\s+$/, "") + "…"
}

// Index of the next language in the picker, wrapping round.
function cycleLanguage(lang, step) {
  var i = LANGUAGES.indexOf(lang)
  if (i === -1) return "en"
  var n = LANGUAGES.length
  return LANGUAGES[((i + (step || 1)) % n + n) % n]
}

// The saved choice lives in a small state file next to Omarchy's own
// widget state (weather.json): {"language": "tr"}.
function parseState(raw) {
  var data = parseObject(raw) || {}
  return { language: isLanguage(data.language) ? data.language : "" }
}

function serializeState(lang) {
  return JSON.stringify({ language: isLanguage(lang) ? lang : "" }) + "\n"
}
