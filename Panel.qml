import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "Model.js" as Model
import "Strings.js" as Strings

// The news panel and the data behind the bar label. BarWidget.qml loads this
// file and forwards the bar lifecycle to it, the way Omarchy's own weather
// widget does.
Panel {
  id: root
  moduleName: "org.fosswire.news"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  // ---- Settings (inline on the shell.json bar entry) and the saved language.
  readonly property int count: Math.max(3, Math.min(30, parseInt(setting("count", 12), 10) || 12))
  readonly property int refreshMinutes: Math.max(5, parseInt(setting("refreshMinutes", 30), 10) || 30)
  property string savedLanguage: ""
  // Omarchy's display language where the shell has the I18n singleton (newer
  // releases), else the system locale ($LANG, e.g. tr_TR.UTF-8).
  readonly property string shellLanguage: {
    var i18n = Commons.I18n
    return (i18n && (i18n.language || i18n.currentLocale)) || Quickshell.env("LANG") || ""
  }
  readonly property string lang: Model.pickLanguage(savedLanguage, setting("language", "auto"), shellLanguage)
  readonly property bool rightToLeft: Model.isRightToLeft(lang)

  function tr(key) { return Strings.t(root.lang, key) }

  // ---- Data. The last good copy stays on screen when a refresh fails.
  property var feed: null
  property var titlesByLang: ({})
  property var takeawaysByLang: ({})
  property var items: []
  property bool loading: false
  property bool failed: false

  property int cursor: -1
  property bool pickingLanguage: false

  // Shown on the bar: the newest headline.
  readonly property string headline: items.length ? items[0].title : ""

  readonly property color fg: root.barForeground
  readonly property color dim: Qt.darker(root.barForeground, 1.4)
  readonly property string fontFamily: root.bar ? root.bar.fontFamily : Style.font.family

  function open() {
    root.pickingLanguage = false
    root.cursor = root.items.length ? 0 : -1
    root.controller.show()
  }

  function close() {
    root.pickingLanguage = false
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function rebuild() {
    root.items = Model.buildItems(root.feed, root.titlesByLang[root.lang], root.takeawaysByLang[root.lang], root.lang, root.count)
    if (root.cursor >= root.items.length) root.cursor = root.items.length - 1
  }

  function refresh() {
    root.loading = true
    if (!feedProc.running) feedProc.running = true
    fetchTranslations(true)
  }

  // English needs nothing beyond the feed. Other languages load their titles
  // and takeaways once per session, and again on each full refresh.
  function fetchTranslations(force) {
    var lang = root.lang
    if (lang === "en") return
    if (force || !root.titlesByLang[lang]) {
      titlesProc.lang = lang
      titlesProc.command = ["curl", "-fsS", "--compressed", "--max-time", "15", Model.titlesUrl(lang)]
      titlesProc.running = true
    }
    if (force || !root.takeawaysByLang[lang]) {
      takeawaysProc.lang = lang
      takeawaysProc.command = ["curl", "-fsS", "--compressed", "--max-time", "15", Model.takeawaysUrl(lang)]
      takeawaysProc.running = true
    }
  }

  function setLanguage(lang) {
    if (!Model.isLanguage(lang)) return
    root.savedLanguage = lang
    saveProc.command = ["sh", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" > \"$1\"", "sh",
      root.statePath, Model.serializeState(lang)]
    saveProc.running = true
  }

  function openUrl(url) {
    if (!url) return
    Quickshell.execDetached(["xdg-open", url])
    root.close()
  }

  function openItem(index) {
    if (index >= 0 && index < root.items.length) root.openUrl(root.items[index].url)
  }

  function moveCursor(dy) {
    if (!root.items.length) return
    var next = root.cursor < 0 ? 0 : root.cursor + dy
    root.cursor = Math.max(0, Math.min(root.items.length - 1, next))
  }

  // Today's stories show their time; older ones their date, in the reading
  // language's own month names.
  function formatWhen(iso) {
    var date = new Date(iso)
    if (isNaN(date.getTime())) return ""
    var now = new Date()
    if (date.toDateString() === now.toDateString()) return Qt.formatTime(date, "HH:mm")
    return date.toLocaleDateString(Qt.locale(root.lang), "d MMM")
  }

  onLangChanged: {
    rebuild()
    fetchTranslations(false)
  }
  onCountChanged: rebuild()

  readonly property string statePath: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state"))
    + "/omarchy/settings/fosswire.json"

  FileView {
    id: stateFile
    path: root.statePath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.savedLanguage = Model.parseState(text()).language
    onLoadFailed: root.savedLanguage = ""
  }

  Process {
    id: saveProc
    onExited: stateFile.reload()
  }

  Process {
    id: feedProc
    command: ["curl", "-fsS", "--compressed", "--max-time", "15", Model.feedUrl()]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var parsed = Model.parseObject(text)
        root.loading = false
        if (!parsed || !Array.isArray(parsed.articles)) {
          root.failed = true
          return
        }
        root.feed = parsed
        root.failed = false
        root.rebuild()
      }
    }
  }

  Process {
    id: titlesProc
    property string lang: ""
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var parsed = Model.parseObject(text)
        if (!parsed) return
        var next = Object.assign({}, root.titlesByLang)
        next[titlesProc.lang] = parsed
        root.titlesByLang = next
        root.rebuild()
      }
    }
  }

  Process {
    id: takeawaysProc
    property string lang: ""
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var parsed = Model.parseObject(text)
        if (!parsed) return
        var next = Object.assign({}, root.takeawaysByLang)
        next[takeawaysProc.lang] = parsed
        root.takeawaysByLang = next
        root.rebuild()
      }
    }
  }

  Timer {
    interval: root.refreshMinutes * 60 * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(460))
    contentHeight: panel.fittedContentHeight(body.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      LayoutMirroring.enabled: root.rightToLeft
      LayoutMirroring.childrenInherit: true

      onCloseRequested: {
        if (root.pickingLanguage) root.pickingLanguage = false
        else root.close()
      }
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onMoveRequested: function(dx, dy) {
        if (root.pickingLanguage && dx !== 0) root.setLanguage(Model.cycleLanguage(root.lang, dx))
        else if (dy !== 0) root.moveCursor(dy)
      }
      onActivateRequested: {
        if (root.pickingLanguage) root.pickingLanguage = false
        else root.openItem(root.cursor)
      }
      onTextKey: function(text, modifiers) {
        if (text === "r") root.refresh()
        else if (text === "o") root.openUrl(Model.homeUrl(root.lang))
        else if (text === "L") root.pickingLanguage = !root.pickingLanguage
      }

      Flickable {
        id: scroll
        anchors.fill: parent
        contentWidth: width
        contentHeight: body.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        Column {
          id: body
          width: scroll.width
          spacing: Style.space(10)

          // ---- Header: name, language, refresh.
          Item {
            width: parent.width
            implicitHeight: Math.max(brand.implicitHeight, actions.implicitHeight)

            Text {
              id: brand
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              textFormat: Text.PlainText
              text: "󰎕  FOSSWIRE"
              color: Commons.Color.accent
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
              font.letterSpacing: 1
            }

            Row {
              id: actions
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.spacing.labelGap

              PanelActionButton {
                iconText: root.lang.toUpperCase()
                tooltipText: root.tr("language")
                foreground: root.fg
                fontFamily: root.fontFamily
                fontSize: Style.font.bodySmall
                size: Style.space(30)
                onClicked: root.pickingLanguage = !root.pickingLanguage
              }

              PanelActionButton {
                iconText: "󰑐"
                tooltipText: root.tr("refresh")
                foreground: root.fg
                fontFamily: root.fontFamily
                enabled: !root.loading
                onClicked: root.refresh()
              }
            }
          }

          // ---- Language picker: every site language by its own name.
          Flow {
            visible: root.pickingLanguage
            width: parent.width
            spacing: Style.space(6)

            Repeater {
              model: Model.LANGUAGES

              CursorSurface {
                required property string modelData
                foreground: root.fg
                current: modelData === root.lang
                hasCursor: chipMouse.containsMouse
                implicitWidth: chipLabel.implicitWidth + Style.spacing.controlPaddingX * 2
                implicitHeight: chipLabel.implicitHeight + Style.spacing.controlPaddingY * 2

                Text {
                  id: chipLabel
                  anchors.centerIn: parent
                  textFormat: Text.PlainText
                  text: Model.LANGUAGE_NAMES[modelData]
                  color: root.fg
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                }

                MouseArea {
                  id: chipMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    root.setLanguage(modelData)
                    root.pickingLanguage = false
                  }
                }
              }
            }
          }

          PanelSeparator { foreground: root.fg }

          PanelSectionHeader {
            text: root.tr("latest").toUpperCase()
            foreground: root.fg
            fontFamily: root.fontFamily
          }

          Text {
            visible: root.loading && !root.items.length || root.failed
            width: parent.width
            textFormat: Text.PlainText
            wrapMode: Text.WordWrap
            text: root.failed ? root.tr(root.items.length ? "stale" : "failed") : root.tr("loading")
            color: root.failed ? Commons.Color.urgent : root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }

          // ---- Headlines. The highlighted one also shows its takeaway.
          Column {
            width: parent.width
            spacing: Style.space(2)

            Repeater {
              model: root.items

              CursorSurface {
                id: row
                required property var modelData
                required property int index
                readonly property bool selected: index === root.cursor

                width: parent.width
                implicitHeight: rowText.implicitHeight + Style.spacing.rowPaddingX
                foreground: root.fg
                hasCursor: selected

                Column {
                  id: rowText
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.leftMargin: Style.spacing.rowPaddingX
                  anchors.rightMargin: Style.spacing.rowPaddingX
                  spacing: Style.space(3)

                  Text {
                    width: parent.width
                    textFormat: Text.PlainText
                    text: row.modelData.title
                    color: root.fg
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    font.bold: row.index === 0
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                  }

                  Text {
                    visible: row.selected && row.modelData.takeaway !== ""
                    width: parent.width
                    textFormat: Text.PlainText
                    text: row.modelData.takeaway
                    color: root.fg
                    opacity: 0.85
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    wrapMode: Text.WordWrap
                    maximumLineCount: 4
                    elide: Text.ElideRight
                  }

                  Text {
                    width: parent.width
                    textFormat: Text.PlainText
                    text: [row.modelData.source, root.formatWhen(row.modelData.publishedAt)].filter(Boolean).join("  ·  ")
                    color: root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    elide: Text.ElideRight
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onEntered: root.cursor = row.index
                  onClicked: root.openItem(row.index)
                }

                onSelectedChanged: if (selected) Qt.callLater(function() {
                  var top = row.mapToItem(body, 0, 0).y
                  if (top < scroll.contentY) scroll.contentY = top
                  else if (top + row.height > scroll.contentY + scroll.height)
                    scroll.contentY = Math.min(top + row.height - scroll.height, scroll.contentHeight - scroll.height)
                })
              }
            }
          }

          PanelSeparator { foreground: root.fg }

          CursorSurface {
            width: parent.width
            implicitHeight: siteLabel.implicitHeight + Style.spacing.rowPaddingX
            foreground: root.fg
            hasCursor: siteMouse.containsMouse

            Text {
              id: siteLabel
              anchors.left: parent.left
              anchors.leftMargin: Style.spacing.rowPaddingX
              anchors.verticalCenter: parent.verticalCenter
              textFormat: Text.PlainText
              text: "󰖟  " + root.tr("openSite")
              color: root.fg
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
            }

            MouseArea {
              id: siteMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.openUrl(Model.homeUrl(root.lang))
            }
          }
        }
      }
    }
  }
}
