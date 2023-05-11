import QtQuick 2.15
import QtQuick.Controls 2.15

AbstractButton {
    id: control
    width: 46
    height: 40
    focusPolicy: Qt.NoFocus
    display: AbstractButton.IconOnly
    implicitWidth: width
    implicitHeight: height
    leftPadding: 4
    rightPadding: 4

    property int activateTransitionTime: 300
    property bool isSlotExist: false
    property bool isActive: false
    property color indicatorColor: "#660066"

    //onClicked: control.isActive = !control.isActive
    background: buttonBackground

    Rectangle {
        id: buttonBackground
        width: parent.width
        height: parent.height
        color: "#00000000"
        opacity: 1
        radius: 15
        border.color: "#eeeeee"

        Rectangle {
            id: buttonHighlighter
            width: parent.width
            height: parent.height
            color: control.hovered && !control.isActive ? "#33eeeeee" : "#00000000"
            radius: parent.radius
            border.width: 0
        }
    }

    Rectangle {
        id: buttonIndicator
        height: 10
        color: control.indicatorColor
        radius: 6
        border.width: 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 8
        anchors.leftMargin: 8
        anchors.topMargin: 8
    }
    states: [
        State {
            name: "empty"
            when: !control.isSlotExist

            PropertyChanges {
                target: buttonIndicator
                height: 10
            }

            PropertyChanges {
                target: control
                height: 26
            }
        },
        State {
            name: "normal"
            when: !control.isActive && control.isSlotExist

            PropertyChanges {
                target: buttonIndicator
                height: 10
            }

            PropertyChanges {
                target: control
                height: 40
            }
        },
        State {
            name: "active"
            when: control.isActive && control.isSlotExist

            PropertyChanges {
                target: buttonIndicator
                explicit: true
                height: buttonIndicator.width - 6
            }

            PropertyChanges {
                target: control
                height: 40
            }
        }
    ]
    transitions: [
        Transition {
            reversible: true
            NumberAnimation {
                running: false
                properties: "height"
                duration: control.activateTransitionTime
                easing.type: Easing.InOutQuad
            }
        }
    ]
}

/*##^##
Designer {
    D{i:0;formeditorColor:"#000000";formeditorZoom:6;height:46;width:46}D{i:2}D{i:1}D{i:3}
}
##^##*/

