import QtQuick
import QtQuick.Shapes

// The fosswire.org logo mark (web/public/logo.svg) without its tile: the
// wire-drawn F with its two nodes, stroked in one color so it follows the bar
// theme like any other glyph. Coordinates are the logo's own 512-unit grid,
// cropped to the mark.
Item {
  id: root

  property color color: "white"

  // The mark's bounds in logo units, strokes included.
  readonly property real markWidth: 252
  readonly property real markHeight: 314
  readonly property real unit: height / markHeight

  implicitHeight: 16
  implicitWidth: Math.round(implicitHeight * markWidth / markHeight)

  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      strokeColor: root.color
      strokeWidth: 44 * root.unit
      fillColor: "transparent"
      capStyle: ShapePath.RoundCap
      joinStyle: ShapePath.RoundJoin
      scale: Qt.size(root.unit, root.unit)
      PathSvg { path: "M26 292V44h150 M26 162h96" }
    }

    ShapePath {
      strokeColor: root.color
      strokeWidth: 28 * root.unit
      fillColor: "transparent"
      scale: Qt.size(root.unit, root.unit)
      PathSvg { path: "M236 44a30 30 0 1 0 -60 0a30 30 0 1 0 60 0 M182 162a30 30 0 1 0 -60 0a30 30 0 1 0 60 0" }
    }
  }
}
