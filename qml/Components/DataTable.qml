pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property alias model: tableView.model
    property var dateColumns: []
    property var hiddenColumns: []
    property int warningQuantityColumn: -1
    property int upperLimitColumn: -1
    property int lowerLimitColumn: -1
    property var expiryDateColumns: []
    property int recordAmountColumn: -1
    property bool showStatusColors: true
    property int columnCount: 5

    function contains(columns, column) {
        return columns.indexOf(column) !== -1
    }

    function isHidden(column) {
        return contains(hiddenColumns, column)
    }

    function isDateColumn(column) {
        return contains(dateColumns, column)
    }

    function valueAt(row, column) {
        if (!tableView.model || column < 0)
            return undefined
        const index = tableView.model.index(row, column)
        return tableView.model.data(index)
    }

    function cellColor(row, column) {
        if (!showStatusColors)
            return Theme.surface

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
        return Theme.surface
    }

    function displayValue(value, column) {
        if (!isDateColumn(column))
            return value === undefined || value === null ? "" : value
        const raw = String(value)
        if (/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/.test(raw))
            return raw
        const parsed = new Date(raw)
        if (isNaN(parsed.getTime()))
            return raw
        return Qt.formatDateTime(parsed, "yyyy-MM-dd")
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
                return root.isHidden(column) ? 0 : horizontalHeader.width / root.columnCount
            }

            delegate: Rectangle {
                id: headerDelegate

                required property int index
                required property string display

                color: Theme.headerBg
                border.color: Theme.border
                implicitWidth: horizontalHeader.width / root.columnCount
                implicitHeight: horizontalHeader.height
                visible: !root.isHidden(index)

                Text {
                    anchors.centerIn: parent
                    text: headerDelegate.display
                    font.pixelSize: Theme.fontSmall
                    elide: Text.ElideRight
                }
            }
        }

        TableView {
            id: tableView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            columnWidthProvider: function(column) {
                return root.isHidden(column) ? 0 : horizontalHeader.width / root.columnCount
            }

            delegate: Rectangle {
                id: cellDelegate

                required property int row
                required property int column
                required property var display

                implicitWidth: root.isHidden(column) ? 0 : horizontalHeader.width / root.columnCount
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
                }
            }

            ScrollBar.horizontal: ScrollBar {}
            ScrollBar.vertical: ScrollBar {}
        }
    }
}
