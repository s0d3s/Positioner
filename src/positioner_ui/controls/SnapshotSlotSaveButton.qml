import QtQuick 2.15
import QtQuick.Controls 2.15

AbstractButton {
    id: control
    width: 46
    height: 20
    focusPolicy: Qt.NoFocus
    display: AbstractButton.IconOnly
    implicitWidth: 46
    implicitHeight: 36
    leftPadding: 4
    rightPadding: 4

    property int activateTransitionTime: 300
    property bool isSlotExist: false

    background: buttonBackground

    Rectangle {
        id: buttonBackground
        width: control.width
        height: control.height
        color: "#00000000"
        opacity: 1
        visible: false //enabled ? 1 : 0.3
        radius: 15
        border.color: "#eeeeee"
    }

    Rectangle {
        id: buttonHighlighter
        color: control.hovered ? "#33eeeeee" : "#00000000"
        radius: 18
        border.width: 0
        anchors.left: parent.horizontalCenter
        anchors.right: parent.horizontalCenter
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.rightMargin: -control.height / 2
        anchors.leftMargin: -control.height / 2
        anchors.bottomMargin: 0
        anchors.topMargin: 0
    }

    Image {
        id: refresh
        opacity: 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        source: "../assets/refresh.svg"
        anchors.rightMargin: 8
        anchors.leftMargin: 8
        anchors.bottomMargin: 0
        anchors.topMargin: 0
        sourceSize.height: 36
        sourceSize.width: 36
        fillMode: Image.PreserveAspectFit

        Behavior on rotation {
            NumberAnimation{duration: 300}
        }
    }

    onClicked: refresh.rotation = Math.abs(refresh.rotation - 360)

    Image {
        id: compact_disk
        opacity: 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        source: "../assets/compact_disk.svg"
        anchors.leftMargin: 8
        anchors.bottomMargin: 3
        anchors.rightMargin: 8
        anchors.topMargin: 3
        sourceSize.height: 30
        sourceSize.width: 30
        fillMode: Image.PreserveAspectFit
    }

    states: [
        State {
            name: "empty"
            when: !control.isSlotExist

            PropertyChanges {
                target: control
                height: 36
            }

            PropertyChanges {
                target: refresh
                opacity: 0
            }

            PropertyChanges {
                target: compact_disk
                opacity: 1
                rotation: 0
            }
        },
        State {
            name: "exist"
            when: control.isSlotExist && !control.down

            PropertyChanges {
                target: control
                height: 20
            }

            PropertyChanges {
                target: refresh
                opacity: 1
            }

            PropertyChanges {
                target: compact_disk
                opacity: 0
                rotation: 180
            }
        },
        State {
            name: "down"
            when: control.down

            PropertyChanges {
                target: compact_disk
                opacity: 0
            }
        }
    ]
    transitions: [
        Transition {
            reversible: true
            NumberAnimation {
                properties: "height,opacity,rotation"
                duration: control.activateTransitionTime
                easing.type: Easing.InOutQuad
            }
        }
    ]
}

/*##^##
Designer {
    D{i:0;formeditorColor:"#ffffff";formeditorZoom:10;height:36;width:46}D{i:1}D{i:2}
D{i:3}D{i:4}
}
##^##*/

