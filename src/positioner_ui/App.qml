import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.0
import "./controls"
import "./models"

Window {
    id: mainWindow

    AppSettingsModel { id: testAppSettings }
    property var appSettings: testAppSettings

    width: 400
    height: 200    

    x: Screen.width - width - 10
    y: Screen.desktopAvailableHeight - height - 10

    flags: Qt.Window | Qt.FramelessWindowHint

    minimumHeight: height
    minimumWidth: width

    maximumHeight: height
    maximumWidth: width

    visible: mainWindow.appSettings.showMainWindow

    onVisibleChanged: function (value){
        if (value){
            this.flags = this.flags | Qt.WindowStaysOnTopHint
            this.flags = this.flags & ~Qt.WindowStaysOnTopHint
        }
    }

    color: "#00000000"
    title: mainWindow.appSettings.appTitle

    property string appVersionStr: mainWindow.appSettings.appVersionStr
    property bool showAppSettingWindow: false
    property bool showSnaphotsSettingWindow: false
    property bool showDesktopFlagsWindow: false


    property color firstSlotMainColor: mainWindow.appSettings.firstSlotMainColor
    property color secondSlotMainColor: mainWindow.appSettings.secondSlotMainColor
    property color thirdSlotMainColor: mainWindow.appSettings.thirdSlotMainColor

    property alias targetSnapshotsListModel: snapshotsSettingWindow.targetListModel
    property alias targetDesktopFlagsModel: desktopFlagsWindow.targetListModel

    property int lastUpdateTimestamp: 0
    property int minUpdateInterval: 2000 // 2 sec

    function updateData() {
        if (lastUpdateTimestamp + minUpdateInterval > Date.now())
            return

        targetSnapshotsListModel.updateSlotsState()
        targetDesktopFlagsModel.updateFlags()
        lastUpdateTimestamp = Date.now()
    }

    AppSettingsWindow {
        id: appSettingWindow
        visible: mainWindow.showAppSettingWindow
        onHidden: mainWindow.showAppSettingWindow = false
    }

    SnapshotSettingsWindow {
        id: snapshotsSettingWindow
        visible: mainWindow.showSnaphotsSettingWindow
        onHidden: mainWindow.showSnaphotsSettingWindow = false

        onUpdateNeeded: mainWindow.updateData()
    }

    DesktopFlagsWindow {
        id: desktopFlagsWindow
        visible: mainWindow.showDesktopFlagsWindow
        onHidden: mainWindow.showDesktopFlagsWindow = false

        onUpdateNeeded: mainWindow.updateData()
    }



    onActiveChanged: mainWindow.updateData()

    Component.onCompleted: {
        try{
            mainWindow.appSettings = appSettingsModel
            console.log("appSettingsModel exist(model from python used)")

        } catch(error){
            if (error instanceof ReferenceError) {
                console.log("appSettingsModel doesn`t exist(test model used)")
                mainWindow.appSettings = appSettings
            }
        }

        appSettingWindow.x = mainWindow.x - appSettingWindow.width - 10
        appSettingWindow.y = mainWindow.y

        snapshotsSettingWindow.x = mainWindow.x
        snapshotsSettingWindow.y = mainWindow.y - mainWindow.height*2 - 10

        desktopFlagsWindow.x = mainWindow.x - desktopFlagsWindow.width - 10
        desktopFlagsWindow.y = mainWindow.y - mainWindow.height*2 - 10
    }

    Rectangle {
        id: appOverlay
        x: 300
        y: 200
        width: 100
        height: 30
        color: "#00000000"
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 0
        anchors.topMargin: 0
        property int overlayOffset: 20

        DragHandler {
            onActiveChanged: if(active) mainWindow.startSystemMove()
        }


        Canvas {
            id: bevelCanvas
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d");

                context.beginPath();
                context.moveTo(0, appOverlay.height);
                context.lineTo(appOverlay.overlayOffset, 0);
                context.lineTo(appOverlay.overlayOffset, appOverlay.height);
                context.closePath();

                context.fillStyle = "#47B5FF";
                context.fill();
            }
        }





        Rectangle {
            id: appOverlayBevel
            width: appOverlay.width - appOverlay.overlayOffset
            height: appOverlay.height
            color: "#47b5ff"
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 0
            anchors.rightMargin: 0
        }



        WindowOverlayMinusButton {
            id: controlMinusButton
            x: 57
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 17
            onClicked: {
                console.log("hiding...")
                mainWindow.showAppSettingWindow = false
                mainWindow.showSnaphotsSettingWindow = false
                mainWindow.showDesktopFlagsWindow = false

                mainWindow.appSettings.showMainWindow = false
            }
        }
        AppSettingsButton {
            id: appSettingsButton;
            width: 30
            height: 28
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: controlMinusButton.left;
            anchors.rightMargin: 3
            onClicked: mainWindow.showAppSettingWindow = !mainWindow.showAppSettingWindow
            isActive: mainWindow.showAppSettingWindow
        }
    }

    Rectangle {
        id: appBase
        color: "#06283d"
        border.width: 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: appOverlay.bottom
        anchors.bottom: parent.bottom
        focus: true
        z: 1
        anchors.topMargin: 0

        onFocusChanged: console.log("main appBase Focus")

        Rectangle {
            id: appToolbar
            x: 7
            y: 88
            height: 50
            color: "#47b5ff"
            border.color: "#00000000"
            border.width: 0
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0
            anchors.rightMargin: 0
            anchors.leftMargin: 0

            DragHandler {
                onActiveChanged: if(active) mainWindow.startSystemMove()
            }

            Text {
                id: appTitleShadow
                y: 3
                width: 207
                height: 36
                visible: false
                color: "#000000"
                text: "Positioner"
                anchors.left: appTitle.right
                anchors.bottom: appTitle.top
                font.letterSpacing: 2
                font.pixelSize: 32
                horizontalAlignment: Text.AlignLeft
                anchors.leftMargin: -205
                anchors.bottomMargin: -34
                font.family: "Arial"
                font.styleName: "Bold"
                font.wordSpacing: 0
            }

            Text {
                id: appTitle
                y: 5
                width: 207
                height: 36
                color: "#eeeeee"
                text: "Positioner"
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                font.letterSpacing: 2
                font.pixelSize: 32
                horizontalAlignment: Text.AlignLeft
                font.wordSpacing: 0
                font.styleName: "Regular"
                font.family: "Orbitron"
                anchors.leftMargin: 8
                anchors.bottomMargin: 8
            }

            GithubIcon {
                id: githubIcon
                x: 355
                y: 4
                anchors.right: parent.right
                anchors.bottom: appTitle.bottom
                anchors.bottomMargin: 0
                anchors.rightMargin: 10
            }

            Text {
                id: appVersion
                color: "#dddddd"
                text: mainWindow.appVersionStr
                anchors.left: appTitle.right
                anchors.top: appTitle.verticalCenter
                font.pixelSize: 12
                anchors.topMargin: 0
                anchors.leftMargin: 0
            }

        }

        SwitchIconsButton {
            id: switchDeskIconsButton
            enabled: mainWindow.targetSnapshotsListModel.enableSlotControls
            x: 17
            y: 33
            width: 70
            height: 70
            isActive: mainWindow.targetSnapshotsListModel.hideShowIsActive
            onClicked: mainWindow.targetSnapshotsListModel.hideShowButtonClicked()
        }

        Text {
            id: slotsTitle
            x: 111
            y: 8
            opacity: 0.3
            color: "#dddddd"
            text: "Snapshot Slots"
            font.pointSize: 12
            font.family: "Arial"
        }

        Item {
            id: slotsContainer
            x: 104
            y: 43
            width: 192
            height: 63
            enabled: mainWindow.targetSnapshotsListModel.enableSlotControls

            SnapshotSlotControl {
                id: snapshotSlotControl0
                slotInd: 0

                indocatorColor: mainWindow.firstSlotMainColor
                isActive: mainWindow.targetSnapshotsListModel.isFirstSlotActive
                isSlotExist: mainWindow.targetSnapshotsListModel.indexAttachedToFirstSlot !== -2
                x: 0
                y: 0

                onSaveToSlot: (slotInd) => mainWindow.targetSnapshotsListModel.createSnapshotAndAttachTo(slotInd)
                onRestoreFromSlot: (fromSlotInd)=>mainWindow.targetSnapshotsListModel.restoreSnapshotFromSlot(fromSlotInd)
            }

            SnapshotSlotControl {
                id: snapshotSlotControl1
                slotInd: 1
                indocatorColor: mainWindow.secondSlotMainColor
                isActive: mainWindow.targetSnapshotsListModel.isSecondSlotActive
                isSlotExist: mainWindow.targetSnapshotsListModel.indexAttachedToSecondSlot !== -2
                x: 66
                y: 0

                onSaveToSlot: (slotInd) => mainWindow.targetSnapshotsListModel.createSnapshotAndAttachTo(slotInd)

                onRestoreFromSlot: (fromSlotInd)=>mainWindow.targetSnapshotsListModel.restoreSnapshotFromSlot(fromSlotInd)
            }

            SnapshotSlotControl {
                id: snapshotSlotControl2
                slotInd: 2

                indocatorColor: mainWindow.thirdSlotMainColor
                isActive: mainWindow.targetSnapshotsListModel.isThirdSlotActive
                isSlotExist: mainWindow.targetSnapshotsListModel.indexAttachedToThirdSlot !== -2
                x: 132
                y: 0

                onSaveToSlot: (slotInd) => mainWindow.targetSnapshotsListModel.createSnapshotAndAttachTo(slotInd)
                onRestoreFromSlot: (fromSlotInd) => mainWindow.targetSnapshotsListModel.restoreSnapshotFromSlot(fromSlotInd)
            }
        }

        SettingsSnapshotButton {
            id: settingsSnapshotButton
            x: 352
            y: 19
            anchors.right: parent.right
            anchors.rightMargin: 8
            onClicked: mainWindow.showSnaphotsSettingWindow = !mainWindow.showSnaphotsSettingWindow
            isActive: mainWindow.showSnaphotsSettingWindow
        }

        SettingsDesktopButton {
            id: settingsDesktopButton
            x: 352
            y: 66
            onClicked: mainWindow.showDesktopFlagsWindow = !mainWindow.showDesktopFlagsWindow
            isActive: mainWindow.showDesktopFlagsWindow
        }


    }
}




/*##^##
Designer {
    D{i:0;formeditorZoom:6}D{i:1}D{i:2}D{i:3}D{i:4}D{i:6}D{i:7}D{i:8}D{i:9}D{i:10}D{i:5}
D{i:13}D{i:14}D{i:15}D{i:16}D{i:17}D{i:12}D{i:18}D{i:19}D{i:21}D{i:22}D{i:23}D{i:20}
D{i:24}D{i:25}D{i:11}
}
##^##*/
