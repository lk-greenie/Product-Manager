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
    property string searchPlaceholder: qsTr("搜索商品名")
    readonly property string currentCategory: categoryCombo.currentText
    readonly property string currentName: searchField.text.trim()
    readonly property string startDate: startDateField.text.trim()
    readonly property string endDate: endDateField.text.trim()

    signal filterRequested(string category, string name, string startDate, string endDate)
    signal filterReset()

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

    spacing: 8

    Label { text: qsTr("分类：") }

    ComboBox {
        id: categoryCombo
        Layout.preferredWidth: 130
        currentIndex: -1
        displayText: currentIndex >= 0 ? currentText : qsTr("全部")
        onActivated: bar.requestFilter()
    }

    TextField {
        id: searchField
        visible: bar.showSearch
        Layout.preferredWidth: 150
        placeholderText: bar.searchPlaceholder
        onAccepted: bar.requestFilter()
    }

    TextField {
        id: startDateField
        visible: bar.showDates
        Layout.preferredWidth: 120
        placeholderText: qsTr("起始日期 yyyy-MM-dd")
        inputMask: "0000-00-00;_"
        onAccepted: bar.requestFilter()
    }

    TextField {
        id: endDateField
        visible: bar.showDates
        Layout.preferredWidth: 120
        placeholderText: qsTr("终止日期 yyyy-MM-dd")
        inputMask: "0000-00-00;_"
        onAccepted: bar.requestFilter()
    }

    Button {
        text: qsTr("筛选")
        onClicked: bar.requestFilter()
    }

    Button {
        text: qsTr("重置")
        onClicked: {
            categoryCombo.currentIndex = -1
            searchField.clear()
            startDateField.clear()
            endDateField.clear()
            validationLabel.text = ""
            bar.filterReset()
        }
    }

    Label {
        visible: bar.showSummary
        text: bar.summaryLabel + bar.summaryText
        font.bold: true
    }

    Label {
        id: validationLabel
        color: "#b91c1c"
        Layout.fillWidth: true
        elide: Text.ElideRight
    }
}
