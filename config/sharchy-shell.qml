import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Polkit
import Quickshell.Services.UPower
import Quickshell.Wayland

ShellRoot {
  id: shellRoot

  property bool darkMode: themeFile.text().trim() !== "light"
  property int cpuUsage: 0
  property int memoryUsage: 0
  property real previousCpuIdle: 0
  property real previousCpuTotal: 0
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

  Process {
    id: systemUsageProcess
    running: true
    command: ["sh", "-c", "head -n 1 /proc/stat; awk '/MemTotal:/ { total=$2 } /MemAvailable:/ { available=$2 } END { print total, available }' /proc/meminfo"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        const lines = text.trim().split("\n")
        if (lines.length < 2) return

        const cpu = lines[0].trim().split(/\s+/)
        let total = 0
        for (let i = 1; i < cpu.length; i++) total += Number(cpu[i])
        const idle = Number(cpu[4]) + Number(cpu[5] || 0)
        const totalDelta = total - shellRoot.previousCpuTotal
        const idleDelta = idle - shellRoot.previousCpuIdle
        if (shellRoot.previousCpuTotal > 0 && totalDelta > 0)
          shellRoot.cpuUsage = Math.max(0, Math.min(100, Math.round(100 * (1 - idleDelta / totalDelta))))
        shellRoot.previousCpuTotal = total
        shellRoot.previousCpuIdle = idle

        const memory = lines[1].trim().split(/\s+/)
        const totalKiB = Number(memory[0])
        const availableKiB = Number(memory[1])
        shellRoot.memoryUsage = totalKiB > 0 ? Math.round(100 * (totalKiB - availableKiB) / totalKiB) : 0
      }
    }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: if (!systemUsageProcess.running) systemUsageProcess.running = true
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
      property date now: new Date()
      property var sink: Pipewire.defaultAudioSink
      property var battery: UPower.displayDevice

      readonly property color foreground: shellRoot.darkMode ? "#f4f0e8" : "#26251e"
      readonly property color barBackground: shellRoot.darkMode ? "#211f18" : "#efeee9"
      readonly property color panelBorder: shellRoot.darkMode ? "#3b3830" : "#cecdc7"
      readonly property color inactive: shellRoot.darkMode ? "#777777" : "#98968e"
      readonly property color error: shellRoot.darkMode ? "#d66a64" : "#aa3731"

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

      screen: modelData
      anchors.top: true
      anchors.left: true
      anchors.right: true
      implicitHeight: 30
      color: "transparent"

      Rectangle {
        anchors.fill: parent
        radius: 0
        color: bar.barBackground
        border.width: 1
        border.color: bar.panelBorder
      }

      PwObjectTracker {
        objects: [bar.sink]
      }

      Process {
        id: wifiProcess
        running: true
        command: ["sh", "-c", "nmcli -t -f TYPE,STATE,CONNECTION device | awk -F: '$1 == \"wifi\" && $2 == \"connected\" { sub(/^[^:]*:[^:]*:/, \"\"); print; exit }'"]
        stdout: StdioCollector {
          waitForEnd: true
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
            color: modelData.focused ? bar.foreground : bar.inactive
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            font.bold: modelData.focused
          }
        }
      }

      RowLayout {
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: 14

        Text {
          Layout.alignment: Qt.AlignVCenter
          text: "󰻠 " + shellRoot.cpuUsage + "%  󰍛 " + shellRoot.memoryUsage + "%"
          color: bar.foreground
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 11
        }

        Text {
          Layout.alignment: Qt.AlignVCenter
          Layout.maximumWidth: 220
          text: bar.wifiName.length > 0 ? "󰖩 " + bar.wifiName : "󰖪 offline"
          color: bar.wifiName.length > 0 ? bar.foreground : bar.inactive
          elide: Text.ElideRight
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 11
        }

        Text {
          Layout.alignment: Qt.AlignVCenter
          text: bar.volumeIcon() + " " + (bar.sink && bar.sink.audio ? Math.round(bar.sink.audio.volume * 100) + "%" : "—")
          color: bar.foreground
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 11
        }

        Text {
          Layout.alignment: Qt.AlignVCenter
          text: bar.battery && bar.battery.ready ? bar.batteryIcon() + " " + Math.round(bar.battery.percentage * 100) + "%" : "󰂑 —"
          color: bar.battery && bar.battery.ready && bar.battery.percentage < 0.2 ? bar.error : bar.foreground
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 11
        }

        Text {
          Layout.alignment: Qt.AlignVCenter
          text: Qt.formatDateTime(bar.now, "ddd, MMM d") + " · " + Qt.formatDateTime(bar.now, "HH:mm:ss")
          color: bar.foreground
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 11
        }
      }

    }
  }
}
