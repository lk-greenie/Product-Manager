// 打开子窗口/组件的样板封装：Qt.createComponent + status 判断 + createObject + show。
// 统一处理 Ready / Loading 异步分支，修复原代码中 Loading 分支异步 show() 的隐患
// （原写法在回调外直接 show，addnew 可能尚未创建）。
//
// 注意：此文件不使用 .pragma library，因为 Component/Qt 全局对象在隔离上下文中不可访问。
//
// 供 DisplayPage 菜单（打开 AddCat/In/Out/SetPrice/SetLimits）与 LoginPage（打开 MainMenu）复用。
//
// 参数：
//   parentObj —— 新对象的父对象（QML Item / Window）
//   qmlPath   —— 组件路径，可为相对路径 "In.qml" 或资源路径 "qrc:/qml/MainMenu.qml"
// 返回：创建成功返回新对象；Loading 情况下返回 null（在回调中异步创建并 show）。
function openWindow(parentObj, qmlPath) {
    var component = Qt.createComponent(qmlPath)

    function create() {
        var obj = component.createObject(parentObj)
        if (obj === null) {
            console.log("创建窗口失败：" + qmlPath)
            return null
        }
        var owner = parentObj && parentObj.Window ? parentObj.Window.window : null
        if (owner) {
            obj.transientParent = owner
            obj.x = owner.x + Math.round((owner.width - obj.width) / 2)
            obj.y = owner.y + Math.round((owner.height - obj.height) / 2)
        }
        obj.show()
        return obj
    }

    // Component 状态数值：Null=0, Ready=1, Loading=2, Error=3。
    // 不直接引用 Component.Ready 枚举——在导入的 JS 文件中 Component 类型不可靠，
    // 改用数值常量完全规避 ReferenceError。
    if (component.status === 1) {          // Ready
        return create()
    } else if (component.status === 2) {   // Loading
        // 异步加载：等就绪后在回调内创建并显示，避免对象未就绪时 show()
        component.statusChanged.connect(function () {
            if (component.status === 1) {        // Ready
                create()
            } else if (component.status === 3) { // Error
                console.log("无法打开窗口 " + qmlPath + "：" + component.errorString())
            }
        })
        return null
    } else {
        // Error(3) 或 Null(0)
        console.log("无法打开窗口 " + qmlPath + "：" + component.errorString())
        return null
    }
}
