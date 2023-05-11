import QtQuick 2.15
import "./controls"

/* due to QML Puppet bug, this template is only for manual copying */
import QtQuick.Controls 6.2

Window {
    id: childWindow
    color: "#00000000"
    flags: Qt.Window | Qt.FramelessWindowHint
    width: 300
    height: 400
    visible: true

    signal hidden
    signal updateNeeded

    property var targetListModel: testDesktopFlagsModel

    onActiveChanged: childWindow.updateNeeded()

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

        Text {
            id: windowTitle
            x: 20
            y: 15
            color: "#dddddd"
            text: qsTr("Desktop Features")
            font.pixelSize: 23
            font.italic: false
            font.bold: false
            font.weight: Font.Bold
            font.capitalization: Font.MixedCase
            font.family: "Arial"
        }

        ListView {
            id: desktopFlagsListView
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: windowTitle.bottom
            anchors.bottom: parent.bottom
            anchors.topMargin: 20
            anchors.rightMargin: 20
            anchors.leftMargin: 20
            anchors.bottomMargin: 46

            model: childWindow.targetListModel
            ListModel {
                id: testDesktopFlagsModel

                function toggleFlag(flagIndex: int) {console.log("Toggling", flagIndex, "flag")}
                function updateFlags() {}

                ListElement {
                    flag: 0x1
                    name: "FWF_AUTOARRANGE"
                    title: "Auto arrange"
                    description: "Automatically arrange the icons"
                    isActive: false
                }
                ListElement {
                    flag: 0x4
                    name: "FWF_SNAPTOGRID"
                    title: "Snap to grid"
                    description: "Snap icon positions to grid"
                    isActive: false
                }
                ListElement {
                    flag: 0x1
                    name: "FWF_AUTOARRANGE"
                    title: "Auto arrange"
                    description: "Automatically arrange the icons"
                    isActive: false
                }
                ListElement {
                    flag: 0x4
                    name: "FWF_SNAPTOGRID"
                    title: "Snap to grid"
                    description: "Snap icon positions to grid"
                    isActive: false
                }
                ListElement {
                    flag: 0x1
                    name: "FWF_AUTOARRANGE"
                    title: "Auto arrange"
                    description: "Automatically arrange the icons"
                    isActive: false
                }
                ListElement {
                    flag: 0x4
                    name: "FWF_SNAPTOGRID"
                    title: "Snap to grid"
                    description: "Snap icon positions to grid"
                    isActive: true
                }
                ListElement {
                    flag: 0x1
                    name: "FWF_AUTOARRANGE"
                    title: "Auto arrange"
                    description: "Automatically arrange the icons"
                    isActive: false
                }
                ListElement {
                    flag: 0x4
                    name: "FWF_SNAPTOGRID"
                    title: "Snap to grid"
                    description: "Snap icon positions to grid"
                    isActive: false
                }
                ListElement {
                    flag: 0x1
                    name: "FWF_AUTOARRANGE"
                    title: "Auto arrange"
                    description: "Automatically arrange the icons"
                    isActive: true
                }
                ListElement {
                    flag: 0x4
                    name: "FWF_SNAPTOGRID"
                    title: "Snap to grid"
                    description: "Snap icon positions to grid"
                    isActive: false
                }
            }

            delegate: Item {
                height: 45

                width: desktopFlagsListView.width

                DesktopFlagSwitch {
                    id: desktopFlagSwitch
                    anchors.verticalCenter: parent.verticalCenter
                    checked: isActive
                    onReleased: desktopFlagsListView.model.toggleFlag(index)
                }

                Item {
                    height: flagTitle.height + flagDescription.height
                    anchors.left: desktopFlagSwitch.right
                    anchors.right: parent.right
                    anchors.leftMargin: 30
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        id: flagTitle
                        color: "#eeeeee"
                        text: title
                        anchors.left: parent.left
                        anchors.top: parent.top
                        font.pixelSize: 14
                        anchors.leftMargin: 0
                        anchors.topMargin: 0
                    }

                    Text {
                        id: flagDescription
                        opacity: 0.6
                        color: "#dddddd"
                        text: description
                        anchors.left: parent.left
                        anchors.top: flagTitle.bottom
                        font.pixelSize: 10
                        anchors.leftMargin: 0
                    }
                }
            }
        }
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

    Component.onCompleted: {
        try{
            childWindow.targetListModel = desktopFlagsModel
            console.log("desktopFlagsModel exist(model from python used)")

        } catch(error){
            if (error instanceof ReferenceError) {
                console.log("desktopFlagsModel doesn`t exist(test model used)")
                childWindow.targetListModel = testDesktopFlagsModel
            }
        }
    }

}


