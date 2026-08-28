import QtQuick

Item {
  id: root

  property string title: "Welcome back"
  property string subtitle: "shardul"
  property string prompt: "Password"
  property string errorText: ""
  property bool dark: true
  property bool busy: false
  readonly property color cardColor: dark ? "#1b1913" : "#efeee9"
  readonly property color fieldColor: dark ? "#14120b" : "#f7f7f4"
  readonly property color borderColor: dark ? "#2b2923" : "#cecdc7"
  readonly property color textColor: dark ? "#cecece" : "#26251e"
  readonly property color mutedColor: dark ? "#999999" : "#57564f"
  readonly property color placeholderColor: dark ? "#6f716c" : "#77756e"
  readonly property color selectionColor: dark ? "#3a382f" : "#f4edd7"
  readonly property color errorColor: dark ? "#d66a64" : "#aa3731"
  readonly property color accentColor: "#cd974b"
  readonly property color accentHoverColor: dark ? "#d5b773" : "#cb9000"
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
    color: root.cardColor
    border.width: 1
    border.color: root.borderColor

    Column {
      anchors.fill: parent
      anchors.margins: 30
      spacing: 14

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: "󰌾"
        color: root.accentColor
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 28
      }

      Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: root.title
        color: root.textColor
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 17
        font.bold: true
      }

      Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: root.subtitle
        color: root.mutedColor
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
        color: root.fieldColor
        border.width: passwordInput.activeFocus ? 2 : 1
        border.color: root.errorText.length > 0 ? root.errorColor : (passwordInput.activeFocus ? root.accentColor : root.borderColor)

        TextInput {
          id: passwordInput
          anchors.fill: parent
          anchors.leftMargin: 15
          anchors.rightMargin: 15
          verticalAlignment: TextInput.AlignVCenter
          color: root.textColor
          selectionColor: root.selectionColor
          selectedTextColor: root.textColor
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
          color: root.placeholderColor
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 13
        }
      }

      Text {
        width: parent.width
        height: 16
        horizontalAlignment: Text.AlignHCenter
        text: root.errorText
        color: root.errorColor
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 10
        elide: Text.ElideRight
      }

      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: 138
        height: 38
        radius: 8
        color: submitMouse.containsMouse ? root.accentHoverColor : root.accentColor
        opacity: root.busy || passwordInput.text.length === 0 ? 0.55 : 1

        Text {
          anchors.centerIn: parent
          text: root.busy ? "Checking…" : "Continue"
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
          enabled: !root.busy && passwordInput.text.length > 0
          onClicked: root.submitted(passwordInput.text)
        }
      }
    }
  }
}
