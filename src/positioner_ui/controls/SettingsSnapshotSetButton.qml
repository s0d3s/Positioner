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

    ToolTip{

        x: - Math.round(parent.width/2) - width
        y: Math.round((parent.height - height) / 2)
        opacity: 1
        visible: parent.hovered
        text: "Activate Snapshot"
        background: Rectangle{
            radius: 15
            border.width: 1
            border.color: "#eeeeee"
            color: "#eeeeee"
        }
    }

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

    Image {
        id: buttonMain
        x: 7
        y: 7
        width: 22
        opacity: control.down ? 0.7 : 1
        source: control.enabled ? "../assets/activate_snapshot.svg" : "../assets/activate_snapshot__disabled.svg"
        sourceSize.height: 30
        sourceSize.width: 30
        fillMode: Image.PreserveAspectFit
    }
}

/*##^##
Designer {
    D{i:0;formeditorColor:"#000000";formeditorZoom:8;height:36;width:36}D{i:1}D{i:3}D{i:4}
}
##^##*/

