import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: bar

    property alias categoryModel: categoryCombo.model
    property bool showSearch: true
    property bool showDates: false
    property bool showSummary: false
    property string summaryText: ""
    property string summaryLabel: qsTr("总额：")
    property string searchPlaceholder: qsTr("搜索（商品名）")
    property bool showOrderButton: false
    property bool orderAscending: false
    property string orderToolTip: qsTr("切换排序")
    readonly property string currentCategory: categoryCombo.currentText
    readonly property string currentName: searchField.text.trim()
    readonly property string startDate: startDateField.displayText
    readonly property string endDate: endDateField.displayText

    signal filterRequested(string category, string name, string startDate, string endDate)
    signal filterReset()
    signal orderToggled()

    // 搜索输入使用短防抖，避免每个字符都触发 SQL 模型过滤和汇总查询。
    Timer {
        id: searchDebounce
        interval: 180
        repeat: false
        onTriggered: bar.requestFilter()
    }

    function validDate(value) {
        if (value === "")
            return true
        return /^\d{4}-\d{2}-\d{2}$/.test(value) && !isNaN(new Date(value + "T00:00:00").getTime())
    }

    function requestFilter() {
        if (!validDate(startDate) || !validDate(endDate)) {
            validationLabel.text = qsTr("日期格式应为 yyyy-MM-dd")
            return
        }
        if (startDate !== "" && endDate !== "" && startDate > endDate) {
            validationLabel.text = qsTr("起始日期不能晚于终止日期")
            return
        }
        validationLabel.text = ""
        filterRequested(currentCategory, currentName, startDate, endDate)
    }

    spacing: 10

    Label {
        text: qsTr("分类：")
        color: Theme.textSecondary
        font.pixelSize: Theme.fontSmall
    }

    StyledComboBox {
        id: categoryCombo
        Layout.preferredWidth: 150
        Layout.preferredHeight: Theme.controlHeight
        currentIndex: 0
        displayText: currentIndex >= 0 ? currentText : qsTr("全部")
        onActivated: bar.requestFilter()
    }

    ToolButton {
        id: orderButton
        visible: bar.showOrderButton
        text: bar.orderAscending ? qsTr("↑") : qsTr("↓")
        Accessible.name: bar.orderToolTip
        ToolTip.visible: hovered
        ToolTip.text: bar.orderToolTip
        Layout.preferredWidth: 34
        Layout.preferredHeight: Theme.controlHeight
        onClicked: bar.orderToggled()
        background: Rectangle {
            radius: Theme.radiusSmall
            color: orderButton.hovered ? Theme.primarySoft : Theme.surface
            border.color: Theme.border
            border.width: 1
        }
    }

    StyledTextField {
        id: searchField
        visible: bar.showSearch
        Layout.preferredWidth: 190
        Layout.preferredHeight: Theme.compactControlHeight
        placeholderText: bar.searchPlaceholder
        onTextChanged: searchDebounce.restart()
        onAccepted: bar.requestFilter()
    }

    DatePickerField {
        id: startDateField
        visible: bar.showDates
        Layout.preferredWidth: 132
        Layout.preferredHeight: Theme.compactControlHeight
        placeholderText: qsTr("起始日期")
        onDatePicked: function(){ bar.requestFilter() }
    }

    DatePickerField {
        id: endDateField
        visible: bar.showDates
        Layout.preferredWidth: 132
        Layout.preferredHeight: Theme.compactControlHeight
        placeholderText: qsTr("终止日期")
        onDatePicked: function(){ bar.requestFilter() }
    }

    PrimaryButton {
        text: qsTr("筛选")
        onClicked: bar.requestFilter()
    }

    SecondaryButton {
        text: qsTr("重置")
        onClicked: {
            categoryCombo.currentIndex = 0
            searchField.clear()
            searchDebounce.stop()
            startDateField.selectedDate = null
            endDateField.selectedDate = null
            validationLabel.text = ""
            bar.filterReset()
        }
    }

    Label {
        visible: bar.showSummary
        text: bar.summaryLabel + bar.summaryText
        font.bold: true
        color: Theme.textPrimary
    }

    Label {
        id: validationLabel
        color: Theme.danger
        Layout.fillWidth: true
        elide: Text.ElideRight
    }
}
