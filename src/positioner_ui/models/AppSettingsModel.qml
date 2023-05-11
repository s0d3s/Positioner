import QtQuick

QtObject{
    property bool showMainWindow: true

    property string appTitle: "Positioner"
    property string appVersionStr: "v1.1.12"
    property string appHomePage: "http://www.google.com/"

    property color firstSlotMainColor: "#7DD6E8"
    property color secondSlotMainColor: "#96B5FF"
    property color thirdSlotMainColor: "#977DE8"

    property bool launchOnSystemStartup: true
    property bool startMinimized: false
    property int restoreFromSnapshotOnSystemStartup: -1 // -1 >> false; 0 <= ? >> slot ind
}
