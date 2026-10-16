import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// The standard About card for ozdil's Omarchy plugins. Name, version, author,
// license and description come from the plugin's own manifest.json, so the card
// never drifts from the release; the panel only passes its colors, font, the
// links and (optionally) translated labels.
//
// Drop-in use, inside a panel's PanelKeyCatcher:
//
//   AboutCard {
//     id: about
//     anchors.fill: parent
//     visible: root.showingAbout
//     manifestUrl: Qt.resolvedUrl("manifest.json")
//     repoUrl: "https://github.com/ozdil/omarchy-example"
//     foreground: root.fg
//     fontFamily: root.fontFamily
//     onCloseRequested: root.showingAbout = false
//   }
//
// The panel toggles it with an 󰋽 header button and the `a` key, and Esc closes
// it before it closes the panel. Size the panel with about.implicitHeight while
// it is shown.
Item {
  id: root

  property url manifestUrl
  property string repoUrl: ""
  property string sponsorUrl: "https://github.com/sponsors/ozdil"
  property string coffeeUrl: "https://buymeacoffee.com/ozdil"

  property color foreground: Commons.Color.foreground
  property color accent: Commons.Color.accent
  property string fontFamily: Style.font.family

  // Labels in the panel's language; any key left out falls back to English.
  property var labels: ({})
  readonly property var english: ({
    about: "About", version: "Version", developer: "Developer", license: "License",
    source: "Source code", sponsor: "Sponsor on GitHub", coffee: "Buy Me a Coffee", close: "Close"
  })
  function label(key) { return root.labels[key] || root.english[key] }

  // Overrides the manifest description, e.g. with a translated one.
  property string description: ""

  property var manifest: ({})
  readonly property string name: manifest.name || ""
  readonly property string version: manifest.version || ""
  readonly property string author: manifest.author || ""
  readonly property string license: manifest.license || ""
  readonly property bool verified: manifest.verified === true

  signal closeRequested()

  function openUrl(url) {
    if (url) Qt.openUrlExternally(url)
  }

  implicitHeight: card.implicitHeight

  FileView {
    path: String(root.manifestUrl).replace(/^file:\/\//, "")
    printErrors: false
    onLoaded: {
      try { root.manifest = JSON.parse(text()) || {} } catch (e) { root.manifest = {} }
    }
  }

  Column {
    id: card
    width: parent.width
    spacing: Style.space(12)

    // ---- Title: name, version, the verified mark, close.
    Item {
      width: parent.width
      implicitHeight: Math.max(title.implicitHeight, closeButton.implicitHeight)

      Row {
        id: title
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(8)

        Text {
          anchors.verticalCenter: parent.verticalCenter
          textFormat: Text.PlainText
          text: root.name
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.title
          font.bold: true
        }

        Rectangle {
          visible: root.verified
          anchors.verticalCenter: parent.verticalCenter
          implicitWidth: verifiedText.implicitWidth + Style.space(8)
          implicitHeight: verifiedText.implicitHeight + Style.space(4)
          radius: Style.space(4)
          color: Qt.rgba(0.13, 0.77, 0.37, 0.18)
          border.color: "#22c55e"
          border.width: 1

          Text {
            id: verifiedText
            anchors.centerIn: parent
            textFormat: Text.PlainText
            text: "VERIFIED"
            color: "#22c55e"
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption - 2
            font.bold: true
          }
        }
      }

      Button {
        id: closeButton
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: "󰅖"
        tooltipText: root.label("close")
        bordered: true
        foreground: root.foreground
        accent: root.accent
        fontFamily: root.fontFamily
        fontSize: Style.font.caption
        onClicked: root.closeRequested()
      }
    }

    // ---- Facts, aligned in two columns.
    Grid {
      columns: 2
      columnSpacing: Style.space(12)
      rowSpacing: Style.space(4)

      Repeater {
        // Label, value, label, value...
        model: [
          root.label("version"), root.version,
          root.label("developer"), root.author,
          root.label("license"), root.license
        ]

        delegate: Text {
          required property var modelData
          required property int index
          textFormat: Text.PlainText
          text: modelData
          color: root.foreground
          opacity: index % 2 ? 0.95 : 0.6
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
      }
    }

    Text {
      width: parent.width
      textFormat: Text.PlainText
      wrapMode: Text.WordWrap
      text: root.description || root.manifest.description || ""
      color: root.foreground
      opacity: 0.85
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      lineHeight: 1.3
    }

    PanelSeparator { width: parent.width; foreground: root.foreground }

    // ---- Links: the code, then the two ways to support the work.
    Button {
      width: parent.width
      visible: root.repoUrl !== ""
      text: root.label("source")
      iconText: "󰊤"
      tooltipText: root.repoUrl.replace(/^https:\/\//, "")
      bordered: true
      foreground: root.foreground
      accent: root.accent
      fontFamily: root.fontFamily
      fontSize: Style.font.caption
      onClicked: root.openUrl(root.repoUrl)
    }

    Button {
      width: parent.width
      text: root.label("sponsor")
      iconText: "󰋑"
      tooltipText: root.sponsorUrl.replace(/^https:\/\//, "")
      bordered: true
      foreground: "#ea4aaa"
      accent: "#ea4aaa"
      fontFamily: root.fontFamily
      fontSize: Style.font.caption
      onClicked: root.openUrl(root.sponsorUrl)
    }

    Button {
      width: parent.width
      text: root.label("coffee")
      iconText: "󰅶"
      tooltipText: root.coffeeUrl.replace(/^https:\/\//, "")
      foreground: "#000000"
      accent: "#000000"
      // Only properties every Omarchy 4.x Button has: a fixed fill, no hover tint.
      color: "#FFDD00"
      fontFamily: root.fontFamily
      fontSize: Style.font.caption
      onClicked: root.openUrl(root.coffeeUrl)
    }
  }
}
