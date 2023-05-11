import QtQuick 2.15
import QtQuick.Controls 2.15

AbstractButton {
    id: control
    width: 60
    height: 60
    focusPolicy: Qt.NoFocus
    display: AbstractButton.IconOnly
    implicitWidth: 60
    implicitHeight: 60
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
        opacity: 1 //enabled ? 1 : 0.3
        radius: 20
        border.color: "#eeeeee"

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
        id: buttonIcon
        opacity: 1 //enabled ? 1 : 0.3
        anchors.fill: parent
        source: "../assets/eye_open.svg"
        sourceSize.height: 70
        sourceSize.width: 70
        fillMode: Image.Stretch
        anchors.rightMargin: 5
        anchors.leftMargin: 5
        anchors.bottomMargin: 5
        anchors.topMargin: 5
    }

    states: [
        State {
            name: "normal"
            when: !control.isActive

            PropertyChanges {
                target: buttonBackground
                color: "#00000000"
                border.color: "#eeeeee"
                border.width: 1
            }
        },
        State {
            name: "down"
            when: control.isActive

            PropertyChanges {
                target: buttonBackground
                border.color: "#1363DF"
                border.width: control.width / 2
            }
        }
    ]
    transitions: [
        Transition {
            reversible: true
            ParallelAnimation {
                NumberAnimation {
                    properties: "border.width"
                    duration: control.activateTransitionTime
                    easing.type: Easing.InOutQuad
                }
                ColorAnimation {
                    duration: 100
                }
            }
        }
    ]
}
