import QtQuick 2.15
import QtQuick.Controls 2.15
import "./controls"

Window {
    id: childWindow
    color: "#00000000"
    flags: Qt.Window | Qt.FramelessWindowHint
    width: 400
    height: 400
    minimumHeight: 400
    visible: true

    property var targetListModel: testSnapshotListModel
    property int maxSnapshotsCount: 50

    signal hidden
    signal updateNeeded

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

        ListView {
            id: snapshotsListView
            anchors.left: parent.left
            anchors.right: snapshotControls.left
            anchors.top: windowTitle.bottom
            anchors.bottom: parent.bottom
            anchors.topMargin: 20
            anchors.rightMargin: 20
            anchors.leftMargin: 10
            anchors.bottomMargin: 20
            keyNavigationWraps: false
            layoutDirection: Qt.LeftToRight
            model: childWindow.targetListModel
            ListModel {
                id: testSnapshotListModel

                property bool enableSlotControls: true

                property bool hideShowIsActive: true

                property int selectedSnapshotIndex: 1

                property int indexAttachedToFirstSlot: -2
                property int indexAttachedToSecondSlot: -2
                property int indexAttachedToThirdSlot: -2

                // Support attaching few slots to one snapshot
                property bool isFirstSlotActive: true
                property bool isSecondSlotActive: false
                property bool isThirdSlotActive: false

                function hideShowButtonClicked(){
                    hideShowIsActive = !hideShowIsActive
                }

                function updateSlotsState(){}

                function activateCurrentSnapshot(){activateSnapshot(selectedSnapshotIndex)}
                function activateSnapshot(snapInd: int){
                    if (indexAttachedToFirstSlot === snapInd)
                        isFirstSlotActive = !isFirstSlotActive
                    else if (indexAttachedToSecondSlot === snapInd)
                        isSecondSlotActive = !isSecondSlotActive
                    else if (indexAttachedToThirdSlot === snapInd)
                        isThirdSlotActive = !isThirdSlotActive
                }

                function restoreSnapshotFromSlot(slotId: int){
                    console.log(slotId, indexAttachedToFirstSlot, indexAttachedToSecondSlot, indexAttachedToThirdSlot)
                    switch(slotId){
                    case 0:
                        activateSnapshot(indexAttachedToFirstSlot)
                        break
                    case 1:
                        activateSnapshot(indexAttachedToSecondSlot)
                        break
                    case 2:
                        activateSnapshot(indexAttachedToThirdSlot)
                    }
                }

                function setSnapshotName(index: int, name: string) {}

                function createSnapshotAndAttachTo(slotInd: int) {
                    unshiftNew()
                    attachSelectedToSlot(slotInd)
                    console.log(indexAttachedToFirstSlot, indexAttachedToSecondSlot, indexAttachedToThirdSlot)
                }

                function unshiftNew() {
                    insert(0, {
                               "snapshotDate": "2013-09-30 01:16:06",
                               "snapshotName": "Auto Snapshot",
                               "snapshotLocked": false
                           })
                    selectedSnapshotIndex = 0
                    if (indexAttachedToFirstSlot>=0)
                        indexAttachedToFirstSlot++
                    if (indexAttachedToSecondSlot>=0)
                        indexAttachedToSecondSlot++
                    if (indexAttachedToThirdSlot>=0)
                        indexAttachedToThirdSlot++
                }

                function attachSelectedToSlot(slotNum: int) {
                    if (indexAttachedToFirstSlot === selectedSnapshotIndex) {
                        indexAttachedToFirstSlot = -2
                    }
                    if (indexAttachedToSecondSlot === selectedSnapshotIndex) {
                        indexAttachedToSecondSlot = -2
                    }
                    if (indexAttachedToThirdSlot === selectedSnapshotIndex) {
                        indexAttachedToThirdSlot = -2
                    }
                    console.log(slotNum)
                    switch(slotNum) {
                    case 0:
                        indexAttachedToFirstSlot = selectedSnapshotIndex
                        break
                    case 1:
                        indexAttachedToSecondSlot = selectedSnapshotIndex
                        break
                    case 2:
                        indexAttachedToThirdSlot = selectedSnapshotIndex

                    }

                }

                ListElement {
                    snapshotDate: "2013-09-30 01:16:06"
                    snapshotName: "Auto Snapshot0"
                    snapshotLocked: false
                }

                ListElement {
                    snapshotDate: "2013-09-30 01:16:06"
                    snapshotName: "Auto Snapshot"
                    snapshotLocked: false
                }

                ListElement {
                    snapshotDate: "2013-09-30 01:16:06"
                    snapshotName: "Auto Snapshot"
                    snapshotLocked: false
                }

                ListElement {
                    snapshotDate: "2013-09-30 01:16:06"
                    snapshotName: "Auto Snapshot"
                    snapshotLocked: true
                }
            }
            delegate: Rectangle{
                id: viewDelegateBase
                height: 40
                width: snapshotsListView.width
                color: "#00000000"
                enabled: !snapshotLocked

                onHeightChanged: model.edit
                MouseArea {
                    id: rowMouseArea
                    onClicked: if (!snapshotLocked)
                                   snapshotsListView.model.selectedSnapshotIndex =
                                       index===snapshotsListView.model.selectedSnapshotIndex ? -1 : index;
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: !snapshotLocked

                    Rectangle {
                        id: dRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: 10
                        anchors.leftMargin: 5
                        anchors.topMargin: 5
                        anchors.bottomMargin: 5


                        color: "#00000000"
                        opacity: rowMouseArea.containsMouse ? 0.6 : 1

                        radius: index === snapshotsListView.model.selectedSnapshotIndex ? 0 : 10
                        border.width: rowMouseArea.containsMouse ? 3 : 1
                        border.color: "#ffdddddd"
                        Behavior on radius {
                            NumberAnimation {duration: 200}
                        }
                        Behavior on opacity {
                            NumberAnimation {duration: 100}
                        }
                        Behavior on border.width {
                            NumberAnimation {duration: 100}
                        }
                        Behavior on border.color {
                            ColorAnimation {duration: 500}
                        }


                        Text {
                            id: slotDate
                            text: snapshotDate
                            anchors.left: parent.left
                            anchors.leftMargin: 10

                            anchors.verticalCenter: parent.verticalCenter
                            font.bold: true
                            color: "#eeeeee"
                        }
                        TextInput {
                            text: !snapshotLocked ? snapshotName : "[Lock]"+snapshotName

                            clip: true

                            maximumLength: 36

                            onActiveFocusChanged: snapshotsListView.model.selectedSnapshotIndex = index
                            onTextEdited: snapshotsListView.model.setSnapshotName(index, text)

                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: slotDate.right
                            anchors.leftMargin: 20
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            font.bold: true
                            color: "#dddddd"
                        }

                        states: [
                            State {
                                name: "default"
                                when: false


                                PropertyChanges {
                                    target: dRow
                                    border.width: 1
                                    opacity: 1
                                    border.color: "#ffdddddd"
                                }
                            },
                            State {
                                name: "attachedToFSlot"
                                when: index === snapshotsListView.model.indexAttachedToFirstSlot

                                PropertyChanges {
                                    target: dRow
                                    border.color: mainWindow.firstSlotMainColor
                                    border.width: 2
                                }

                            },
                            State {
                                name: "attachedToSSlot"
                                when: index === snapshotsListView.model.indexAttachedToSecondSlot

                                PropertyChanges {
                                    target: dRow
                                    border.color: mainWindow.secondSlotMainColor
                                    border.width: 2
                                }

                            },
                            State {
                                name: "attachedToThSlot"
                                when: index === snapshotsListView.model.indexAttachedToThirdSlot

                                PropertyChanges {
                                    target: dRow
                                    border.color: mainWindow.thirdSlotMainColor
                                    border.width: 2
                                }

                            }
                        ]
                        transitions: [
                            Transition {
                                reversible: true
                                NumberAnimation {
                                    running: false
                                    properties: ""
                                    duration: 300
                                    easing.type: Easing.InOutQuad
                                }
                            }
                        ]
                    }
                }
            }
            ScrollIndicator.vertical: ScrollIndicator { }
        }

        Text {
            id: windowTitle
            x: 16
            y: 16
            color: "#dddddd"
            text: qsTr("Snapshots")
            font.pixelSize: 23
            font.underline: false
            font.bold: false
            font.family: "Arial"
            font.italic: false
            font.capitalization: Font.MixedCase
            font.weight: Font.Bold
        }

        Item {
            id: snapshotControls
            width: 88
            anchors.right: parent.right
            anchors.top: snapshotsListView.top
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12
            anchors.topMargin: 0
            anchors.rightMargin: 0

            SettingsSnapshotPlusButton{
                anchors.top: parent.top
                anchors.topMargin: 0
                id: settingsSnapshotPlusButton
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: snapshotsListView.model.unshiftNew()
                enabled: snapshotsListView.model.count < childWindow.maxSnapshotsCount

            }

            SettingsSnapshotMinusButton{
                id: settingsSnapshotMinusButton
                anchors.top: settingsSnapshotPlusButton.bottom
                anchors.topMargin: 15
                anchors.horizontalCenter: parent.horizontalCenter
                enabled: snapshotsListView.model.selectedSnapshotIndex !== -1
                onClicked: snapshotsListView.model.remove(snapshotsListView.model.selectedSnapshotIndex)
            }

            SettingsSnapshotSetButton {
                id: settingsSnapshotSetButton
                anchors.top: settingsSnapshotMinusButton.bottom
                anchors.topMargin: 36
                anchors.horizontalCenter: parent.horizontalCenter
                enabled: snapshotsListView.model.selectedSnapshotIndex !== -1
                onClicked: snapshotsListView.model.activateCurrentSnapshot()
            }

            Item {
                id: slotsControlItems
                width: 80
                height: 48
                anchors.top: settingsSnapshotSetButton.bottom
                anchors.topMargin: 30
                anchors.horizontalCenter: parent.horizontalCenter

                Text {
                    id: attachedToText
                    x: 7
                    y: 0
                    color: "#eeeeee"
                    text: qsTr("Attached to:")
                    font.pixelSize: 12
                }

                SettingsSnapshotAttachToButton {
                    id: settingsSnapshotAttachToButton0
                    buttonColor: mainWindow.firstSlotMainColor
                    isActive: snapshotsListView.model.selectedSnapshotIndex ===
                              snapshotsListView.model.indexAttachedToFirstSlot
                    x: 0
                    y: 22

                    onClicked:  if(snapshotsListView.model.selectedSnapshotIndex !== -1)
                                    snapshotsListView.model.attachSelectedToSlot(0)
                }

                SettingsSnapshotAttachToButton {
                    id: settingsSnapshotAttachToButton1
                    buttonColor: mainWindow.secondSlotMainColor
                    isActive: snapshotsListView.model.selectedSnapshotIndex ===
                              snapshotsListView.model.indexAttachedToSecondSlot
                    x: 27
                    y: 22

                    onClicked: if(snapshotsListView.model.selectedSnapshotIndex !== -1)
                                   snapshotsListView.model.attachSelectedToSlot(1)
                }

                SettingsSnapshotAttachToButton {
                    id: settingsSnapshotAttachToButton2
                    buttonColor: mainWindow.thirdSlotMainColor
                    isActive: snapshotsListView.model.selectedSnapshotIndex ===
                              snapshotsListView.model.indexAttachedToThirdSlot
                    x: 54
                    y: 22

                    onClicked: if(snapshotsListView.model.selectedSnapshotIndex !== -1)
                                   snapshotsListView.model.attachSelectedToSlot(2)
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
            childWindow.targetListModel = snapshotsListModel
            console.log("snapshotsListModel exist(model from python used)")

        } catch(error){
            if (error instanceof ReferenceError) {
                console.log("snapshotsListModel doesn`t exist(test model used)")
                childWindow.targetListModel = testSnapshotListModel
            }
        }
    }

}





/*##^##
Designer {
    D{i:0;formeditorZoom:1.25}D{i:2}D{i:3}D{i:4}D{i:5}D{i:1}D{i:8}D{i:7}D{i:29}D{i:31}
D{i:32}D{i:33}D{i:35}D{i:36}D{i:37}D{i:38}D{i:34}D{i:30}D{i:6}D{i:40}D{i:39}
}
##^##*/
