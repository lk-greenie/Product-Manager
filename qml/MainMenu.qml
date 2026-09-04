import QtQuick 2.15
import "./Components"
import "./MainMenu"

Window {
    id: mainMenu

    visible: true
    width: 1280
    height: 760
    minimumWidth: 960
    minimumHeight: 620
    color: Theme.appBackground
    title: qsTr("产品进销存管理系统")

    property string currentRoute: "stock"
    property var loginWindow: null

    Rectangle {
        anchors.fill: parent
        color: Theme.appBackground
        z: -1
    }

    SideNavigation {
        id: navigation
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: expanded ? Theme.navExpandedWidth : Theme.navCollapsedWidth
        currentRoute: mainMenu.currentRoute
        onNavigate: function(route) { mainMenu.currentRoute = route }
    }

    MainContentStack {
        id: mainContent
        anchors.left: navigation.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        route: mainMenu.currentRoute
        onLogoutRequested: {
            if (mainMenu.loginWindow)
                mainMenu.loginWindow.show()
            mainMenu.close()
            mainMenu.destroy()
        }
    }
}
