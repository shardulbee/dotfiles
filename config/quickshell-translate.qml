import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
  id: root

  property bool darkMode: themeFile.text().trim() !== "light"

  FileView {
    id: themeFile
    path: "/home/shardul/.local/state/sharchy-theme"
    preload: true
    blockLoading: true
    printErrors: false
  }

  PanelWindow {
    visible: true
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: root.darkMode ? "#a614120b" : "#99000000"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    MouseArea {
      anchors.fill: parent
    }

    Rectangle {
      anchors.centerIn: parent
      width: 250
      height: 92
      radius: 12
      color: root.darkMode ? "#211f18" : "#efeee9"
      border.width: 1
      border.color: root.darkMode ? "#3b3830" : "#cecdc7"

      Row {
        anchors.centerIn: parent
        spacing: 16

        Canvas {
          id: spinner
          anchors.verticalCenter: parent.verticalCenter
          width: 28
          height: 28

          onPaint: {
            const context = getContext("2d")
            context.reset()
            context.strokeStyle = "#cd974b"
            context.lineWidth = 3
            context.lineCap = "round"
            context.beginPath()
            context.arc(width / 2, height / 2, 11, 0, Math.PI * 1.45)
            context.stroke()
          }

          RotationAnimator on rotation {
            from: 0
            to: 360
            duration: 750
            loops: Animation.Infinite
            running: true
          }
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "Translating…"
          color: root.darkMode ? "#cecece" : "#26251e"
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 14
          font.bold: true
        }
      }
    }
  }
}
