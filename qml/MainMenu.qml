import QtQuick 2.15
import QtQuick.Layouts
import "./MainMenu"

Window {
    id: mainMenu

    visible: true
    width: 1000
    height: 600
    title: qsTr("产品进销存管理系统")

    property string currentRoute: "stock"
    property var loginWindow: null

    RowLayout {
        anchors.fill: parent
        spacing: 0

        SideNavigation {
            id: navigation
            Layout.fillHeight: true
            Layout.preferredWidth: expanded ? mainMenu.width * 0.15 : mainMenu.width * 0.012
            currentRoute: mainMenu.currentRoute
            onNavigate: function(route) { mainMenu.currentRoute = route }
            onProfileRequested: profilePopup.open()

            Behavior on Layout.preferredWidth {
                NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
            }
        }

        MainContentStack {
            Layout.fillWidth: true
            Layout.fillHeight: true
            route: mainMenu.currentRoute
        }
    }

    ProfilePopup {
        id: profilePopup
        onLogoutRequested: {
            if (mainMenu.loginWindow)
                mainMenu.loginWindow.show()
            mainMenu.close()
            mainMenu.destroy()
        }
    }
}
