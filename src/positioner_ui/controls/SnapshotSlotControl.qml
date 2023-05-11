import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: control
    width: 60
    height: 60

    property int slotInd
    property bool isSlotExist: true
    property alias isActive: slotButton.isActive
    property alias indocatorColor: slotButton.indicatorColor

    signal saveToSlot(int toSlotInd)
    signal restoreFromSlot(int fromSlotInd)

    SnapshotSlotButton{
        id: slotButton
        x: 8
        y: 0
        isSlotExist: control.isSlotExist
        onClicked: if (!control.isActive && control.isSlotExist) control.restoreFromSlot(control.slotInd)
    }

    SnapshotSlotSaveButton {
        id: snapshotSlotSaveButton
        x: 8
        isSlotExist: control.isSlotExist

        anchors.top: slotButton.bottom
        anchors.topMargin: 2

        onClicked: control.saveToSlot(control.slotInd)
    }
}

/*##^##
Designer {
    D{i:0;formeditorZoom:4}D{i:1}D{i:2}
}
##^##*/
