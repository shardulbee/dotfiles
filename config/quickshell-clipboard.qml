import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
  id: root

  property string filterText: ""
  property int selectedIndex: 0
  property double nowMs: Date.now()
  property var history: []

  readonly property string backend: "/home/shardul/.local/bin/sharchy-clipboard-backend"
  readonly property color background: darkMode ? "#211f18" : "#f7f7f4"
  readonly property color foreground: darkMode ? "#f4f0e8" : "#26251e"
  readonly property color muted: darkMode ? "#aaa9a5" : "#77756e"
  readonly property color inactive: darkMode ? "#777777" : "#98968e"
  readonly property color borderColor: darkMode ? "#3b3830" : "#cecdc7"
  readonly property color selectedBackground: darkMode ? "#353229" : "#f4edd7"
  readonly property color accent: "#cd974b"
  readonly property bool darkMode: themeFile.text().trim() !== "light"

  onSelectedIndexChanged: textPreview.contentY = 0

  function show(): void {
    root.nowMs = Date.now()
    root.setFilter("")
    historyFile.reload()
    panel.visible = true
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function hide(): void {
    panel.visible = false
  }

  function toggle(): void {
    if (panel.visible) root.hide()
    else root.show()
  }

  function loadHistory(raw) {
    try {
      const value = raw.trim() ? JSON.parse(raw) : []
      root.history = Array.isArray(value) ? value : []
    } catch (error) {
      root.history = []
    }
    rebuildDisplay()
  }

  function rebuildDisplay() {
    const query = root.filterText.trim().toLowerCase()
    displayModel.clear()
    for (let i = 0; i < root.history.length; i++) {
      const entry = root.history[i]
      const searchable = (String(entry.summary || "") + " " + String(entry.text || "").slice(0, 8192)).toLowerCase()
      if (query && !searchable.includes(query)) continue
      displayModel.append({
        entryId: String(entry.id || ""),
        entryType: String(entry.type || "binary"),
        mime: String(entry.mime || "application/octet-stream"),
        summary: String(entry.summary || "Clipboard data"),
        fullText: String(entry.text || ""),
        previewImage: entry.type === "image" && entry.path ? "file://" + entry.path : "",
        capturedAt: Number(entry.capturedAt || 0)
      })
    }
    if (displayModel.count === 0) root.selectedIndex = 0
    else root.selectedIndex = Math.max(0, Math.min(root.selectedIndex, displayModel.count - 1))
    Qt.callLater(function() {
      if (displayModel.count > 0) resultList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
      keyCatcher.forceActiveFocus()
    })
  }

  function setFilter(value) {
    root.filterText = value
    root.selectedIndex = 0
    rebuildDisplay()
  }

  function select(delta) {
    if (displayModel.count === 0) return
    root.selectedIndex = (root.selectedIndex + delta + displayModel.count) % displayModel.count
    resultList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
  }

  function relativeTime(capturedAt) {
    if (!capturedAt) return "Older"
    const seconds = Math.max(0, Math.floor((root.nowMs - capturedAt) / 1000))
    if (seconds < 60) return "Now"
    if (seconds < 3600) return Math.floor(seconds / 60) + "m ago"
    if (seconds < 86400) return Math.floor(seconds / 3600) + "h ago"
    const days = Math.floor(seconds / 86400)
    return days + (days === 1 ? " day ago" : " days ago")
  }

  function activate(copyOnly) {
    if (displayModel.count === 0) return
    const row = displayModel.get(root.selectedIndex)
    Quickshell.execDetached([root.backend, copyOnly ? "copy" : "paste", row.entryId])
    root.hide()
  }

  function removeSelected() {
    if (displayModel.count === 0) return
    const row = displayModel.get(root.selectedIndex)
    Quickshell.execDetached([root.backend, "delete", row.entryId])
    displayModel.remove(root.selectedIndex)
    if (displayModel.count === 0) root.selectedIndex = 0
    else root.selectedIndex = Math.min(root.selectedIndex, displayModel.count - 1)
  }

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
    id: historyFile
    path: "/home/shardul/.local/state/sharchy-clipboard/history.json"
    preload: true
    blockLoading: true
    watchChanges: true
    printErrors: false
    onLoaded: root.loadHistory(text())
    onLoadFailed: root.loadHistory("[]")
    onFileChanged: reload()
  }

  Timer {
    interval: 60000
    running: true
    repeat: true
    onTriggered: root.nowMs = Date.now()
  }

  ListModel { id: displayModel }

  IpcHandler {
    target: "clipboard"
    function toggle(): void { root.toggle() }
  }

  PanelWindow {
    id: panel
    visible: false
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: true
    WlrLayershell.namespace: "sharchy-clipboard"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Rectangle {
      anchors.fill: parent
      color: root.darkMode ? "#9914120b" : "#66e5e4df"

      MouseArea {
        anchors.fill: parent
        onClicked: root.hide()
      }
    }

    Rectangle {
      id: card
      anchors.centerIn: parent
      width: Math.min(1100, panel.width - 80)
      height: Math.min(650, panel.height - 80)
      radius: 14
      color: root.background
      border.width: 1
      border.color: root.borderColor

      MouseArea { anchors.fill: parent; onClicked: {} }

      Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true
        z: 10

        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            if (root.filterText) root.setFilter("")
            else root.hide()
            event.accepted = true
          } else if (event.key === Qt.Key_Backspace) {
            if (root.filterText) root.setFilter(root.filterText.slice(0, -1))
            event.accepted = true
          } else if (event.key === Qt.Key_Up) {
            root.select(-1)
            event.accepted = true
          } else if (event.key === Qt.Key_Down) {
            root.select(1)
            event.accepted = true
          } else if (event.key === Qt.Key_PageUp) {
            root.select(-8)
            event.accepted = true
          } else if (event.key === Qt.Key_PageDown) {
            root.select(8)
            event.accepted = true
          } else if (event.key === Qt.Key_Home) {
            root.selectedIndex = 0
            resultList.positionViewAtBeginning()
            event.accepted = true
          } else if (event.key === Qt.Key_End) {
            root.selectedIndex = Math.max(0, displayModel.count - 1)
            resultList.positionViewAtEnd()
            event.accepted = true
          } else if (event.key === Qt.Key_Delete) {
            root.removeSelected()
            event.accepted = true
          } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.activate(Boolean(event.modifiers & Qt.ShiftModifier))
            event.accepted = true
          } else if (!(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))
                     && event.text && event.text.length > 0 && event.text.charCodeAt(0) >= 32) {
            root.setFilter(root.filterText + event.text)
            event.accepted = true
          }
        }
      }

      Column {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        Rectangle {
          width: parent.width
          height: 52
          radius: 10
          color: "transparent"
          border.width: 1
          border.color: root.borderColor

          Text {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: ""
            color: root.accent
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 17
          }

          Text {
            anchors.left: parent.left
            anchors.leftMargin: 48
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: root.filterText || "Search clipboard…"
            color: root.filterText ? root.foreground : root.muted
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 15
            elide: Text.ElideRight
          }
        }

        Item {
          width: parent.width
          height: parent.height - 52 - 32 - parent.spacing * 2

          Row {
            anchors.fill: parent
            spacing: 0

            Item {
              width: Math.floor(parent.width * 0.48)
              height: parent.height
              clip: true

              ListView {
                id: resultList
                anchors.fill: parent
                anchors.rightMargin: 14
                model: displayModel
                spacing: 4
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                  id: resultRow
                  required property int index
                  required property string entryType
                  required property string summary
                  required property string previewImage
                  required property double capturedAt

                  readonly property bool selected: index === root.selectedIndex

                  width: ListView.view.width
                  height: 52
                  radius: 9
                  color: selected ? root.selectedBackground : "transparent"

                  Image {
                    id: thumbnail
                    visible: resultRow.entryType === "image" && resultRow.previewImage.length > 0
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: visible ? 34 : 0
                    height: 34
                    source: resultRow.previewImage
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                  }

                  Text {
                    anchors.left: thumbnail.visible ? thumbnail.right : parent.left
                    anchors.leftMargin: thumbnail.visible ? 10 : 12
                    anchors.right: timestamp.left
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: resultRow.summary
                    color: root.foreground
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    elide: Text.ElideRight
                  }

                  Text {
                    id: timestamp
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 78
                    horizontalAlignment: Text.AlignRight
                    text: root.relativeTime(resultRow.capturedAt)
                    color: root.inactive
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                  }

                  MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.selectedIndex = resultRow.index
                    onClicked: root.selectedIndex = resultRow.index
                    onDoubleClicked: root.activate(false)
                  }
                }
              }
            }

            Rectangle {
              width: 1
              height: parent.height
              color: root.borderColor
              opacity: 0.7
            }

            Item {
              id: previewPane
              width: parent.width - Math.floor(parent.width * 0.48) - 1
              height: parent.height
              clip: true

              property var activeRow: displayModel.count > 0 && root.selectedIndex < displayModel.count
                ? displayModel.get(root.selectedIndex) : null

              Flickable {
                id: textPreview
                visible: previewPane.activeRow && previewPane.activeRow.entryType === "text"
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 4
                clip: true
                contentWidth: width
                contentHeight: previewText.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Text {
                  id: previewText
                  width: textPreview.width
                  text: previewPane.activeRow ? previewPane.activeRow.fullText : ""
                  textFormat: Text.PlainText
                  color: root.foreground
                  font.family: "JetBrainsMono Nerd Font"
                  font.pixelSize: 12
                  wrapMode: Text.WrapAnywhere
                }
              }

              Image {
                visible: previewPane.activeRow && previewPane.activeRow.entryType === "image"
                anchors.fill: parent
                anchors.leftMargin: 18
                source: previewPane.activeRow ? previewPane.activeRow.previewImage : ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
              }

              Column {
                visible: previewPane.activeRow && previewPane.activeRow.entryType === "binary"
                anchors.centerIn: parent
                spacing: 10

                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: "󰒓"
                  color: root.accent
                  font.family: "JetBrainsMono Nerd Font"
                  font.pixelSize: 34
                }
                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: previewPane.activeRow ? previewPane.activeRow.summary : "Clipboard data"
                  color: root.foreground
                  font.family: "JetBrainsMono Nerd Font"
                  font.pixelSize: 13
                }
                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: "Preview unavailable"
                  color: root.muted
                  font.family: "JetBrainsMono Nerd Font"
                  font.pixelSize: 10
                }
              }

              Column {
                visible: displayModel.count === 0
                anchors.centerIn: parent
                spacing: 10

                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: ""
                  color: root.accent
                  font.family: "JetBrainsMono Nerd Font"
                  font.pixelSize: 30
                }
                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: root.history.length === 0 ? "Clipboard history is empty" : "No matching entries"
                  color: root.muted
                  font.family: "JetBrainsMono Nerd Font"
                  font.pixelSize: 12
                }
              }
            }
          }
        }

        Item {
          width: parent.width
          height: 32

          Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "↑↓ navigate   ↵ paste   ⇧↵ copy only   Delete remove   Esc close"
            color: root.inactive
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 9
          }

          Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: displayModel.count + (displayModel.count === 1 ? " item" : " items")
            color: root.inactive
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 9
          }
        }
      }
    }
  }
}
