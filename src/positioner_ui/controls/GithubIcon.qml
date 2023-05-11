import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    width: 36
    height: 36

    MouseArea {
        property string homePage: mainWindow.appSettings.appHomePage
        id: mouseArea
        visible: true
        anchors.fill: parent

        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: Qt.openUrlExternally(homePage)
    }

    Image {
        opacity: 1
        id: github_icon
        x: 6
        y: 6
        source: "../assets/github_icon.svg"
        fillMode: Image.PreserveAspectFit
    }

    Image {
        id: github_icon_2
        x: 0
        y: 0
        width: 36
        height: 36
        opacity: 0
        source: "../assets/github_icon_2.svg"
        sourceSize.height: 48
        sourceSize.width: 48
        fillMode: Image.PreserveAspectFit
    }

    states: [
        State {
            name: "normal"
            when: !mouseArea.containsMouse

            PropertyChanges {
                target: github_icon
                opacity: 0.9
            }

            PropertyChanges {
                target: github_icon_2
                opacity: 0
            }
        },
        State {
            name: "hovered"
            when: mouseArea.containsMouse

            PropertyChanges {
                target: github_icon
                opacity: 0
            }

            PropertyChanges {
                target: github_icon_2
                opacity: 0.7
            }
        }
    ]
    transitions: [
        Transition {
            reversible: true
            NumberAnimation {
                properties: "opacity"
                duration: 300
                easing.type: Easing.InOutQuad
            }
        }
    ]
}

/*##^##
Designer {
    D{i:0;formeditorZoom:16;height:36;width:36}D{i:1}D{i:2}D{i:3}
}
##^##*/

