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
      property bool wifiEnabled: false
      property date now: new Date()
      property bool panelOpen: false
      property string panelPage: ""
      property string pendingPowerAction: ""
      property var sink: Pipewire.defaultAudioSink
      property var battery: UPower.displayDevice

      readonly property color foreground: "#f4f0e8"
      readonly property color muted: "#aaa9a5"
      readonly property color accent: "#cd974b"
      readonly property color panelBackground: "#211f18"
      readonly property color panelBorder: "#3b3830"

      function togglePanel(page) {
        if (panelOpen && panelPage === page) {
          panelOpen = false
          return
        }
        panelPage = page
        pendingPowerAction = ""
        panelOpen = true
        if (page === "wifi" && !wifiProcess.running) wifiProcess.running = true
      }

      function batteryIcon() {
        if (!battery || !battery.ready) return "󰂑"
        const discharge = ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
        const charge = ["󰢟", "󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"]
        const index = Math.max(0, Math.min(10, Math.round(battery.percentage * 10)))
        const charging = battery.state === UPowerDeviceState.Charging
          || battery.state === UPowerDeviceState.FullyCharged
        return charging ? charge[index] : discharge[index]
      }

      function volumeIcon() {
        if (!sink || !sink.audio || sink.audio.muted) return "󰖁"
        if (sink.audio.volume >= 0.67) return "󰕾"
        if (sink.audio.volume >= 0.34) return "󰖀"
        if (sink.audio.volume > 0) return "󰕿"
        return "󰖁"
      }

      function setVolume(value) {
        if (!sink || !sink.audio) return
        sink.audio.volume = Math.max(0, Math.min(1, value))
      }

      function bluetoothSummary() {
        const devices = Bluetooth.devices ? Bluetooth.devices.values : []
        const names = []
        for (let i = 0; i < devices.length; i++) {
          if (devices[i] && devices[i].connected)
            names.push(devices[i].name || devices[i].deviceName || "Connected device")
        }
        return names.length > 0 ? names.join(", ") : "No devices connected"
      }

      function bluetoothConnected() {
        const devices = Bluetooth.devices ? Bluetooth.devices.values : []
        for (let i = 0; i < devices.length; i++)
          if (devices[i] && devices[i].connected) return true
        return false
      }

      screen: modelData
      anchors.top: true
      anchors.left: true
      anchors.right: true
      implicitHeight: 26
      color: "#181818"

      component PanelRow: Rectangle {
        id: panelRow
        property string icon: ""
        property string label: ""
        property string detail: ""
        property string trailing: ""
        property bool destructive: false
        signal activated()

        width: parent ? parent.width : 0
        height: detail.length > 0 ? 44 : 36
        radius: 6
        color: rowMouse.containsMouse ? "#353229" : "transparent"

        Text {
          id: rowIcon
          anchors.left: parent.left
          anchors.leftMargin: 8
          anchors.verticalCenter: parent.verticalCenter
          width: 22
          horizontalAlignment: Text.AlignHCenter
          text: panelRow.icon
          color: panelRow.destructive ? "#d66a64" : bar.foreground
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 15
        }

        Column {
          anchors.left: rowIcon.right
          anchors.leftMargin: 9
          anchors.right: rowTrailing.left
          anchors.rightMargin: 8
          anchors.verticalCenter: parent.verticalCenter
          spacing: 1

          Text {
            width: parent.width
            text: panelRow.label
            color: panelRow.destructive ? "#d66a64" : bar.foreground
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            elide: Text.ElideRight
          }
          Text {
            visible: panelRow.detail.length > 0
            width: parent.width
            text: panelRow.detail
            color: bar.muted
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 10
            elide: Text.ElideRight
          }
        }

        Text {
          id: rowTrailing
          anchors.right: parent.right
          anchors.rightMargin: 9
          anchors.verticalCenter: parent.verticalCenter
          text: panelRow.trailing
          color: panelRow.destructive ? "#d66a64" : bar.muted
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 11
        }

        MouseArea {
          id: rowMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: panelRow.activated()
        }
      }

      PwObjectTracker {
        objects: [bar.sink]
      }

      Process {
        id: wifiProcess
        running: true
        command: ["sh", "-c", "nmcli radio wifi; nmcli -t -f TYPE,STATE,CONNECTION device | awk -F: '$1 == \"wifi\" && $2 == \"connected\" { print $3; exit }'"]
        stdout: StdioCollector {
          waitForEnd: true
          onStreamFinished: {
            const lines = text.trim().split("\n")
            bar.wifiEnabled = lines.length > 0 && lines[0] === "enabled"
            bar.wifiName = lines.length > 1 ? lines.slice(1).join(":") : ""
          }
        }
      }

      Process {
        id: wifiToggleProcess
        onExited: if (!wifiProcess.running) wifiProcess.running = true
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
            color: modelData.focused ? bar.foreground : "#777777"
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
      }

      Text {
        anchors.centerIn: parent
        text: Qt.formatDateTime(bar.now, "HH:mm")
        color: bar.foreground
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
        font.bold: true
      }

      RowLayout {
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: 3

        Item {
          Layout.preferredWidth: 25
          Layout.fillHeight: true
          Text {
            anchors.centerIn: parent
            text: "󰖩"
            color: bar.wifiName.length > 0 ? bar.foreground : "#666666"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
          }
          Rectangle { anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; width: 14; height: 1; color: bar.accent; visible: bar.panelOpen && bar.panelPage === "wifi" }
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: bar.togglePanel("wifi") }
        }

        Item {
          Layout.preferredWidth: 25
          Layout.fillHeight: true
          Text {
            anchors.centerIn: parent
            text: bar.bluetoothConnected() ? "󰂱" : "󰂯"
            color: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled ? bar.foreground : "#666666"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
          }
          Rectangle { anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; width: 14; height: 1; color: bar.accent; visible: bar.panelOpen && bar.panelPage === "bluetooth" }
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: bar.togglePanel("bluetooth") }
        }

        Item {
          Layout.preferredWidth: 25
          Layout.fillHeight: true
          Text {
            anchors.centerIn: parent
            text: bar.volumeIcon()
            color: bar.foreground
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
          }
          Rectangle { anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; width: 14; height: 1; color: bar.accent; visible: bar.panelOpen && bar.panelPage === "sound" }
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: bar.togglePanel("sound")
            onWheel: event => bar.setVolume((bar.sink && bar.sink.audio ? bar.sink.audio.volume : 0) + (event.angleDelta.y > 0 ? 0.05 : -0.05))
          }
        }

        Item {
          Layout.preferredWidth: 67
          Layout.fillHeight: true
          Text {
            anchors.centerIn: parent
            text: bar.battery && bar.battery.ready ? bar.batteryIcon() + " " + Math.round(bar.battery.percentage * 100) + "%" : "󰂑"
            color: bar.battery && bar.battery.ready && bar.battery.percentage < 0.2 ? "#d66a64" : bar.foreground
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
          }
          Rectangle { anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; width: 30; height: 1; color: bar.accent; visible: bar.panelOpen && bar.panelPage === "power" }
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: bar.togglePanel("power") }
        }

        Item {
          Layout.preferredWidth: 25
          Layout.fillHeight: true
          Text {
            anchors.centerIn: parent
            text: "󰐥"
            color: bar.foreground
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
          }
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: bar.togglePanel("power") }
        }
      }

      PopupWindow {
        id: quickPanel
        visible: bar.panelOpen
        color: "transparent"
        implicitWidth: 310
        implicitHeight: bar.panelPage === "power" ? 300 : bar.panelPage === "sound" ? 190 : 158

        onVisibleChanged: if (!visible) bar.pendingPowerAction = ""

        HyprlandFocusGrab {
          active: bar.panelOpen
          windows: [quickPanel, bar]
          onCleared: bar.panelOpen = false
        }

        anchor {
          window: bar
          adjustment: PopupAdjustment.Slide
          edges: Edges.Top | Edges.Left
          gravity: Edges.Bottom | Edges.Right
          rect.x: bar.width - quickPanel.implicitWidth - 6
          rect.y: bar.height + 4
          rect.width: 1
          rect.height: 1
        }

        Rectangle {
          anchors.fill: parent
          color: bar.panelBackground
          border.color: bar.panelBorder
          border.width: 1
          radius: 10

          Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            Row {
              width: parent.width
              height: 22
              spacing: 9
              Text {
                text: bar.panelPage === "wifi" ? "󰖩" : bar.panelPage === "bluetooth" ? "󰂯" : bar.panelPage === "sound" ? bar.volumeIcon() : bar.batteryIcon()
                color: bar.accent
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 17
                anchors.verticalCenter: parent.verticalCenter
              }
              Text {
                text: bar.panelPage === "wifi" ? "Wi-Fi" : bar.panelPage === "bluetooth" ? "Bluetooth" : bar.panelPage === "sound" ? "Sound" : "Power"
                color: bar.foreground
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
              }
            }

            Rectangle { width: parent.width; height: 1; color: bar.panelBorder }

            Column {
              visible: bar.panelPage === "wifi"
              width: parent.width
              spacing: 4
              PanelRow {
                icon: "󰖩"
                label: "Wi-Fi"
                detail: bar.wifiName.length > 0 ? bar.wifiName : "Not connected"
                trailing: bar.wifiEnabled ? "On" : "Off"
                onActivated: {
                  if (wifiToggleProcess.running) return
                  wifiToggleProcess.command = ["nmcli", "radio", "wifi", bar.wifiEnabled ? "off" : "on"]
                  wifiToggleProcess.running = true
                }
              }
              PanelRow {
                icon: "󰒓"
                label: "Network settings…"
                trailing: "›"
                onActivated: {
                  bar.panelOpen = false
                  Quickshell.execDetached(["nm-connection-editor"])
                }
              }
            }

            Column {
              visible: bar.panelPage === "bluetooth"
              width: parent.width
              spacing: 4
              PanelRow {
                icon: bar.bluetoothConnected() ? "󰂱" : "󰂯"
                label: "Bluetooth"
                detail: bar.bluetoothSummary()
                trailing: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled ? "On" : "Off"
                onActivated: if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
              }
              PanelRow {
                icon: "󰒓"
                label: "Bluetooth settings…"
                trailing: "›"
                onActivated: {
                  bar.panelOpen = false
                  Quickshell.execDetached(["blueman-manager"])
                }
              }
            }

            Column {
              visible: bar.panelPage === "sound"
              width: parent.width
              spacing: 9

              Row {
                width: parent.width
                height: 24
                spacing: 10
                Text {
                  text: bar.volumeIcon()
                  color: bar.foreground
                  font.family: "JetBrainsMono Nerd Font"
                  font.pixelSize: 15
                  anchors.verticalCenter: parent.verticalCenter
                }
                Rectangle {
                  id: volumeTrack
                  width: parent.width - 70
                  height: 6
                  radius: 3
                  color: "#3b3830"
                  anchors.verticalCenter: parent.verticalCenter
                  Rectangle {
                    height: parent.height
                    width: parent.width * Math.max(0, Math.min(1, bar.sink && bar.sink.audio ? bar.sink.audio.volume : 0))
                    radius: parent.radius
                    color: bar.accent
                  }
                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    function apply(mouse) { bar.setVolume(mouse.x / width) }
                    onPressed: mouse => apply(mouse)
                    onPositionChanged: mouse => { if (pressed) apply(mouse) }
                  }
                }
                Text {
                  width: 38
                  horizontalAlignment: Text.AlignRight
                  text: Math.round((bar.sink && bar.sink.audio ? bar.sink.audio.volume : 0) * 100) + "%"
                  color: bar.foreground
                  font.family: "JetBrainsMono Nerd Font"
                  font.pixelSize: 11
                  anchors.verticalCenter: parent.verticalCenter
                }
              }

              PanelRow {
                icon: bar.sink && bar.sink.audio && bar.sink.audio.muted ? "󰖁" : "󰕾"
                label: bar.sink && bar.sink.audio && bar.sink.audio.muted ? "Unmute" : "Mute"
                trailing: ""
                onActivated: if (bar.sink && bar.sink.audio) bar.sink.audio.muted = !bar.sink.audio.muted
              }
              PanelRow {
                icon: "󰒓"
                label: "Audio settings…"
                trailing: "›"
                onActivated: {
                  bar.panelOpen = false
                  Quickshell.execDetached(["pavucontrol"])
                }
              }
            }

            Column {
              visible: bar.panelPage === "power"
              width: parent.width
              spacing: 4

              Item {
                width: parent.width
                height: 47
                Text {
                  anchors.left: parent.left
                  anchors.verticalCenter: parent.verticalCenter
                  text: bar.batteryIcon()
                  color: bar.battery && bar.battery.ready && bar.battery.percentage < 0.2 ? "#d66a64" : bar.foreground
                  font.family: "JetBrainsMono Nerd Font"
                  font.pixelSize: 24
                }
                Column {
                  anchors.left: parent.left
                  anchors.leftMargin: 38
                  anchors.right: batteryPercent.left
                  anchors.rightMargin: 8
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: 4
                  Text {
                    text: bar.battery && bar.battery.ready ? "Battery" : "No battery"
                    color: bar.foreground
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                  }
                  Rectangle {
                    width: parent.width
                    height: 5
                    radius: 3
                    color: bar.panelBorder
                    Rectangle {
                      height: parent.height
                      width: parent.width * Math.max(0, Math.min(1, bar.battery && bar.battery.ready ? bar.battery.percentage : 0))
                      radius: parent.radius
                      color: bar.accent
                    }
                  }
                }
                Text {
                  id: batteryPercent
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  text: bar.battery && bar.battery.ready ? Math.round(bar.battery.percentage * 100) + "%" : "—"
                  color: bar.foreground
                  font.family: "JetBrainsMono Nerd Font"
                  font.pixelSize: 18
                  font.bold: true
                }
              }

              PanelRow {
                icon: "󰌾"
                label: "Lock"
                onActivated: {
                  bar.panelOpen = false
                  Quickshell.execDetached(["swaylock", "-f", "-c", "272727"])
                }
              }
              PanelRow {
                icon: "󰒲"
                label: "Suspend"
                onActivated: {
                  bar.panelOpen = false
                  Quickshell.execDetached(["systemctl", "suspend"])
                }
              }
              PanelRow {
                icon: "󰜉"
                label: bar.pendingPowerAction === "reboot" ? "Click again to restart" : "Restart"
                destructive: bar.pendingPowerAction === "reboot"
                onActivated: {
                  if (bar.pendingPowerAction === "reboot") Quickshell.execDetached(["systemctl", "reboot"])
                  else bar.pendingPowerAction = "reboot"
                }
              }
              PanelRow {
                icon: "󰐥"
                label: bar.pendingPowerAction === "poweroff" ? "Click again to shut down" : "Shut down"
                destructive: bar.pendingPowerAction === "poweroff"
                onActivated: {
                  if (bar.pendingPowerAction === "poweroff") Quickshell.execDetached(["systemctl", "poweroff"])
                  else bar.pendingPowerAction = "poweroff"
                }
              }
            }
          }
        }
      }
    }
  }
}
