import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Polkit
import Quickshell.Services.UPower
import Quickshell.Wayland

ShellRoot {
  id: shellRoot

  property bool darkMode: themeFile.text().trim() !== "light"
  property string rebuildStatus: rebuildFile.text().trim()
  readonly property color authBackground: darkMode ? "#1b1913" : "#efeee9"
  readonly property color authField: darkMode ? "#14120b" : "#f7f7f4"
  readonly property color authBorder: darkMode ? "#2b2923" : "#cecdc7"
  readonly property color authText: darkMode ? "#cecece" : "#26251e"
  readonly property color authMuted: darkMode ? "#999999" : "#57564f"
  readonly property color authPlaceholder: darkMode ? "#6f716c" : "#77756e"
  readonly property color authSelection: darkMode ? "#3a382f" : "#f4edd7"
  readonly property color authError: darkMode ? "#d66a64" : "#aa3731"
  readonly property color authAccentHover: darkMode ? "#d5b773" : "#cb9000"

  FileView {
    id: themeFile
    path: "/home/shardul/.local/state/sharchy-theme"
    preload: true
    blockLoading: true
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
  }

  FileView {
    id: rebuildFile
    path: "/home/shardul/.local/state/sharchy-rebuild-status"
    preload: true
    blockLoading: true
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
  }

  PolkitAgent {
    id: polkitAgent
  }

  PanelWindow {
    id: authWindow
    visible: polkitAgent.isActive
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: shellRoot.darkMode ? "#cc14120b" : "#ccf7f7f4"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    function submitPassword() {
      if (!polkitAgent.flow || !polkitAgent.flow.isResponseRequired) return
      polkitAgent.flow.submit(passwordInput.text)
      passwordInput.text = ""
      passwordInput.forceActiveFocus()
    }

    onVisibleChanged: {
      passwordInput.text = ""
      if (visible) passwordInput.forceActiveFocus()
    }

    Rectangle {
      anchors.centerIn: parent
      width: 420
      height: 300
      radius: 12
      color: shellRoot.authBackground
      border.width: 1
      border.color: shellRoot.authBorder

      Column {
        anchors.fill: parent
        anchors.margins: 30
        spacing: 14

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: "󰌾"
          color: "#cd974b"
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 30
        }

        Text {
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          text: "Authentication required"
          color: shellRoot.authText
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 17
          font.bold: true
        }

        Text {
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          text: polkitAgent.flow?.message || "Enter your password to continue"
          color: shellRoot.authMuted
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 11
          wrapMode: Text.Wrap
          maximumLineCount: 2
          elide: Text.ElideRight
        }

        Rectangle {
          width: parent.width
          height: 48
          radius: 8
          color: shellRoot.authField
          border.width: passwordInput.activeFocus ? 2 : 1
          border.color: polkitAgent.flow?.failed ? shellRoot.authError : (passwordInput.activeFocus ? "#cd974b" : shellRoot.authBorder)

          TextInput {
            id: passwordInput
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            verticalAlignment: TextInput.AlignVCenter
            color: shellRoot.authText
            selectionColor: shellRoot.authSelection
            selectedTextColor: shellRoot.authText
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            echoMode: polkitAgent.flow?.responseVisible ? TextInput.Normal : TextInput.Password
            enabled: !!polkitAgent.flow?.isResponseRequired
            focus: authWindow.visible
            onAccepted: authWindow.submitPassword()

            Keys.onEscapePressed: {
              if (polkitAgent.flow) polkitAgent.flow.cancelAuthenticationRequest()
            }
          }

          Text {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            visible: passwordInput.text.length === 0 && !passwordInput.activeFocus
            text: polkitAgent.flow?.inputPrompt || "Password"
            color: shellRoot.authPlaceholder
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
          }
        }

        Text {
          width: parent.width
          height: 16
          horizontalAlignment: Text.AlignHCenter
          text: polkitAgent.flow?.failed ? "Authentication failed" : (polkitAgent.flow?.supplementaryMessage || "")
          color: polkitAgent.flow?.failed || polkitAgent.flow?.supplementaryIsError ? shellRoot.authError : shellRoot.authMuted
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 10
          elide: Text.ElideRight
        }

        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 10

          Rectangle {
            width: 110
            height: 38
            radius: 9
            color: cancelMouse.containsMouse ? shellRoot.authBorder : "transparent"
            border.width: 1
            border.color: shellRoot.authBorder

            Text {
              anchors.centerIn: parent
              text: "Cancel"
              color: shellRoot.authText
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: 12
            }
            MouseArea {
              id: cancelMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: if (polkitAgent.flow) polkitAgent.flow.cancelAuthenticationRequest()
            }
          }

          Rectangle {
            width: 110
            height: 38
            radius: 9
            color: submitMouse.containsMouse ? shellRoot.authAccentHover : "#cd974b"

            Text {
              anchors.centerIn: parent
              text: "Continue"
              color: "#26251e"
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: 12
              font.bold: true
            }
            MouseArea {
              id: submitMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: authWindow.submitPassword()
            }
          }
        }
      }
    }

    Connections {
      target: polkitAgent.flow
      function onIsResponseRequiredChanged() {
        passwordInput.text = ""
        if (polkitAgent.flow?.isResponseRequired) passwordInput.forceActiveFocus()
      }
    }
  }

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
      property int rebuildFrame: 0
      property var rebuildFrames: ["|", "/", "—", "\\"]
      property var sink: Pipewire.defaultAudioSink
      property var battery: UPower.displayDevice

      readonly property color foreground: shellRoot.darkMode ? "#f4f0e8" : "#26251e"
      readonly property color muted: shellRoot.darkMode ? "#aaa9a5" : "#57564f"
      readonly property color accent: "#cd974b"
      readonly property color barBackground: shellRoot.darkMode ? "#211f18" : "#efeee9"
      readonly property color panelBackground: shellRoot.darkMode ? "#211f18" : "#efeee9"
      readonly property color panelBorder: shellRoot.darkMode ? "#3b3830" : "#cecdc7"
      readonly property color hoverBackground: shellRoot.darkMode ? "#353229" : "#d9d8d2"
      readonly property color inactive: shellRoot.darkMode ? "#777777" : "#98968e"
      readonly property color error: shellRoot.darkMode ? "#d66a64" : "#aa3731"

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
      implicitHeight: 30
      color: "transparent"

      Rectangle {
        anchors.fill: parent
        anchors.margins: 3
        radius: 8
        color: bar.barBackground
        border.width: 1
        border.color: bar.panelBorder
      }

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
        color: rowMouse.containsMouse ? bar.hoverBackground : "transparent"

        Text {
          id: rowIcon
          anchors.left: parent.left
          anchors.leftMargin: 8
          anchors.verticalCenter: parent.verticalCenter
          width: 22
          horizontalAlignment: Text.AlignHCenter
          text: panelRow.icon
          color: panelRow.destructive ? bar.error : bar.foreground
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
            color: panelRow.destructive ? bar.error : bar.foreground
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
          color: panelRow.destructive ? bar.error : bar.muted
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

      Timer {
        interval: 200
        running: shellRoot.rebuildStatus === "running"
        repeat: true
        onTriggered: bar.rebuildFrame = (bar.rebuildFrame + 1) % bar.rebuildFrames.length
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
            color: modelData.focused ? bar.foreground : bar.inactive
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
        text: Qt.formatDateTime(bar.now, "ddd, MMM d") + " · " + Qt.formatDateTime(bar.now, "HH:mm")
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
          visible: shellRoot.rebuildStatus === "running"
          Layout.preferredWidth: visible ? 108 : 0
          Layout.fillHeight: true
          Text {
            anchors.centerIn: parent
            text: bar.rebuildFrames[bar.rebuildFrame] + " rebuilding"
            color: bar.accent
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
          }
        }

        Item {
          Layout.preferredWidth: 25
          Layout.fillHeight: true
          Text {
            anchors.centerIn: parent
            text: "󰖩"
            color: bar.wifiName.length > 0 ? bar.foreground : bar.inactive
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
            color: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled ? bar.foreground : bar.inactive
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
            color: bar.battery && bar.battery.ready && bar.battery.percentage < 0.2 ? bar.error : bar.foreground
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
                  color: bar.panelBorder
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
                  color: bar.battery && bar.battery.ready && bar.battery.percentage < 0.2 ? bar.error : bar.foreground
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
                  Quickshell.execDetached(["systemctl", "--user", "start", "sharchy-lock.service"])
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
