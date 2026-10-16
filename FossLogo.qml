import QtQuick
import QtQuick.Shapes

// The fosswire.org logo mark (web/public/logo.svg) without its tile: the
// wire-drawn F with its two nodes, stroked in one color so it follows the bar
// theme like any other glyph. Coordinates are the logo's own 512-unit grid,
// cropped to the mark; the strokes are about a quarter heavier than the logo's
// so the thin wire holds its own beside the bar's solid glyphs.
Item {
  id: root

  property color color: "white"

  // The mark's bounds in logo units, strokes included.
  readonly property real markWidth: 264
  readonly property real markHeight: 326
  readonly property real unit: height / markHeight

  implicitHeight: 16
  implicitWidth: Math.round(implicitHeight * markWidth / markHeight)

  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      strokeColor: root.color
      strokeWidth: 56 * root.unit
      fillColor: "transparent"
      capStyle: ShapePath.RoundCap
      joinStyle: ShapePath.RoundJoin
      scale: Qt.size(root.unit, root.unit)
      PathSvg { path: "M32 298V50h150 M32 168h96" }
    }

    ShapePath {
      strokeColor: root.color
      strokeWidth: 36 * root.unit
      fillColor: "transparent"
      scale: Qt.size(root.unit, root.unit)
      PathSvg { path: "M242 50a30 30 0 1 0 -60 0a30 30 0 1 0 60 0 M188 168a30 30 0 1 0 -60 0a30 30 0 1 0 60 0" }
    }
  }
}
