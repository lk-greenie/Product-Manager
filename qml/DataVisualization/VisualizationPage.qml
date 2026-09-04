import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts
import "../Components"

Page {
    id: root

    background: Rectangle { color: Theme.appBackground }

    property string metric: "cost"
    property string pageTitle: qsTr("成本统计")
    property var breakdown: []
    property var trend: []
    property int topN: 6
    property bool detailExpanded: false
    readonly property var scaleLabels: [qsTr("按日"), qsTr("按月"), qsTr("按年")]
    readonly property bool isProfit: metric === "profit"
    // 成本/销售额：单一饼图，展示 breakdown 前 topN 项
    readonly property var singlePieItems: {
        let arr = breakdown.slice()
        arr.sort(function(a, b) { return Math.abs(Number(b.value)) - Math.abs(Number(a.value)) })
        return arr.slice(0, topN)
    }
    // 盈利/亏损分开
    readonly property var profitItems: breakdown.filter(function(i) { return Number(i.value) > 0 })
    readonly property var lossItems: breakdown.filter(function(i) { return Number(i.value) < 0 })
    // 只取占比最大的前 topN 项用于饼图与图例，避免过多小扇区
    readonly property var topProfitItems: {
        let arr = profitItems.slice()
        arr.sort(function(a, b) { return Math.abs(Number(b.value)) - Math.abs(Number(a.value)) })
        return arr.slice(0, topN)
    }
    readonly property var topLossItems: {
        let arr = lossItems.slice()
        arr.sort(function(a, b) { return Math.abs(Number(b.value)) - Math.abs(Number(a.value)) })
        return arr.slice(0, topN)
    }

    readonly property real maxBreakdown: {
        let m = 0
        for (let i = 0; i < breakdown.length; ++i)
            m = Math.max(m, Math.abs(Number(breakdown[i].value || 0)))
        return m
    }

    // 颜色：按商品在 breakdown 中的原始下标固定分配，保证饼图/图例/柱状一致
    // 保留最多两位小数，去掉多余尾零，避免金额被四舍五入成整数
    function fmtNum(v) {
        const n = Number(v)
        if (isNaN(n)) return "0"
        return n.toFixed(2).replace(/\.?0+$/, "")
    }
    function fmtMoney(v) { return qsTr("￥%1").arg(root.fmtNum(v)) }

    function showTip(label, value, itemRef, lx, ly) {
        tipText.text = label + "：" + fmtMoney(value)
        const p = root.mapFromItem(itemRef, lx, ly)
        tip.x = Math.max(8, Math.min(root.width - tip.width - 8, p.x + 14))
        tip.y = Math.max(8, Math.min(root.height - tip.height - 8, p.y + 14))
        tip.visible = true
        tip.opacity = 1
    }

    function hideTip() {
        tip.opacity = 0
        tip.visible = false
    }

    Timer {
        id: refreshDebounce
        interval: 120
        repeat: false
        onTriggered: root.loadData()
    }

    function refresh() { refreshDebounce.restart() }

    function loadData() {
        if (categoryBox.currentIndex < 0) {
            statusLabel.text = qsTr("请先选择分类")
            return
        }
        const category = categoryBox.currentText
        const isAllProduct = productBox.currentIndex < 0 || productBox.currentText === qsTr("全部")
        const name = isAllProduct ? "" : productBox.currentText
        breakdown = TableDisplay.chartBreakdown(metric, category, name,
                                                startField.displayText, endField.displayText)
        const scale = scaleBox.currentIndex === 1 ? "month" : scaleBox.currentIndex === 2 ? "year" : "day"
        trend = TableDisplay.chartTrend(metric, category, name, scale, startField.displayText, endField.displayText)
        statusLabel.text = ""
    }

    function updatePies() {
        // 各 PieChartItem 通过 onItemsChanged 自动重绘，此处无需手动填充
    }

    onBreakdownChanged: updatePies()

    Component.onCompleted: {
        productBox.model = TableDisplay.allProducts(categoryBox.currentText)
        productBox.currentIndex = 0
        refresh()
    }

    Rectangle {
        id: tip
        visible: false
        z: 9999
        color: Theme.surface
        border.color: Theme.borderStrong
        border.width: 1
        radius: Theme.radiusSmall
        opacity: 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
        Behavior on x { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
        width: tipText.implicitWidth + 24
        height: tipText.implicitHeight + 14
        Label {
            id: tipText
            anchors.fill: parent
            anchors.margins: 7
            font.pixelSize: Theme.fontSmall
        }
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: Theme.pagePadding
        spacing: Theme.sectionSpacing

        PageTitle {
            title: root.pageTitle
            subtitle: qsTr("按分类、商品和时间范围查看经营趋势")
        }

        Flow {
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            spacing: 10

            Label {
                text: qsTr("分类：")
                color: Theme.textSecondary
                height: Theme.controlHeight
                verticalAlignment: Text.AlignVCenter
            }
            StyledComboBox {
                id: categoryBox
                width: 150
                height: Theme.controlHeight
                model: TableDisplay.allCategories()
                currentIndex: 0
                displayText: currentIndex >= 0 ? currentText : qsTr("请选择")
                onActivated: {
                    TableDisplay.updatecnameModel(currentText)
                    productBox.model = TableDisplay.allProducts(currentText)
                    productBox.currentIndex = 0
                    root.refresh()
                }
            }
            Label {
                text: qsTr("商品：")
                color: Theme.textSecondary
                height: Theme.controlHeight
                verticalAlignment: Text.AlignVCenter
            }
            StyledComboBox {
                id: productBox
                width: 170
                height: Theme.controlHeight
                model: []
                currentIndex: 0
                displayText: currentIndex >= 0 ? currentText : qsTr("全部")
                onActivated: root.refresh()
            }
            Label {
                text: qsTr("尺度：")
                color: Theme.textSecondary
                height: Theme.controlHeight
                verticalAlignment: Text.AlignVCenter
            }
            StyledComboBox {
                id: scaleBox
                width: 112
                height: Theme.controlHeight
                model: root.scaleLabels
                currentIndex: 0
                displayText: currentIndex >= 0 ? root.scaleLabels[currentIndex] : qsTr("选择尺度")
                onActivated: root.refresh()
            }
            DatePickerField {
                id: startField
                width: 132
                height: Theme.compactControlHeight
                placeholderText: qsTr("起始日期")
                onDatePicked: root.refresh()
            }
            DatePickerField {
                id: endField
                width: 132
                height: Theme.compactControlHeight
                placeholderText: qsTr("终止日期")
                onDatePicked: root.refresh()
            }
            PrimaryButton { text: qsTr("查询"); onClicked: root.refresh() }
        }

        Label {
            id: statusLabel
            color: Theme.danger
            visible: text !== ""

            Timer {
                id: statusTimer
                interval: 2600
                repeat: false
                onTriggered: statusLabel.text = ""
            }

            onTextChanged: {
                if (text !== "")
                    statusTimer.restart()
                else
                    statusTimer.stop()
            }
        }

        Connections {
            target: TableDisplay
            function onDataChanged() {
                categoryBox.model = TableDisplay.allCategories()
                TableDisplay.updatecnameModel(categoryBox.currentText)
                productBox.model = TableDisplay.allProducts(categoryBox.currentText)
                root.refresh()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 260
            visible: productBox.currentIndex < 0 || productBox.currentText === qsTr("全部")

            // 成本/销售额：单一饼图（图例在左，前 topN 项）
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !root.isProfit
                Label { text: qsTr("占比饼图"); font.bold: true }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 8
                    ColumnLayout {
                        Layout.preferredWidth: 150
                        Layout.fillHeight: true
                        spacing: 3
                        Repeater {
                            model: root.singlePieItems
                            delegate: RowLayout {
                                spacing: 3
                                Rectangle { Layout.preferredWidth: 12; Layout.preferredHeight: 12; radius: 2; color: Theme.chartColors[index % Theme.chartColors.length] }
                                Label { text: modelData.label; font.pixelSize: Theme.fontSmall; elide: Text.ElideRight }
                            }
                        }
                    }
                    PieChartItem {
                        id: singlePieItem
                        items: root.singlePieItems
                        Layout.preferredWidth: 220
                        Layout.preferredHeight: 180
                        Layout.alignment: Qt.AlignVCenter
                        onHovered: function(label, value, lx, ly) { root.showTip(label, value, singlePieItem, lx, ly) }
                         onHoverOff: root.hideTip()
                    }
                }
            }

            // 盈利饼图：图例在左（前 topN 项），饼图适中大小
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.isProfit
                Label { text: qsTr("盈利饼图"); font.bold: true }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 8
                    ColumnLayout {
                        Layout.preferredWidth: 150
                        Layout.fillHeight: true
                        spacing: 3
                        Repeater {
                            model: root.topProfitItems
                            delegate: RowLayout {
                                spacing: 3
                                Rectangle { Layout.preferredWidth: 12; Layout.preferredHeight: 12; radius: 2; color: Theme.chartColors[index % Theme.chartColors.length] }
                                Label { text: modelData.label; font.pixelSize: Theme.fontSmall; elide: Text.ElideRight }
                            }
                        }
                    }
                    PieChartItem {
                        id: profitPieItem
                        items: root.topProfitItems
                        Layout.preferredWidth: 220
                        Layout.preferredHeight: 180
                        Layout.alignment: Qt.AlignVCenter
                        onHovered: function(label, value, lx, ly) { root.showTip(label, value, profitPieItem, lx, ly) }
                         onHoverOff: root.hideTip()
                    }
                }
            }

            // 亏损饼图
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.isProfit
                Label { text: qsTr("亏损饼图"); font.bold: true }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 8
                    ColumnLayout {
                        Layout.preferredWidth: 150
                        Layout.fillHeight: true
                        spacing: 3
                        Repeater {
                            model: root.topLossItems
                            delegate: RowLayout {
                                spacing: 3
                                Rectangle { Layout.preferredWidth: 12; Layout.preferredHeight: 12; radius: 2; color: Theme.chartColors[index % Theme.chartColors.length] }
                                Label { text: modelData.label; font.pixelSize: Theme.fontSmall; elide: Text.ElideRight }
                            }
                        }
                    }
                    PieChartItem {
                        id: lossPieItem
                        items: root.topLossItems
                        Layout.preferredWidth: 220
                        Layout.preferredHeight: 180
                        Layout.alignment: Qt.AlignVCenter
                        onHovered: function(label, value, lx, ly) { root.showTip(label, value, lossPieItem, lx, ly) }
                         onHoverOff: root.hideTip()
                    }
                }
            }

            // 柱状图（正负）
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Label { text: qsTr("柱状图（金额/元，正负）"); font.bold: true }
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    ColumnLayout {
                        width: availableWidth
                        spacing: 4
                        Repeater {
                            model: root.breakdown
                            delegate: Item {
                                id: barRow
                                Layout.fillWidth: true
                                implicitHeight: 20
                                scale: barHover.containsMouse ? 1.01 : 1.0
                                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                Rectangle {
                                    anchors.fill: parent
                                    color: barHover.containsMouse ? Theme.accentLight : "transparent"
                                }
                                RowLayout {
                                    anchors.fill: parent
                                    spacing: 6
                                    Label { text: modelData.label; Layout.preferredWidth: 110; elide: Text.ElideRight; font.pixelSize: Theme.fontSmall }
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 20
                                        color: Theme.headerBg
                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.top: parent.top
                                            anchors.bottom: parent.bottom
                                            width: root.maxBreakdown > 0 ? parent.width * (Math.abs(Number(modelData.value || 0)) / root.maxBreakdown) : 0
                                            color: Number(modelData.value) >= 0 ? Theme.primary : Theme.danger
                                        }
                                    }
                                    Label { text: root.fmtNum(modelData.value); Layout.preferredWidth: 60; horizontalAlignment: Text.AlignRight; font.pixelSize: Theme.fontSmall }
                                }
                                MouseArea {
                                    id: barHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onEntered: {
                                        tipText.text = modelData.label + "：" + root.fmtMoney(modelData.value)
                                        const p = root.mapFromItem(this, mouseX, mouseY)
                                        tip.x = p.x + 14
                                        tip.y = p.y + 14
                                        tip.visible = true
                                        tip.opacity = 1
                                    }
                                    onPositionChanged: {
                                        const p = root.mapFromItem(this, mouseX, mouseY)
                                        tip.x = Math.max(8, Math.min(root.width - tip.width - 8, p.x + 14))
                                        tip.y = Math.max(8, Math.min(root.height - tip.height - 8, p.y + 14))
                                    }
                                    onExited: root.hideTip()
                                }
                            }
                        }
                    }
                }
            }
        }

        // 折线图：使用独立 QtCharts 组件；数据点较多时保留横向滚动空间。
        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 320
            Layout.minimumHeight: 260
            spacing: 8

            Label { text: qsTr("折线图（金额/元，时间趋势）"); font.bold: true }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 220
                color: Theme.surface
                border.color: Theme.border
                border.width: 1
                radius: Theme.radiusMedium

                // 视口保持当前页面宽度；时间点较多时内容按最小间距向右延展，
                // 通过横向滚动条查看完整日期和对应数据，避免横轴文字被压缩成省略号。
                Flickable {
                    id: trendViewport
                    anchors.fill: parent
                    anchors.margins: 8
                    clip: true
                    contentWidth: lineChart.width
                    contentHeight: height
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.HorizontalFlick
                    interactive: contentWidth > width

                    LineChart {
                        id: lineChart
                        width: Math.max(trendViewport.width, minimumContentWidth)
                        height: trendViewport.height
                        points: root.trend
                        onHovered: function(label, value, lx, ly) {
                            tipText.text = label + "：" + root.fmtMoney(value)
                            const p = root.mapFromItem(lineChart, lx, ly)
                            tip.x = Math.max(8, Math.min(root.width - tip.width - 8, p.x + 14))
                            tip.y = Math.max(8, Math.min(root.height - tip.height - 8, p.y - 12))
                            tip.visible = true
                            tip.opacity = 1
                        }
                        onHoverOff: root.hideTip()
                    }

                    ScrollBar.horizontal: ScrollBar {
                        policy: trendViewport.contentWidth > trendViewport.width
                                ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                    }
                }
            }
        }

        Rectangle {
            id: detailHeader
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            color: detailMouse.containsMouse ? Theme.primarySoft : Theme.surfaceMuted
            border.color: Theme.border
            radius: Theme.radiusSmall

            Label {
                anchors.fill: parent
                anchors.leftMargin: 12
                text: qsTr("数据明细（标签 -> 值）") + (root.detailExpanded ? "  ▾" : "  ▸")
                verticalAlignment: Text.AlignVCenter
                color: Theme.textSecondary
                font.pixelSize: Theme.fontSmall
            }

            MouseArea {
                id: detailMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.detailExpanded = !root.detailExpanded
            }
        }
        ScrollView {
            Layout.fillWidth: true
            visible: root.detailExpanded
            Layout.preferredHeight: root.detailExpanded ? 140 : 0
            clip: true
            ColumnLayout {
                width: availableWidth
                spacing: 2
                Repeater {
                    model: root.breakdown
                    delegate: Label { text: "  " + modelData.label + " → " + root.fmtMoney(modelData.value); font.pixelSize: Theme.fontSmall; color: Theme.textSecondary }
                }
                Repeater {
                    model: root.trend
                    delegate: Label { text: "  " + modelData.label + " → " + root.fmtMoney(modelData.value); font.pixelSize: Theme.fontSmall; color: Theme.textSecondary }
                }
            }
        }
    }
}
