import QtQuick
import Quickshell
import qs.Commons
import qs.Ui
import "Model.js" as Model
import "Strings.js" as Strings

// Bar entry point: the newspaper glyph and the newest headline. Left click
// opens the news panel, middle click refreshes, right click opens the site.
BarWidget {
  id: root
  moduleName: "org.fosswire.news"

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  readonly property bool showHeadline: setting("showHeadline", true) !== false && !root.vertical
  readonly property int maxChars: Math.max(10, parseInt(setting("maxChars", 42), 10) || 42)
  readonly property string headline: panelLoader.item ? panelLoader.item.headline : ""
  readonly property string lang: panelLoader.item ? panelLoader.item.lang : "en"

  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function toggle() { if (panelLoader.item) panelLoader.item.toggle() }
  function refresh() { if (panelLoader.item) panelLoader.item.refresh() }
  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.showHeadline && root.headline !== ""
      ? "󰎕  " + Model.truncate(root.headline, root.maxChars)
      : "󰎕"
    tooltipText: root.opened ? "" : (root.headline || Strings.t(root.lang, "tooltip"))

    onPressed: function(b) {
      if (b === Qt.MiddleButton) root.refresh()
      else if (b === Qt.RightButton) Quickshell.execDetached(["xdg-open", Model.homeUrl(root.lang)])
      else root.toggle()
    }
  }
}
