import QtQuick 2.15
import QtQuick.Controls 2.15

AbstractButton {
    id: control
    width: 26
    height: 26
    focusPolicy: Qt.NoFocus
    implicitWidth: width
    implicitHeight: height
    leftPadding: 4
    rightPadding: 4

    property int activateTransitionTime: 300
    property color buttonColor: "#ff00ff"
    property bool isActive: false

    background: buttonBackground

    Rectangle {
        id: buttonBackground
        x: 1
        y: 1
        width: 24
        height: 24
        color: "#eeeeee"
        opacity: 1
        radius: 20
    }

    Rectangle {
        id: buttonHighlighter
        x: 3
        y: 3
        width: 20
        height: 20
        color: control.buttonColor
        radius: 20
        border.width: 0
    }

    states: [
        State {
            name: "normal"
            when: !control.isActive

            PropertyChanges {
                target: buttonBackground
                opacity: 0
            }

            PropertyChanges {
                target: buttonHighlighter
                opacity: 0.4
            }
        },
        State {
            name: "active"
            when: control.isActive

            PropertyChanges {
                target: buttonBackground
                opacity: 0.8
            }

            PropertyChanges {
                target: buttonHighlighter
                opacity: 1
            }
        }
    ]
    transitions: [
        Transition {
            reversible: true
            NumberAnimation {
                running: false
                properties: "opacity"
                duration: control.activateTransitionTime
                easing.type: Easing.InOutQuad
            }
        }
    ]
}

/*##^##
Designer {
    D{i:0;formeditorColor:"#000000";formeditorZoom:16;height:26;width:26}D{i:1}D{i:2}
}
##^##*/

