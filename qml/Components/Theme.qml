pragma Singleton
import QtQuick 2.15

// 全局主题单例：集中所有硬编码颜色、字号、圆角、尺寸。
// 通过 qmldir 声明为单例（singleton Theme 1.0 Theme.qml）。
// 使用方式：import "../Components" 后直接引用 Theme.primary 等。
QtObject {
    id: theme

    // ---------- 主色系 ----------
    readonly property color primary: "#0099ff"        // 主色蓝（导航栏、主按钮、顶部条）
    readonly property color primaryDark: "#008deb"     // 主色悬停/按下更深的蓝
    readonly property color accentLight: "lightblue"   // 渐变中段浅蓝

    // ---------- 中性色 ----------
    readonly property color headerBg: "#f0f0f0"        // 表头背景
    readonly property color border: "#cccccc"          // 单元格/表头边框
    readonly property color statusBar: "lightgrey"     // 底部状态栏 / 次按钮悬停
    readonly property color surface: "white"           // 输入框/单元格底色
    readonly property color textOnPrimary: "white"     // 主色上的文字（白字）
    readonly property color textPrimary: "black"       // 常规文字

    // ---------- 状态色 ----------
    readonly property color warningCell: "#fff3bf"
    readonly property color expiredCell: "#ffd6d6"
    readonly property color expenseRow: "#ffe2e2"
    readonly property color incomeRow: "#dcfce7"

    // ---------- 图表色 ----------
    readonly property var chartColors: ["#2563eb", "#7c3aed", "#ea580c", "#0891b2", "#4d7c0f", "#c026d3", "#475569", "#ca8a04"]

    // ---------- 字号 ----------
    readonly property int fontSmall: 14
    readonly property int fontNormal: 16
    readonly property int fontLarge: 18
    readonly property int fontTitle: 24

    // ---------- 圆角 ----------
    readonly property int radiusSmall: 5               // 按钮/输入框
    readonly property int radiusLarge: 10              // 卡片/导航项/登录面板

    // ---------- 常用尺寸 ----------
    readonly property int labelWidth: 50               // 表单 label 统一宽度
    readonly property int controlHeight: 30            // 输入框/按钮统一高度
    readonly property int statusBarHeight: 20          // 底部状态栏高度
}
