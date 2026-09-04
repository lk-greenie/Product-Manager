import QtQuick 2.15

// 轻量导航图标，不依赖外部图标字体或图片资源。
// 每个图标由少量原生 QML 图元构成，适合深色/浅色导航背景复用。
Item {
    id: root

    property string kind: "inventory"
    property color color: "#ffffff"

    implicitWidth: 20
    implicitHeight: 20

    // 个人资料
    Rectangle { visible: root.kind === "profile"; x: 7; y: 2; width: 6; height: 6; radius: 3; color: root.color }
    Rectangle { visible: root.kind === "profile"; x: 3; y: 11; width: 14; height: 7; radius: 3.5; color: root.color }

    // 库存：三个货箱
    Rectangle { visible: root.kind === "inventory"; x: 2; y: 3; width: 7; height: 6; radius: 1; color: root.color }
    Rectangle { visible: root.kind === "inventory"; x: 11; y: 3; width: 7; height: 6; radius: 1; color: root.color }
    Rectangle { visible: root.kind === "inventory"; x: 6.5; y: 11; width: 7; height: 6; radius: 1; color: root.color }

    // 交易记录与全部记录
    Rectangle { visible: root.kind === "records" || root.kind === "recordsAll"; x: 3; y: 3; width: 14; height: 2; radius: 1; color: root.color }
    Rectangle { visible: root.kind === "records" || root.kind === "recordsAll"; x: 3; y: 9; width: 14; height: 2; radius: 1; color: root.color }
    Rectangle { visible: root.kind === "records" || root.kind === "recordsAll"; x: 3; y: 15; width: 10; height: 2; radius: 1; color: root.color }

    // 数据可视化与销售额：柱形图
    Rectangle { visible: root.kind === "visual" || root.kind === "sales"; x: 3; y: 11; width: 3; height: 6; radius: 1; color: root.color }
    Rectangle { visible: root.kind === "visual" || root.kind === "sales"; x: 8.5; y: 7; width: 3; height: 10; radius: 1; color: root.color }
    Rectangle { visible: root.kind === "visual" || root.kind === "sales"; x: 14; y: 3; width: 3; height: 14; radius: 1; color: root.color }

    // AI：四角星
    Rectangle { visible: root.kind === "assistant"; x: 8; y: 2; width: 4; height: 16; radius: 2; color: root.color }
    Rectangle { visible: root.kind === "assistant"; x: 2; y: 8; width: 16; height: 4; radius: 2; color: root.color }
    Rectangle { visible: root.kind === "assistant"; x: 6; y: 6; width: 8; height: 8; rotation: 45; color: root.color }

    // 收入/支出/利润使用方向箭头；成本使用圆形成本标记。
    Text {
        visible: root.kind === "income" || root.kind === "expense" || root.kind === "profit"
        anchors.centerIn: parent
        text: root.kind === "income" ? "↑" : root.kind === "expense" ? "↓" : "↗"
        color: root.color
        font.pixelSize: 20
        font.weight: Font.DemiBold
    }
    Rectangle { visible: root.kind === "cost"; x: 3; y: 3; width: 14; height: 14; radius: 7; border.color: root.color; border.width: 2; color: "transparent" }
    Rectangle { visible: root.kind === "cost"; x: 8; y: 6; width: 4; height: 8; radius: 1; color: root.color }
}
