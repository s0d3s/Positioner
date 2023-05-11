import QtQuick 2.15
import "./controls"
import QtQuick.Controls 6.2


Window {
    id: childWindow
    color: "#00000000"
    flags: Qt.Window | Qt.FramelessWindowHint
    width: 400
    height: 200
    visible: true

    signal hidden

    Rectangle {
        id: windowOverlay
        x: 200
        y: 200
        width: 100
        height: 33
        color: "#00000000"
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 0
        anchors.topMargin: 0
        property int overlayOffset: 20


        DragHandler {
            onActiveChanged: if(active) childWindow.startSystemMove()
        }



        Canvas {
            id: bevelCanvas
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d");

                context.beginPath();
                context.moveTo(0, windowOverlay.height);
                context.lineTo(windowOverlay.overlayOffset, 0);
                context.lineTo(windowOverlay.overlayOffset, windowOverlay.height);
                context.closePath();

                context.fillStyle = "#47B5FF";
                context.fill();
            }
        }



        Rectangle {
            id: windowOverlayBase
            width: windowOverlay.width - windowOverlay.overlayOffset
            height: windowOverlay.height
            color: "#47b5ff"
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 0
            anchors.rightMargin: 0
        }

        WindowOverlayMinusButton {
            id: controlMinusButton
            z: 1
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 17
            onClicked: childWindow.hidden()
        }

    }

    Rectangle {
        id: windowBase
        color: "#06283D"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: windowOverlay.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: 0
        anchors.bottomMargin: 0
        anchors.rightMargin: 0
        anchors.leftMargin: 0

        Text {
            id: windowTitle
            x: 8
            y: 8
            color: "#dddddd"
            text: qsTr("Settings")
            font.pixelSize: 23
            font.weight: Font.Bold
            font.italic: false
            font.capitalization: Font.MixedCase
            font.underline: false
            font.family: "Arial"
            font.bold: false
        }

        Item {
            id: content
            x: 16
            y: 55
            width: 376
            height: 104

            Item {
                id: item1
                x: 0
                y: 0
                width: 200
                height: 15

                CheckBox {
                    id: launchOnStartup
                    x: 0
                    y: -8
                    text: qsTr("Launch on startup")
                    font.pixelSize: 12
                    display: AbstractButton.TextBesideIcon
                    tristate: false
                    font.bold: false
                    font.italic: false
                    checked: mainWindow.appSettings.launchOnSystemStartup
                    onClicked: mainWindow.appSettings.launchOnSystemStartup = checked
                }
            }

            Item {
                id: item2
                x: 0
                y: 0
                width: 200
                height: 25

                CheckBox {
                    id: startMinimized
                    x: 0
                    y: 8
                    text: qsTr("Start minimized")
                    font.pixelSize: 12
                    checkState: Qt.Unchecked
                    tristate: false
                    display: AbstractButton.TextBesideIcon
                    font.italic: false
                    font.bold: false
                    checked: mainWindow.appSettings.startMinimized
                    onClicked: mainWindow.appSettings.startMinimized = checked
                }
            }

            Item {
                id: restoreFromSlot
                x: 0
                y: 25
                width: 190
                height: 200

                CheckBox {
                    id: restoreFromSnapshotOnStartup
                    x: 0
                    text: qsTr("Restore Snapshot on OS startup")
                    anchors.top: parent.top
                    font.pixelSize: 12
                    anchors.topMargin: 0
                    display: AbstractButton.TextBesideIcon
                    tristate: false
                    font.italic: false
                    font.bold: false
                    checked: mainWindow.appSettings.restoreFromSnapshotOnSystemStartup > -1
                    onClicked: {
                        if (mainWindow.appSettings.restoreFromSnapshotOnSystemStartup > -1)
                            mainWindow.appSettings.restoreFromSnapshotOnSystemStartup = -1
                        else
                            mainWindow.appSettings.restoreFromSnapshotOnSystemStartup = 0
                    }
                }

                Text {
                    id: attachedToText1
                    x: 14
                    y: 23
                    color: "#eeeeee"
                    font.pixelSize: 12
                }

                Item {

                    id: slotsControlItems
                    enabled: mainWindow.appSettings.restoreFromSnapshotOnSystemStartup > -1
                    width: 80
                    height: 45
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter

                    SettingsSnapshotAttachToButton {
                        id: settingsSnapshotAttachToButton0
                        property int index: 0
                        x: 0
                        y: 22
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 0
                        isActive: mainWindow.appSettings.restoreFromSnapshotOnSystemStartup === index
                        buttonColor: mainWindow.firstSlotMainColor
                        onClicked: mainWindow.appSettings.restoreFromSnapshotOnSystemStartup = index
                    }

                    SettingsSnapshotAttachToButton {
                        id: settingsSnapshotAttachToButton1
                        property int index: 1
                        x: 27
                        y: 22
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 0
                        isActive: mainWindow.appSettings.restoreFromSnapshotOnSystemStartup === index
                        buttonColor: mainWindow.secondSlotMainColor
                        onClicked: mainWindow.appSettings.restoreFromSnapshotOnSystemStartup = index
                    }

                    SettingsSnapshotAttachToButton {
                        id: settingsSnapshotAttachToButton2
                        property int index: 2
                        x: 54
                        y: 22
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 0
                        isActive: mainWindow.appSettings.restoreFromSnapshotOnSystemStartup === index
                        buttonColor: mainWindow.thirdSlotMainColor
                        onClicked: mainWindow.appSettings.restoreFromSnapshotOnSystemStartup = index
                    }

                    anchors.topMargin: 0
                }


            }



        }
    }

    MouseArea {
        id: resizeBottom
        height: 10
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 0
        anchors.leftMargin: 0
        anchors.bottomMargin: 0
        cursorShape: Qt.SizeVerCursor

        DragHandler{
            target: null
            onActiveChanged: if (active) { childWindow.startSystemResize(Qt.BottomEdge) }
        }
    }

}

/*##^##
Designer {
    D{i:0;formeditorZoom:1.5}D{i:2}D{i:3}D{i:4}D{i:5}D{i:1}D{i:7}D{i:10}D{i:9}D{i:12}
D{i:11}D{i:14}D{i:15}D{i:17}D{i:18}D{i:19}D{i:16}D{i:13}D{i:8}D{i:6}D{i:21}D{i:20}
}
##^##*/
