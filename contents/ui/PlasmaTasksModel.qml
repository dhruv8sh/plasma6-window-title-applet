import QtQuick
import QtQml.Models

import org.kde.taskmanager as TaskManager

Item {
    id: plasmaTasksItem
    readonly property bool existsWindowActive: root.activeTaskItem && tasksRepeater.count > 0 && activeTaskItem.isActive
    property Item activeTaskItem: null

    TaskManager.TasksModel {
        id: tasksModel
        sortMode: TaskManager.TasksModel.SortVirtualDesktop
        groupMode: TaskManager.TasksModel.GroupDisabled
        screenGeometry: root.screenGeometry
        activity: activityInfo.currentActivity
        virtualDesktop: virtualDesktopInfo.currentDesktop

        filterByScreen: plasmoid.configuration.filterByScreen
        filterByVirtualDesktop: true
        filterByActivity: true
    }
    Item{
        id: taskList
        Repeater{
            id: tasksRepeater
            model: tasksModel
            Item{
                id: task
                readonly property string appName: modelAppName !== "" ? modelAppName : discoveredAppName
                readonly property bool isMinimized: IsMinimized === true ? true : false
                readonly property bool isMaximized: IsMaximized === true ? true : false
                readonly property bool isActive: IsActive === true ? true : false
                readonly property bool isOnAllDesktops: IsOnAllVirtualDesktops === true ? true : false
                property var icon: decoration

                readonly property string modelAppName: AppName
                readonly property string modelDisplay: display

                property string title: ""
                property string discoveredAppName: ""

                readonly property var m: model

                function cleanupTitle() {
                    var text = display || "";
                    var t = modelDisplay || "";

                    // Set default values
                    var dTitle = t.trim(); // Assume the display is the title
                    var dAppName = ""; // App name derived from parsing

                    // Define the list of separators and their lengths
                    var separators = [
                        { sep: " —– ", len: 4 },
                        { sep: " -- ", len: 4 },
                        { sep: " — ", len: 3 },
                        { sep: " - ", len: 3 }
                    ];

                    var sepIndex = -1;
                    var sepLen = 0;

                    // Find the first matching separator in reverse order
                    for (var i = 0; i < separators.length; i++) {
                        var idx = t.lastIndexOf(separators[i].sep);
                        if (idx > -1) {
                            sepIndex = idx;
                            sepLen = separators[i].len;
                            break;
                        }
                    }

                    // Parse only if a valid separator is found
                    if (sepIndex > -1) {
                        dTitle = text.substring(0, sepIndex).trim(); // Extract title
                        dAppName = text.substring(sepIndex + sepLen).trim(); // Extract app name
                    }

                    // Edge Case: Chrome or other apps where the application name might be stripped
                    // If the parsed app name is empty or incorrect, fallback to modelAppName
                    if (!dAppName || dAppName === "") {
                        dAppName = modelAppName || "";
                    }

                    // Handle cases where title starts with the application name
                    if (dTitle.startsWith(dAppName)) {
                        let firstPart = dTitle;
                        dTitle = dAppName;
                        dAppName = firstPart;
                    }

                    // Final fallback if everything fails
                    dAppName = dAppName || modelAppName || "";
                    title = dTitle || t || ""; // Use full display if no clean title found
                    discoveredAppName = dAppName.trim();
                }

                onIsActiveChanged: {
                    if (isActive) {
                        if(plasmoid.configuration.showOnlyOnMaximize && !task.isMaximized)
                            plasmaTasksItem.activeTaskItem = null;
                        else
                            plasmaTasksItem.activeTaskItem = task;

                    }
                }

                onIsMaximizedChanged: {
                    if(plasmoid.configuration.showOnlyOnMaximize && isActive)
                        plasmaTasksItem.activeTaskItem = task.isMaximized ? task : null;
                }

                onModelAppNameChanged: task.cleanupTitle()
                onModelDisplayChanged: task.cleanupTitle()
                Component.onCompleted: task.cleanupTitle()

                Component.onDestruction: {
                    if (plasmaTasksItem.lastActiveTaskItem === task) {
                        plasmaTasksItem.lastActiveTaskItem = null;
                    }
                }

                function modelIndex(){
                    return tasksModel.makeModelIndex(index);
                }

                function toggleMaximized() {
                    tasksModel.requestToggleMaximized(modelIndex());
                }

                function toggleMinimized() {
                    tasksModel.requestToggleMinimized(modelIndex());
                }

                function requestClose() {
                    tasksModel.requestClose(modelIndex());
                }

                function togglePinToAllDesktops() {
                    if (root.plasma515) {
                        tasksModel.requestVirtualDesktops(modelIndex(), 0);
                    } else {
                        tasksModel.requestVirtualDesktop(modelIndex(), 0);
                    }
                }

                function toggleKeepAbove(){
                    tasksModel.requestToggleKeepAbove(modelIndex());
                }
            }
        }
    }

    //! Functionality

    function toggleMaximized() {
        if (activeTaskItem) {
            activeTaskItem.toggleMaximized();
        }
    }

    function toggleMinimized() {
        if (activeTaskItem)
            activeTaskItem.toggleMinimized();
    }

    function requestClose() {
        if (activeTaskItem)
            activeTaskItem.requestClose();
    }

    function togglePinToAllDesktops() {
        if (activeTaskItem) {
            activeTaskItem.togglePinToAllDesktops();
        }
    }

    function toggleKeepAbove(){
        if (activeTaskItem) {
            activeTaskItem.toggleKeepAbove();
        }
    }

    //! Cycle Through Tasks
    function activateNextPrevTask(next) {
        var taskIndexList = [];
        var activeTaskIndex = tasksModel.activeTask;

        for (var i = 0; i < taskList.children.length - 1; ++i) {
            var task = taskList.children[i];
            var modelIndex = task.modelIndex(i);

            if (task.m.IsLauncher !== true && task.m.IsStartup !== true) {
                if (task.m.IsGroupParent === true) {
                    for (var j = 0; j < tasksModel.rowCount(modelIndex); ++j) {
                        taskIndexList.push(tasksModel.makeModelIndex(i, j));
                    }
                } else {
                    taskIndexList.push(modelIndex);
                }
            }
        }

        if (!taskIndexList.length) {
            return;
        }

        var target = taskIndexList[0];

        for (var i = 0; i < taskIndexList.length; ++i) {
            if (taskIndexList[i] === activeTaskIndex)
            {
                if (next && i < (taskIndexList.length - 1)) {
                    target = taskIndexList[i + 1];
                } else if (!next) {
                    if (i) {
                        target = taskIndexList[i - 1];
                    } else {
                        target = taskIndexList[taskIndexList.length - 1];
                    }
                }

                break;
            }
        }
        tasksModel.requestActivate(target);
    }
}
