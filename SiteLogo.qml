import QtQuick
import QtQuick.Shapes

// The fosswire.org logo exactly as the site shows it (web/public/logo.svg):
// the white wire-drawn F with its two nodes on the blue rounded tile. Drawn
// on the logo's own 512-unit grid, so it stays sharp at any size.
Item {
  id: root

  readonly property color tile: "#0969da"
  readonly property real unit: height / 512

  implicitHeight: 20
  implicitWidth: implicitHeight

  Rectangle {
    anchors.fill: parent
    radius: 112 * root.unit
    color: root.tile
  }

  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      strokeColor: "#ffffff"
      strokeWidth: 44 * root.unit
      fillColor: "transparent"
      capStyle: ShapePath.RoundCap
      joinStyle: ShapePath.RoundJoin
      scale: Qt.size(root.unit, root.unit)
      PathSvg { path: "M176 392V144h150 M176 262h96" }
    }

    ShapePath {
      strokeColor: "#ffffff"
      strokeWidth: 28 * root.unit
      fillColor: root.tile
      scale: Qt.size(root.unit, root.unit)
      PathSvg { path: "M386 144a30 30 0 1 0 -60 0a30 30 0 1 0 60 0 M332 262a30 30 0 1 0 -60 0a30 30 0 1 0 60 0" }
    }
  }
}
