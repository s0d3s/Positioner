import QtQuick 2.15
import QtQuick.Controls 2.15

AbstractButton {
    id: control
    width: 40
    height: 40
    focusPolicy: Qt.NoFocus
    display: AbstractButton.IconOnly
    implicitWidth: width
    implicitHeight: height
    leftPadding: 4
    rightPadding: 4

    property int activateTransitionTime: 300
    property bool isActive: false

    background: buttonBackground

    Rectangle {
        id: buttonBackground
        width: parent.width
        height: parent.height
        color: "#00000000"
        opacity: 1
        radius: 20
        border.color: "#eeeeee"
        border.width: 0

        Rectangle {
            id: buttonHighlighter
            width: parent.width
            height: parent.height
            color: control.hovered ? "#33eeeeee" : "#00000000"
            radius: parent.radius
            border.width: 0
        }
    }

    Image {
        id: desktop_flags
        x: 5
        y: 5
        source: "../assets/desktop_flags.svg"
        fillMode: Image.PreserveAspectFit
    }

    states: [
        State {
            name: "normal"
            when: !control.isActive

            PropertyChanges {
                target: buttonBackground
                border.width: 0
            }

            PropertyChanges {
                target: desktop_flags
                opacity: 0.3
            }
        },
        State {
            name: "active"
            when: control.isActive

            PropertyChanges {
                target: buttonBackground
                border.width: 3
            }

            PropertyChanges {
                target: desktop_flags
                opacity: 1
            }
        }
    ]
    transitions: [
        Transition {
            reversible: true
            NumberAnimation {
                running: false
                properties: "opacity, border.width"
                duration: control.activateTransitionTime
                easing.type: Easing.InOutQuad
            }
        }
    ]
}

/*##^##
Designer {
    D{i:0;formeditorColor:"#000000";formeditorZoom:8;height:40;width:40}D{i:2}D{i:1}D{i:3}
}
##^##*/

