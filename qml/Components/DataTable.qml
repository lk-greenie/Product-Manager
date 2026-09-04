pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    Rectangle {
        anchors.fill: parent
        color: Theme.surface
        border.color: Theme.border
        border.width: 1
        radius: Theme.radiusMedium
        z: -1
    }

    property alias model: tableView.model
    property var dateColumns: []
    property var datetimeColumns: []
    property var moneyColumns: []
    property var hiddenColumns: []
    property int warningQuantityColumn: -1
    property int upperLimitColumn: -1
    property int lowerLimitColumn: -1
    property var expiryDateColumns: []
    property int recordAmountColumn: -1
    property bool showStatusColors: true
    property int columnCount: 5
    readonly property int visibleColumnCount: {
        let count = 0
        for (let column = 0; column < root.columnCount; ++column) {
            if (!root.isHidden(column))
                ++count
        }
        return Math.max(1, count)
    }

    function contains(columns, column) {
        return columns.indexOf(column) !== -1
    }

    function isHidden(column) {
        return contains(hiddenColumns, column)
    }

    function isDateColumn(column) {
        return contains(dateColumns, column)
    }

    function isDatetimeColumn(column) {
        return contains(datetimeColumns, column)
    }

    function isMoneyColumn(column) {
        return contains(moneyColumns, column)
    }

    function valueAt(row, column) {
        if (!tableView.model || column < 0)
            return undefined
        const index = tableView.model.index(row, column)
        return tableView.model.data(index)
    }

    function cellColor(row, column) {
        const baseColor = row % 2 === 1 ? Theme.surfaceMuted : Theme.surface
        if (!showStatusColors)
            return baseColor

        if (recordAmountColumn >= 0 && column === recordAmountColumn) {
            const amount = Number(valueAt(row, recordAmountColumn))
            if (amount < 0)
                return Theme.expenseRow
            if (amount > 0)
                return Theme.incomeRow
        }

        if (warningQuantityColumn >= 0 && column === warningQuantityColumn) {
            const quantity = Number(valueAt(row, warningQuantityColumn))
            const upper = Number(valueAt(row, upperLimitColumn))
            const lower = Number(valueAt(row, lowerLimitColumn))
            if (!isNaN(quantity) && !isNaN(upper) && !isNaN(lower)
                    && (quantity > upper || quantity < lower))
                return Theme.warningCell
        }

        if (contains(expiryDateColumns, column)) {
            const expiryColumn = expiryDateColumns.length > 1 ? expiryDateColumns[1] : column
            const expiry = new Date(valueAt(row, expiryColumn))
            if (!isNaN(expiry.getTime()) && expiry < new Date())
                return Theme.expiredCell
        }
        return baseColor
    }

    function displayValue(value, column) {
        if (isMoneyColumn(column)) {
            const n = Number(value)
            return isNaN(n) ? (value === undefined || value === null ? "" : String(value))
                            : qsTr("￥%1").arg(n.toFixed(2))
        }
        if (!isDateColumn(column))
            return value === undefined || value === null ? "" : value
        const raw = String(value)
        if (/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/.test(raw))
            return raw
        const parsed = new Date(raw)
        if (isNaN(parsed.getTime()))
            return raw
        return Qt.formatDateTime(parsed, isDatetimeColumn(column) ? "yyyy-MM-dd HH:mm:ss" : "yyyy-MM-dd")
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        HorizontalHeaderView {
            id: horizontalHeader
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            syncView: tableView
            clip: true
            movableColumns: false
            columnWidthProvider: function(column) {
                return root.isHidden(column) ? 0 : horizontalHeader.width / root.visibleColumnCount
            }

            delegate: Rectangle {
                id: headerDelegate

                required property int index
                required property string display

                color: Theme.headerBg
                border.color: Theme.border
                implicitWidth: horizontalHeader.width / root.visibleColumnCount
                implicitHeight: horizontalHeader.height
                visible: !root.isHidden(index)

                Text {
                    anchors.centerIn: parent
                    text: headerDelegate.display
                    font.pixelSize: Theme.fontSmall
                    font.weight: Font.DemiBold
                    color: Theme.textSecondary
                    elide: Text.ElideRight
                }
            }
        }

        TableView {
            id: tableView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            reuseItems: true
            boundsBehavior: Flickable.StopAtBounds
            rowHeightProvider: function() { return 36 }
            columnWidthProvider: function(column) {
                return root.isHidden(column) ? 0 : horizontalHeader.width / root.visibleColumnCount
            }

            delegate: Rectangle {
                id: cellDelegate

                required property int row
                required property int column
                required property var display

                implicitWidth: root.isHidden(column) ? 0 : horizontalHeader.width / root.visibleColumnCount
                implicitHeight: 32
                visible: !root.isHidden(column)
                border.color: Theme.border
                color: root.cellColor(row, column)

                Text {
                    anchors.fill: parent
                    anchors.margins: 4
                    text: root.displayValue(cellDelegate.display, cellDelegate.column)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    font.pixelSize: Theme.fontSmall
                    color: Theme.textPrimary
                }
            }

            ScrollBar.horizontal: ScrollBar {}
            ScrollBar.vertical: ScrollBar {}
        }
    }
}
