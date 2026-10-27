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
  property string seenAt: ""
  // A display language set explicitly in Omarchy, where the shell has one.
  // Not I18n.currentLocale: Omarchy only ships English and Turkish, so it
  // reports "en" on, say, a German PC.
  readonly property string shellLanguage: {
    var i18n = Commons.I18n
    return (i18n && i18n.configuredLocale) || ""
  }
  // The PC's language from its locale (LANGUAGE, LC_ALL, LC_MESSAGES, LANG),
  // else Qt's idea of it.
  readonly property string pcLanguage: Model.systemLanguage({
    LANGUAGE: Quickshell.env("LANGUAGE"),
    LC_ALL: Quickshell.env("LC_ALL"),
    LC_MESSAGES: Quickshell.env("LC_MESSAGES"),
    LANG: Quickshell.env("LANG")
  }) || Model.languageFromLocale(Qt.locale().name)
  readonly property string lang: Model.pickLanguage(savedLanguage, setting("language", "auto"), shellLanguage, pcLanguage)
  readonly property bool rightToLeft: Model.isRightToLeft(lang)

  function tr(key) { return Strings.t(root.lang, key) }

  // ---- Data. The last good copy stays on screen when a refresh fails.
  property var feed: null
  property var securityData: null
  property var items: []
  property var advisories: []
  property bool loading: false
  property bool failed: false

  property int cursor: -1
  property bool pickingLanguage: false
  property bool showingAbout: false
  property bool showingCve: false

  // Shown on the bar: the newest headline.
  readonly property string headline: items.length ? items[0].title : ""
  // Stories newer than the newest one seen in the panel: the bar glyph lights up.
  readonly property bool unseen: Model.hasUnseen(items, seenAt)

  readonly property color fg: root.barForeground
  readonly property color dim: Qt.darker(root.barForeground, 1.4)
  readonly property string fontFamily: (root.bar && root.bar.fontFamily) || (Style.font && Style.font.family) || "JetBrainsMono Nerd Font"

  function open() {
    root.pickingLanguage = false
    root.showingAbout = false
    var activeList = root.showingCve ? root.advisories : root.items
    root.cursor = activeList.length ? 0 : -1
    root.controller.show()
    if (root.unseen) {
      root.seenAt = root.items[0].publishedAt
      root.saveState()
    }
  }

  function close() {
    root.pickingLanguage = false
    root.showingAbout = false
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
    root.items = Model.buildItems(root.feed, root.count)
    root.advisories = Model.buildAdvisories(root.securityData, root.count)
    var activeList = root.showingCve ? root.advisories : root.items
    if (root.cursor >= activeList.length) root.cursor = activeList.length - 1
  }

  function refresh() {
    root.loading = true
    if (!feedProc.running) feedProc.running = true
    if (!securityProc.running) securityProc.running = true
  }


  function setLanguage(lang) {
    if (!Model.isLanguage(lang)) return
    root.savedLanguage = lang
    root.saveState()
  }

  function saveState() {
    saveProc.command = ["sh", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" > \"$1\"", "sh",
      root.statePath, Model.serializeState(root.savedLanguage, root.seenAt)]
    saveProc.running = true
  }

  function openUrl(url) {
    if (!url) return
    Quickshell.execDetached(["xdg-open", url])
    root.close()
  }

  function openItem(index) {
    var activeList = root.showingCve ? root.advisories : root.items
    if (index >= 0 && index < activeList.length) root.openUrl(activeList[index].url)
  }

  function moveCursor(dy) {
    var activeList = root.showingCve ? root.advisories : root.items
    if (!activeList.length) return
    var next = root.cursor < 0 ? 0 : root.cursor + dy
    root.cursor = Math.max(0, Math.min(activeList.length - 1, next))
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

  onLangChanged: rebuild()
  onCountChanged: rebuild()
  onShowingCveChanged: {
    var activeList = root.showingCve ? root.advisories : root.items
    root.cursor = activeList.length ? 0 : -1
  }

  readonly property string statePath: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state"))
    + "/omarchy/settings/fosswire.json"

  FileView {
    id: stateFile
    path: root.statePath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      var state = Model.parseState(text())
      root.savedLanguage = state.language
      root.seenAt = state.seenAt
    }
    onLoadFailed: {
      root.savedLanguage = ""
      root.seenAt = ""
    }
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
    id: securityProc
    command: ["curl", "-fsS", "--compressed", "--max-time", "15", Model.securityUrl()]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var parsed = Model.parseObject(text)
        if (!parsed || !Array.isArray(parsed.advisories)) return
        root.securityData = parsed
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
    contentHeight: panel.fittedContentHeight(root.showingAbout ? about.implicitHeight : body.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      LayoutMirroring.enabled: root.rightToLeft
      LayoutMirroring.childrenInherit: true

      onCloseRequested: {
        if (root.showingAbout) root.showingAbout = false
        else if (root.pickingLanguage) root.pickingLanguage = false
        else root.close()
      }
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onMoveRequested: function(dx, dy) {
        if (root.showingAbout) return
        if (root.pickingLanguage && dx !== 0) root.setLanguage(Model.cycleLanguage(root.lang, dx))
        else if (dy !== 0) root.moveCursor(dy)
      }
      onActivateRequested: {
        if (root.showingAbout) return
        if (root.pickingLanguage) root.pickingLanguage = false
        else root.openItem(root.cursor)
      }
      onTextKey: function(text, modifiers) {
        if (text === "r") root.refresh()
        else if (text === "o") root.openUrl(root.showingCve ? Model.securityPageUrl() : Model.homeUrl())
        else if (text === "c") root.showingCve = !root.showingCve
        else if (text === "L") root.pickingLanguage = !root.pickingLanguage
        else if (text === "a") root.showingAbout = !root.showingAbout
      }

      // ---- About: version, developer, license and support links, read from manifest.json.
      AboutCard {
        id: about
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        visible: root.showingAbout
        manifestUrl: Qt.resolvedUrl("manifest.json")
        repoUrl: Model.REPO_URL
        foreground: root.fg
        accent: Commons.Color.accent
        fontFamily: root.fontFamily
        labels: Strings.table(root.lang)
        description: root.tr("description")
        onCloseRequested: root.showingAbout = false
      }

      Flickable {
        id: scroll
        anchors.fill: parent
        visible: !root.showingAbout
        contentWidth: width
        contentHeight: body.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        Column {
          id: body
          width: scroll.width
          spacing: Style.space(10)

          // ---- Header: the site logo and name, then CVE Radar, about, language, refresh.
          Item {
            width: parent.width
            implicitHeight: Math.max(brand.implicitHeight, actions.implicitHeight)

            readonly property real buttonSize: Style.space(30)

            Row {
              id: brand
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(10)

              SiteLogo {
                anchors.verticalCenter: parent.verticalCenter
                implicitHeight: Math.round(brandName.implicitHeight * 1.15)
              }

              Text {
                id: brandName
                anchors.verticalCenter: parent.verticalCenter
                textFormat: Text.PlainText
                text: "FOSSWIRE"
                color: Commons.Color.accent
                font.family: root.fontFamily
                font.pixelSize: Style.font.title
                font.bold: true
                font.letterSpacing: 1
              }
            }

            Row {
              id: actions
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.spacing.labelGap

              PanelActionButton {
                anchors.verticalCenter: parent.verticalCenter
                size: parent.parent.buttonSize
                iconText: "󰒃"
                tooltipText: root.tr("cveRadar")
                foreground: root.showingCve ? Commons.Color.accent : root.fg
                fontFamily: root.fontFamily
                onClicked: root.showingCve = !root.showingCve
              }

              PanelActionButton {
                anchors.verticalCenter: parent.verticalCenter
                size: parent.parent.buttonSize
                iconText: "󰋽"
                tooltipText: root.tr("about")
                foreground: root.fg
                fontFamily: root.fontFamily
                onClicked: root.showingAbout = true
              }

              PanelActionButton {
                anchors.verticalCenter: parent.verticalCenter
                size: parent.parent.buttonSize
                iconText: root.lang.toUpperCase()
                tooltipText: root.tr("language")
                foreground: root.fg
                fontFamily: root.fontFamily
                fontSize: Style.font.bodySmall
                onClicked: root.pickingLanguage = !root.pickingLanguage
              }

              PanelActionButton {
                anchors.verticalCenter: parent.verticalCenter
                size: parent.parent.buttonSize
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
            text: root.tr(root.showingCve ? "cveRadar" : "latest").toUpperCase()
            foreground: root.fg
            fontFamily: root.fontFamily
          }

          Text {
            visible: !root.showingCve && (root.loading && !root.items.length || root.failed)
            width: parent.width
            textFormat: Text.PlainText
            wrapMode: Text.WordWrap
            text: root.failed ? root.tr(root.items.length ? "stale" : "failed") : root.tr("loading")
            color: root.failed ? Commons.Color.urgent : root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }

          // ---- CVE Radar advisories.
          Column {
            visible: root.showingCve
            width: parent.width
            spacing: Style.space(2)

            Repeater {
              model: root.advisories

              CursorSurface {
                id: cveRow
                required property var modelData
                required property int index
                readonly property bool selected: index === root.cursor

                width: parent.width
                implicitHeight: cveRowText.implicitHeight + Style.spacing.rowPaddingX
                foreground: root.fg
                hasCursor: selected

                Column {
                  id: cveRowText
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.leftMargin: Style.spacing.rowPaddingX
                  anchors.rightMargin: Style.spacing.rowPaddingX
                  spacing: Style.space(3)

                  Text {
                    width: parent.width
                    textFormat: Text.PlainText
                    text: "[" + cveRow.modelData.severity + "] " + cveRow.modelData.cveId + " · " + cveRow.modelData.title
                    color: cveRow.modelData.severity === "CRITICAL" ? Commons.Color.urgent : root.fg
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    font.bold: cveRow.modelData.severity === "CRITICAL" || cveRow.index === 0
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                  }

                  Text {
                    visible: cveRow.selected && cveRow.modelData.summary !== ""
                    width: parent.width
                    textFormat: Text.PlainText
                    text: cveRow.modelData.summary
                    color: root.fg
                    opacity: 0.85
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    wrapMode: Text.WordWrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                  }

                  Text {
                    width: parent.width
                    textFormat: Text.PlainText
                    text: [cveRow.modelData.product, root.formatWhen(cveRow.modelData.publishedAt)].filter(Boolean).join("  ·  ")
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
                  onEntered: root.cursor = cveRow.index
                  onClicked: root.openItem(cveRow.index)
                }
              }
            }
          }

          // ---- Headlines. The highlighted one also shows its takeaway.
          Column {
            visible: !root.showingCve
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
              text: "󰖟  " + (root.showingCve ? root.tr("cveRadar") : root.tr("openSite"))
              color: root.fg
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
            }

            MouseArea {
              id: siteMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.openUrl(root.showingCve ? Model.securityPageUrl() : Model.homeUrl())
            }
          }
        }
      }
    }
  }
}
