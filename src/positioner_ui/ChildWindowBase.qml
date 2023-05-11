import QtQuick 2.15
import "./controls"

/* due to QML Puppet bug, this template is only for manual copying */

Window {
    id: childWindow
    color: "#00000000"
    flags: Qt.Window | Qt.FramelessWindowHint
    width: 400
    height: 400
    visible: true

    signal hidden

    Rectangle {
        id: windowOverlay
        x: 200
        y: 200
        width: 100
        height: 33
        color: "#00000000"
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 0
        anchors.topMargin: 0
        property int overlayOffset: 20


        DragHandler {
            onActiveChanged: if(active) childWindow.startSystemMove()
        }



        Canvas {
            id: bevelCanvas
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d");

                context.beginPath();
                context.moveTo(0, windowOverlay.height);
                context.lineTo(windowOverlay.overlayOffset, 0);
                context.lineTo(windowOverlay.overlayOffset, windowOverlay.height);
                context.closePath();

                context.fillStyle = "#47B5FF";
                context.fill();
            }
        }



        Rectangle {
            id: windowOverlayBase
            width: windowOverlay.width - windowOverlay.overlayOffset
            height: windowOverlay.height
            color: "#47b5ff"
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 0
            anchors.rightMargin: 0
        }

        WindowOverlayMinusButton {
            id: controlMinusButton
            z: 1
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 17
            onClicked: childWindow.hidden()
        }

    }

    Rectangle {
        id: windowBase
        color: "#06283D"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: windowOverlay.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: 0
        anchors.bottomMargin: 0
        anchors.rightMargin: 0
        anchors.leftMargin: 0
    }

    MouseArea {
        id: resizeBottom
        height: 10
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 0
        anchors.leftMargin: 0
        anchors.bottomMargin: 0
        cursorShape: Qt.SizeVerCursor

        DragHandler{
            target: null
            onActiveChanged: if (active) { childWindow.startSystemResize(Qt.BottomEdge) }
        }
    }

}

/*##^##
Designer {
    D{i:0;formeditorZoom:2}D{i:2}D{i:3}D{i:4}D{i:5}D{i:1}D{i:6}D{i:8}D{i:7}
}
##^##*/
