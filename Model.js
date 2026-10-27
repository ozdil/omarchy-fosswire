// Pure data helpers for the FOSSWire plugin. No QML here, so the functions
// can be checked outside the shell (tests/test_omarchy_plugin.py runs them
// under node).

var SITE = "https://fosswire.org"
var REPO_URL = "https://github.com/ozdil/omarchy-fosswire"

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

// "pt-BR", "zh_CN.UTF-8", "de_DE@euro" and "tr" all name a site language by
// the code before the region; "C", "POSIX" and languages the site lacks do not.
function languageFromLocale(locale) {
  var code = String(locale || "").trim().toLowerCase().split(/[_.@-]/)[0]
  return isLanguage(code) ? code : ""
}

// The PC's language from its locale variables, read the way gettext reads
// them: LANGUAGE ("de:en", a list in order of preference) first, unless the
// locale is C or POSIX; then LC_ALL, LC_MESSAGES and LANG. Each list entry
// that the site lacks is skipped, so "da:de" gives German.
function systemLanguage(env) {
  env = env || {}
  var locale = String(env.LC_ALL || env.LC_MESSAGES || env.LANG || "").trim()
  var base = locale.split(/[.@]/)[0].toUpperCase()
  if (base !== "C" && base !== "POSIX") {
    var wanted = String(env.LANGUAGE || "").split(":")
    for (var i = 0; i < wanted.length; i++) {
      var code = languageFromLocale(wanted[i])
      if (code) return code
    }
  }
  return languageFromLocale(locale)
}

// The reading language: the one picked in the panel, else the widget's
// `language` setting, else a display language chosen in Omarchy, else the
// PC's own language, else English.
function pickLanguage(saved, setting, shellLanguage, pcLanguage) {
  if (isLanguage(saved)) return saved
  if (isLanguage(setting)) return setting
  return languageFromLocale(shellLanguage) || languageFromLocale(pcLanguage) || "en"
}

function isRightToLeft(lang) {
  return lang === "ar"
}

function feedUrl() {
  return SITE + "/api/v1/feed.json"
}

// The site is English only since 2026-10-26: the news is shown in English
// whatever the panel's interface language is.
function articleUrl(slug) {
  return SITE + "/news/" + encodeURIComponent(slug)
}

function homeUrl() {
  return SITE + "/"
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

// The newest `limit` articles of feed.json.
function buildItems(feed, limit) {
  var articles = feed && Array.isArray(feed.articles) ? feed.articles.slice() : []

  articles.sort(function(a, b) {
    return (Date.parse(b.published_at || "") || 0) - (Date.parse(a.published_at || "") || 0)
  })

  var out = []
  for (var i = 0; i < articles.length && out.length < (limit || 12); i++) {
    var art = articles[i]
    if (!art || !art.slug) continue
    out.push({
      slug: String(art.slug),
      title: decodeEntities(art.title),
      takeaway: decodeEntities(art.takeaway || ""),
      source: decodeEntities(art.source || ""),
      publishedAt: String(art.published_at || ""),
      url: articleUrl(art.slug)
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

// Saved state lives in a small file next to Omarchy's own widget state
// (weather.json): the language picked in the panel and the publication time
// of the newest story seen there, which tells the bar whether news is new.
function parseState(raw) {
  var data = parseObject(raw) || {}
  return {
    language: isLanguage(data.language) ? data.language : "",
    seenAt: typeof data.seenAt === "string" ? data.seenAt : ""
  }
}

function serializeState(lang, seenAt) {
  return JSON.stringify({ language: isLanguage(lang) ? lang : "", seenAt: String(seenAt || "") }) + "\n"
}

function securityUrl() {
  return SITE + "/api/v1/security.json"
}

function securityPageUrl() {
  return SITE + "/security"
}

function buildAdvisories(sec, limit) {
  var list = sec && Array.isArray(sec.advisories) ? sec.advisories.slice() : []
  var sevRank = { CRITICAL: 4, HIGH: 3, MEDIUM: 2, LOW: 1 }

  list.sort(function(a, b) {
    var sa = sevRank[String(a && a.severity || "").toUpperCase()] || 0
    var sb = sevRank[String(b && b.severity || "").toUpperCase()] || 0
    if (sb !== sa) return sb - sa
    return (Date.parse(b && b.published_at || "") || 0) - (Date.parse(a && a.published_at || "") || 0)
  })

  var out = []
  for (var i = 0; i < list.length && out.length < (limit || 10); i++) {
    var adv = list[i]
    if (!adv || !adv.slug) continue
    out.push({
      cveId: String(adv.cve_id || (Array.isArray(adv.advisory_ids) && adv.advisory_ids[0]) || "ADVISORY"),
      severity: String(adv.severity || "UNRATED").toUpperCase(),
      cvss: typeof adv.cvss === "number" ? adv.cvss : null,
      product: decodeEntities(adv.product || ""),
      title: decodeEntities(adv.title || ""),
      summary: decodeEntities(adv.mitigation || adv.summary || ""),
      publishedAt: String(adv.published_at || ""),
      url: articleUrl(adv.slug)
    })
  }
  return out
}

// True when the newest story came out after the one last seen in the panel.
// Nothing seen yet counts as new, so a fresh install draws attention once.
function hasUnseen(items, seenAt) {
  if (!items || !items.length) return false
  var newest = Date.parse(items[0].publishedAt || "") || 0
  return newest > (Date.parse(seenAt || "") || 0)
}

