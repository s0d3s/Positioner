import QtQuick 2.15
import QtQuick.Controls 2.15

AbstractButton {
    id: conrol
    width: 26
    height: 10
    implicitWidth: width
    implicitHeight: height

    HoverHandler {
        id: hoverHandler
        cursorShape: Qt.PointingHandCursor
    }

    Rectangle {
        id: highlighter
        x: 1
        y: 1
        width: 24
        height: 8
        opacity: 0
        color: "#ffffff"
        radius: 3
        border.width: 0
    }

    Rectangle {
        id: buttonBase
        x: 3
        y: 3
        width: 20
        height: 4
        color: "#eeeeee"
        border.width: 0
    }

    states: [
        State {
            name: "normal"
            when: !hoverHandler.hovered

            PropertyChanges {
                target: highlighter
                opacity: 0
            }
        },
        State {
            name: "hovered"
            when: hoverHandler.hovered

            PropertyChanges {
                target: highlighter
                opacity: 0.4
            }
        }
    ]
    transitions: [
        Transition {
            reversible: true
            NumberAnimation {
                properties: "opacity"
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }
    ]

}

/*##^##
Designer {
    D{i:0;formeditorColor:"#000000";formeditorZoom:10}D{i:1}D{i:2}D{i:3}
}
##^##*/
