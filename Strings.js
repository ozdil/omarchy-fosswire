// The plugin's own interface text in every site language. Article titles and
// takeaways come translated from the site; these are only the panel's labels.

var STRINGS = {
  en: { latest: "Latest news", refresh: "Refresh", openSite: "Open fosswire.org", language: "Language", loading: "Loading news…", failed: "Could not load the news.", stale: "Could not refresh; showing the last news.", tooltip: "FOSSWire news" },
  tr: { latest: "Son haberler", refresh: "Yenile", openSite: "fosswire.org'u aç", language: "Dil", loading: "Haberler yükleniyor…", failed: "Haberler yüklenemedi.", stale: "Yenilenemedi; son haberler gösteriliyor.", tooltip: "FOSSWire haberleri" },
  de: { latest: "Neueste Meldungen", refresh: "Aktualisieren", openSite: "fosswire.org öffnen", language: "Sprache", loading: "Nachrichten werden geladen…", failed: "Die Nachrichten konnten nicht geladen werden.", stale: "Aktualisierung fehlgeschlagen; letzte Meldungen werden gezeigt.", tooltip: "FOSSWire-Nachrichten" },
  es: { latest: "Últimas noticias", refresh: "Actualizar", openSite: "Abrir fosswire.org", language: "Idioma", loading: "Cargando noticias…", failed: "No se pudieron cargar las noticias.", stale: "No se pudo actualizar; se muestran las últimas noticias.", tooltip: "Noticias de FOSSWire" },
  fr: { latest: "Dernières nouvelles", refresh: "Actualiser", openSite: "Ouvrir fosswire.org", language: "Langue", loading: "Chargement des actualités…", failed: "Impossible de charger les actualités.", stale: "Actualisation impossible ; dernières actualités affichées.", tooltip: "Actualités FOSSWire" },
  it: { latest: "Ultime notizie", refresh: "Aggiorna", openSite: "Apri fosswire.org", language: "Lingua", loading: "Caricamento notizie…", failed: "Impossibile caricare le notizie.", stale: "Aggiornamento non riuscito; mostro le ultime notizie.", tooltip: "Notizie FOSSWire" },
  pt: { latest: "Últimas notícias", refresh: "Atualizar", openSite: "Abrir fosswire.org", language: "Idioma", loading: "Carregando notícias…", failed: "Não foi possível carregar as notícias.", stale: "Não foi possível atualizar; mostrando as últimas notícias.", tooltip: "Notícias do FOSSWire" },
  ru: { latest: "Последние новости", refresh: "Обновить", openSite: "Открыть fosswire.org", language: "Язык", loading: "Загрузка новостей…", failed: "Не удалось загрузить новости.", stale: "Не удалось обновить; показаны последние новости.", tooltip: "Новости FOSSWire" },
  ja: { latest: "最新ニュース", refresh: "更新", openSite: "fosswire.org を開く", language: "言語", loading: "ニュースを読み込み中…", failed: "ニュースを読み込めませんでした。", stale: "更新できませんでした。前回のニュースを表示しています。", tooltip: "FOSSWire ニュース" },
  zh: { latest: "最新新闻", refresh: "刷新", openSite: "打开 fosswire.org", language: "语言", loading: "正在加载新闻…", failed: "无法加载新闻。", stale: "无法刷新，正在显示上次的新闻。", tooltip: "FOSSWire 新闻" },
  ko: { latest: "최신 뉴스", refresh: "새로 고침", openSite: "fosswire.org 열기", language: "언어", loading: "뉴스를 불러오는 중…", failed: "뉴스를 불러오지 못했습니다.", stale: "새로 고치지 못해 마지막 뉴스를 표시합니다.", tooltip: "FOSSWire 뉴스" },
  ar: { latest: "أحدث الأخبار", refresh: "تحديث", openSite: "فتح fosswire.org", language: "اللغة", loading: "جارٍ تحميل الأخبار…", failed: "تعذر تحميل الأخبار.", stale: "تعذر التحديث؛ يتم عرض آخر الأخبار.", tooltip: "أخبار FOSSWire" },
  nl: { latest: "Laatste nieuws", refresh: "Vernieuwen", openSite: "fosswire.org openen", language: "Taal", loading: "Nieuws laden…", failed: "Het nieuws kon niet worden geladen.", stale: "Vernieuwen mislukt; het laatste nieuws wordt getoond.", tooltip: "FOSSWire-nieuws" },
  pl: { latest: "Najnowsze wiadomości", refresh: "Odśwież", openSite: "Otwórz fosswire.org", language: "Język", loading: "Wczytywanie wiadomości…", failed: "Nie udało się wczytać wiadomości.", stale: "Nie udało się odświeżyć; wyświetlane są ostatnie wiadomości.", tooltip: "Wiadomości FOSSWire" },
  sv: { latest: "Senaste nytt", refresh: "Uppdatera", openSite: "Öppna fosswire.org", language: "Språk", loading: "Läser in nyheter…", failed: "Det gick inte att läsa in nyheterna.", stale: "Kunde inte uppdatera; visar de senaste nyheterna.", tooltip: "FOSSWire-nyheter" },
  uk: { latest: "Останні новини", refresh: "Оновити", openSite: "Відкрити fosswire.org", language: "Мова", loading: "Завантаження новин…", failed: "Не вдалося завантажити новини.", stale: "Не вдалося оновити; показано останні новини.", tooltip: "Новини FOSSWire" },
  hi: { latest: "ताज़ा समाचार", refresh: "रीफ़्रेश करें", openSite: "fosswire.org खोलें", language: "भाषा", loading: "समाचार लोड हो रहे हैं…", failed: "समाचार लोड नहीं हो सके।", stale: "रीफ़्रेश नहीं हो सका; पिछले समाचार दिखाए जा रहे हैं।", tooltip: "FOSSWire समाचार" }
}

function t(lang, key) {
  var table = STRINGS[lang] || STRINGS.en
  return table[key] || STRINGS.en[key] || key
}
