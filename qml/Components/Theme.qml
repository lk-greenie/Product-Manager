pragma Singleton
import QtQuick 2.15

// 全局主题单例：集中颜色、字号、圆角和尺寸，页面只引用主题令牌。
QtObject {
    id: theme

    // 现代浅色工作台色板
    readonly property color appBackground: "#f4f7fb"
    readonly property color sidebar: "#152238"
    readonly property color sidebarHover: "#213554"
    readonly property color primary: "#2563eb"
    readonly property color primaryDark: "#1d4ed8"
    readonly property color primarySoft: "#dbeafe"
    readonly property color accentLight: "#eff6ff"

    // 中性色
    readonly property color headerBg: "#eef3f8"
    readonly property color border: "#d8e0ea"
    readonly property color borderStrong: "#c2cfdd"
    readonly property color statusBar: "#e8eef5"
    readonly property color surface: "#ffffff"
    readonly property color surfaceMuted: "#f8fafc"
    readonly property color textOnPrimary: "#ffffff"
    readonly property color textPrimary: "#172033"
    readonly property color textSecondary: "#526176"
    readonly property color textMuted: "#7a8799"

    // 状态色
    readonly property color warningCell: "#fff7d6"
    readonly property color expiredCell: "#ffe4e6"
    readonly property color expenseRow: "#fff1f2"
    readonly property color incomeRow: "#ecfdf3"
    readonly property color success: "#15803d"
    readonly property color warning: "#b45309"
    readonly property color danger: "#b42318"

    // 图表色
    readonly property var chartColors: ["#2563eb", "#7c3aed", "#ea580c", "#0891b2", "#4d7c0f", "#c026d3", "#475569", "#ca8a04"]

    // 字号
    readonly property int fontSmall: 13
    readonly property int fontNormal: 14
    readonly property int fontLarge: 18
    readonly property int fontTitle: 26
    readonly property int fontSection: 16

    // 圆角
    readonly property int radiusSmall: 6
    readonly property int radiusMedium: 8
    readonly property int radiusLarge: 12

    // 常用尺寸
    readonly property int labelWidth: 78
    readonly property int controlHeight: 36
    readonly property int compactControlHeight: 32
    readonly property int statusBarHeight: 28
    readonly property int pagePadding: 20
    readonly property int sectionSpacing: 14
    readonly property int navExpandedWidth: 224
    readonly property int navCollapsedWidth: 64
}
