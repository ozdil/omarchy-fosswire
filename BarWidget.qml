import QtQuick
import Quickshell
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "Model.js" as Model
import "Strings.js" as Strings

// Bar entry point: the fosswire.org logo, which takes the theme's accent color while
// there is news not yet seen in the panel; hovering shows the newest headline.
// Left click opens the news panel, middle click refreshes, right click opens
// the site. `showHeadline: true` also writes the headline on the bar.
BarWidget {
  id: root
  moduleName: "org.fosswire.news"

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  readonly property bool showHeadline: setting("showHeadline", false) === true && !root.vertical
  readonly property int maxChars: Math.max(10, parseInt(setting("maxChars", 42), 10) || 42)
  readonly property string headline: panelLoader.item ? panelLoader.item.headline : ""
  readonly property string lang: panelLoader.item ? panelLoader.item.lang : "en"
  // The fosswire.org logo by default; the `icon` setting swaps in any text or
  // Nerd Font glyph instead.
  readonly property string mark: String(setting("icon", "logo")) || "logo"
  readonly property bool useLogo: mark === "logo"
  readonly property bool headlineShown: showHeadline && headline !== ""
  readonly property bool unseen: panelLoader.item ? panelLoader.item.unseen === true : false

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
    // With the logo, an em space holds its place in the label.
    text: (root.useLogo ? "\u2003" : root.mark)
      + (root.headlineShown ? "  " + Model.truncate(root.headline, root.maxChars) : "")
    labelVisible: !root.useLogo || root.headlineShown
    fixedWidth: root.useLogo && !root.headlineShown && !root.vertical ? Style.bar.iconSlot : -1
    active: root.unseen
    activeColor: Commons.Color.accent
    tooltipText: root.opened ? "" : (root.headline || Strings.t(root.lang, "tooltip"))

    FossLogo {
      visible: root.useLogo
      // Matches the glyphs around it: newer shells have iconSize, 4.0.4 only iconFont.
      implicitHeight: Math.round((Style.bar.iconSize || Style.bar.iconFont || 13) * 0.92)
      x: root.headlineShown ? button.scaledHorizontalMargin : (button.width - width) / 2
      anchors.verticalCenter: parent.verticalCenter
      color: button.active ? button.activeColor : button.foreground
    }

    onPressed: function(b) {
      if (b === Qt.MiddleButton) root.refresh()
      else if (b === Qt.RightButton) Quickshell.execDetached(["xdg-open", Model.homeUrl()])
      else root.toggle()
    }
  }
}
