import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import "."

ShellRoot {
  id: root

  property string errorText: ""
  property bool darkMode: themeFile.text().trim() !== "light"
  property bool authenticating: false
  property string password: ""

  FileView {
    id: themeFile
    path: "/home/shardul/.local/state/sharchy-theme"
    preload: true
    blockLoading: true
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
  }

  function tryUnlock(value) {
    if (value.length === 0 || authenticating) return
    password = value
    errorText = ""
    authenticating = true
    pam.start()
  }

  PamContext {
    id: pam
    configDirectory: "/etc/pam.d"
    config: "sharchy-lock"
    user: "shardul"

    onPamMessage: {
      if (responseRequired) respond(root.password)
    }

    onCompleted: result => {
      root.password = ""
      root.authenticating = false
      if (result === PamResult.Success) {
        sessionLock.locked = false
        Qt.quit()
      } else {
        root.errorText = "Incorrect password"
      }
    }

    onError: error => {
      root.password = ""
      root.authenticating = false
      root.errorText = "Authentication unavailable"
    }
  }

  WlSessionLock {
    id: sessionLock
    locked: true

    WlSessionLockSurface {
      Rectangle {
        id: lockSurface
        anchors.fill: parent
        color: root.darkMode ? "#14120b" : "#f7f7f4"
        property date now: new Date()

        Timer {
          interval: 1000
          running: true
          repeat: true
          onTriggered: lockSurface.now = new Date()
        }

        Column {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: parent.top
          anchors.topMargin: 110
          spacing: 5

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(lockSurface.now, "HH:mm")
            color: root.darkMode ? "#cecece" : "#26251e"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 66
            font.weight: Font.Light
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(lockSurface.now, "dddd, MMMM d")
            color: root.darkMode ? "#999999" : "#57564f"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
          }
        }

        AlabasterAuth {
          id: authCard
          anchors.centerIn: parent
          title: "Session locked"
          subtitle: "shardul"
          dark: root.darkMode
          prompt: "Password"
          errorText: root.errorText
          busy: root.authenticating
          onEdited: root.errorText = ""
          onSubmitted: password => root.tryUnlock(password)
        }

        Component.onCompleted: authCard.focusInput()
      }
    }
  }
}
