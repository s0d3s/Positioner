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

    ToolTip{
        x: - Math.round(parent.width/2) - width
        y: Math.round((parent.height - height) / 2)
        opacity: 1
        visible: !parent.enabled && parent.hovered
        text: "Too many snapshots(>=N)"
        background: Rectangle{
            radius: 15
            border.width: 1
            border.color: "#eeeeee"
            color: "#eeeeee"
        }
    }

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
        id: buttonMain0
        x: 3
        y: 15

        width: 30
        height: 6
        color: control.buttonColor
        radius: 0
        border.width: 0
    }

    Rectangle {
        id: buttonMain1
        x: 15
        y: 3
        width: 6
        height: 30
        color: control.buttonColor
        radius: 0
        border.width: 0
    }

    states: [
        State {
            name: "normal"
            when: !control.down

            PropertyChanges {
                target: buttonMain0
                radius: 0
            }

            PropertyChanges {
                target: buttonMain1
                radius: 0
            }
        },
        State {
            name: "active"
            when: control.down

            PropertyChanges {
                target: buttonMain0
                radius: 3
            }

            PropertyChanges {
                target: buttonMain1
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
    D{i:0;formeditorColor:"#000000";formeditorZoom:6;height:36;width:36}D{i:1}D{i:2}D{i:3}
}
##^##*/

