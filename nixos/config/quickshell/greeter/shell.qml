import QtQuick
import Quickshell
import Quickshell.Services.Greetd
import "."

ShellRoot {
  FloatingWindow {
    id: greeterWindow
    visible: true
    implicitWidth: 1280
    implicitHeight: 800
    color: "#14120b"

    property date now: new Date()
    property string errorText: ""
    property string prompt: "Password"
    property bool responseRequired: false
    property bool responseVisible: false

    function beginAuthentication() {
      errorText = ""
      responseRequired = false
      authCard.clear()
      if (Greetd.available) Greetd.createSession("shardul")
      else errorText = "Preview mode — greetd is unavailable"
    }

    function submitPassword(password) {
      if (!responseRequired || Greetd.state !== GreetdState.Authenticating) return
      errorText = ""
      Greetd.respond(password)
      authCard.clear()
    }

    Timer {
      interval: 1000
      running: true
      repeat: true
      onTriggered: greeterWindow.now = new Date()
    }

    Column {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: 110
      spacing: 5

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDateTime(greeterWindow.now, "HH:mm")
        color: "#cecece"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 66
        font.weight: Font.Light
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDateTime(greeterWindow.now, "dddd, MMMM d")
        color: "#999999"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
      }
    }

    AlabasterAuth {
      id: authCard
      anchors.centerIn: parent
      title: "Welcome back"
      subtitle: "shardul · Hyprland"
      prompt: greeterWindow.prompt
      errorText: greeterWindow.errorText
      busy: Greetd.state === GreetdState.Launching
      responseVisible: greeterWindow.responseVisible
      onEdited: greeterWindow.errorText = ""
      onSubmitted: password => greeterWindow.submitPassword(password)
    }

    Connections {
      target: Greetd

      function onAuthMessage(message, error, responseRequired, echoResponse) {
        greeterWindow.prompt = message || "Password"
        greeterWindow.responseRequired = responseRequired
        greeterWindow.responseVisible = echoResponse
        if (error) greeterWindow.errorText = message
        if (responseRequired) authCard.focusInput()
      }

      function onAuthFailure(message) {
        greeterWindow.errorText = message || "Incorrect password"
        greeterWindow.responseRequired = false
        authCard.clear()
        Qt.callLater(() => Greetd.createSession("shardul"))
      }

      function onReadyToLaunch() {
        Greetd.launch([
          "/run/current-system/sw/bin/uwsm",
          "start",
          "-e",
          "-D",
          "Hyprland",
          "hyprland.desktop"
        ])
      }

      function onError(error) {
        greeterWindow.errorText = error
      }
    }

    Component.onCompleted: beginAuthentication()
  }
}
