import QtQuick 2.15
import QtQuick.Controls 2.15

AbstractButton {
    id: control
    width: 36
    height: 36
    focusPolicy: Qt.NoFocus
    display: AbstractButton.IconOnly
    implicitWidth: width
    implicitHeight: height
    leftPadding: 4
    rightPadding: 4

    property color buttonColor: control.enabled ? "#eeeeee" : "#aaaaaa"

    property int activateTransitionTime: 200
    property bool isActive: false

    background: buttonBackground

    Rectangle {
        id: buttonBackground
        width: parent.width
        height: parent.height
        color: control.buttonColor
        opacity: control.hovered && control.enabled ? 0.6 : 0
        radius: 18
        Behavior on opacity {
            NumberAnimation{duration: control.activateTransitionTime}
        }
    }

    Rectangle {
        id: buttonMain
        x: 3
        y: 15
        width: 30
        height: 6
        color: control.buttonColor
        radius: 0
        border.width: 0
    }

    states: [
        State {
            name: "normal"
            when: !control.down

            PropertyChanges {
                target: buttonMain
                radius: 0
            }
        },
        State {
            name: "active"
            when: control.down

            PropertyChanges {
                target: buttonMain
                radius: 3
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
    D{i:0;formeditorColor:"#000000";formeditorZoom:8;height:36;width:36}D{i:1}D{i:2}
}
##^##*/

