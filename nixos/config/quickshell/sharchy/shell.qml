import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

ShellRoot {
  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: bar
      required property var modelData
      property string wifiName: ""
      property date now: new Date()

      screen: modelData
      anchors.top: true
      anchors.left: true
      anchors.right: true
      implicitHeight: 26
      color: "#181818"

      PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
      }

      Process {
        id: wifiProcess
        running: true
        command: ["sh", "-c", "nmcli -t -f TYPE,STATE,CONNECTION device | awk -F: '$1 == \"wifi\" && $2 == \"connected\" { print $3; exit }'"]
        stdout: StdioCollector {
          onStreamFinished: bar.wifiName = text.trim()
        }
      }

      Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: if (!wifiProcess.running) wifiProcess.running = true
      }

      Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: bar.now = new Date()
      }

      RowLayout {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 7

        Repeater {
          model: Hyprland.workspaces
          delegate: Text {
            required property var modelData
            visible: modelData.id > 0
            text: modelData.name
            color: modelData.focused ? "#f4f0e8" : "#777777"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            font.bold: modelData.focused

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: parent.modelData.activate()
            }
          }
        }

        Text {
          text: {
            const top = Hyprland.activeToplevel
            if (!top) return ""
            if (top.wayland && top.wayland.title) return "·  " + top.wayland.title
            if (top.lastIpcObject && top.lastIpcObject.title) return "·  " + top.lastIpcObject.title
            return ""
          }
          color: "#999999"
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 11
          elide: Text.ElideRight
          Layout.maximumWidth: 360
        }
      }

      Text {
        anchors.centerIn: parent
        text: Qt.formatDateTime(bar.now, "HH:mm")
        color: "#f4f0e8"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
        font.bold: true
      }

      RowLayout {
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 11

        Text {
          text: "󰖩"
          color: bar.wifiName.length > 0 ? "#f4f0e8" : "#666666"
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 13
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Quickshell.execDetached(["nm-connection-editor"])
          }
        }

        Text {
          text: "󰂯"
          color: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled ? "#f4f0e8" : "#666666"
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 13
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Quickshell.execDetached(["blueman-manager"])
          }
        }

        Text {
          property var sink: Pipewire.defaultAudioSink
          text: sink && sink.audio && sink.audio.muted ? "󰖁" : "󰕾"
          color: "#f4f0e8"
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 13
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Quickshell.execDetached(["pavucontrol"])
            onWheel: event => {
              const audio = parent.sink && parent.sink.audio
              if (!audio) return
              audio.volume = Math.max(0, Math.min(1.5, audio.volume + (event.angleDelta.y > 0 ? 0.05 : -0.05)))
            }
          }
        }

        Text {
          property var battery: UPower.displayDevice
          text: battery && battery.ready ? "󰁹 " + Math.round(battery.percentage * 100) + "%" : "󰂑"
          color: battery && battery.ready && battery.percentage < 0.2 ? "#ff6b6b" : "#f4f0e8"
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 12
        }

        Text {
          text: "󰐥"
          color: "#f4f0e8"
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 13
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Quickshell.execDetached(["wlogout"])
          }
        }
      }
    }
  }
}
