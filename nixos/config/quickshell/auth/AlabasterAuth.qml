import QtQuick

Item {
  id: root

  property string title: "Welcome back"
  property string subtitle: "shardul"
  property string prompt: "Password"
  property string errorText: ""
  property bool busy: false
  property bool responseVisible: false
  property bool clearing: false
  signal submitted(string password)
  signal edited()

  function clear() {
    clearing = true
    passwordInput.text = ""
    clearing = false
  }

  function focusInput() {
    passwordInput.forceActiveFocus()
  }

  onErrorTextChanged: {
    if (errorText.length > 0) {
      clear()
      focusInput()
    }
  }

  implicitWidth: 420
  implicitHeight: 310

  Rectangle {
    anchors.fill: parent
    radius: 12
    color: "#1b1913"
    border.width: 1
    border.color: "#2b2923"

    Column {
      anchors.fill: parent
      anchors.margins: 30
      spacing: 14

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: "󰌾"
        color: "#cd974b"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 28
      }

      Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: root.title
        color: "#cecece"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 17
        font.bold: true
      }

      Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: root.subtitle
        color: "#999999"
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
        color: "#14120b"
        border.width: passwordInput.activeFocus ? 2 : 1
        border.color: root.errorText.length > 0 ? "#d66a64" : (passwordInput.activeFocus ? "#cd974b" : "#2b2923")

        TextInput {
          id: passwordInput
          anchors.fill: parent
          anchors.leftMargin: 15
          anchors.rightMargin: 15
          verticalAlignment: TextInput.AlignVCenter
          color: "#cecece"
          selectionColor: "#3a382f"
          selectedTextColor: "#cecece"
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 14
          echoMode: root.responseVisible ? TextInput.Normal : TextInput.Password
          inputMethodHints: Qt.ImhSensitiveData
          enabled: !root.busy
          focus: true
          onAccepted: {
            if (text.length === 0 || root.busy) return
            root.submitted(text)
          }
          onTextChanged: if (!root.clearing) root.edited()
        }

        Text {
          anchors.left: parent.left
          anchors.leftMargin: 15
          anchors.verticalCenter: parent.verticalCenter
          visible: passwordInput.text.length === 0 && !passwordInput.activeFocus
          text: root.prompt
          color: "#6f716c"
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 13
        }
      }

      Text {
        width: parent.width
        height: 16
        horizontalAlignment: Text.AlignHCenter
        text: root.errorText
        color: "#d66a64"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 10
        elide: Text.ElideRight
      }

      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: 138
        height: 38
        radius: 8
        color: submitMouse.containsMouse ? "#d5b773" : "#cd974b"
        opacity: root.busy || passwordInput.text.length === 0 ? 0.55 : 1

        Text {
          anchors.centerIn: parent
          text: root.busy ? "Checking…" : "Continue"
          color: "#14120b"
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 12
          font.bold: true
        }

        MouseArea {
          id: submitMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          enabled: !root.busy && passwordInput.text.length > 0
          onClicked: root.submitted(passwordInput.text)
        }
      }
    }
  }
}
