import QtQuick
import QtQuick.Layouts
import Quickshell

DropdownMenu {
    id: gpuIndicator
    // The daemon's `gpu` topic: {name, load, memory_used, memory_total} (MiB);
    // null while it's unreachable.
    readonly property var gpuUsage: Daemon.connected ? gpuTopic.latest : null
    readonly property string gpuName: gpuUsage ? gpuUsage.name : ""
    readonly property int loadPercent: gpuUsage ? gpuUsage.load : 0
    readonly property int memoryUsed: gpuUsage ? gpuUsage.memory_used : 0
    readonly property int memoryTotal: gpuUsage ? gpuUsage.memory_total : 0
    // Integrated GPUs share system RAM and report no dedicated memory.
    property bool hasDedicatedMemory: memoryTotal > 0
    property int memoryPercent: hasDedicatedMemory ? Math.round(memoryUsed / memoryTotal * 100) : 0
    // The daemon's `gpu.details` topic, sampled while the menu is open:
    // {processes, temperature, power_mw, error}.
    readonly property var gpuDetails: Daemon.connected ? gpuDetailsTopic.latest : null
    readonly property var topProcesses: gpuDetails ? gpuDetails.processes : []
    readonly property string processesError: gpuDetails ? gpuDetails.error : ""
    readonly property bool processesLoaded: gpuDetails !== null
    readonly property int topProcessCount: 5
    // Both null on Intel GPUs and before the first sample; the rows hide
    // themselves then.
    readonly property var temperature: gpuDetails ? gpuDetails.temperature : null
    readonly property var powerMw: gpuDetails ? gpuDetails.power_mw : null
    // Also false for a daemon too old to send the fields at all.
    readonly property bool hasTemperature: temperature !== null && temperature !== undefined
    readonly property bool hasPower: powerMw !== null && powerMw !== undefined

    toggleIconSource: Qt.resolvedUrl("assets/icons/fontawesome/solid/display.svg")

    toggleTextFont.pixelSize: 18
    toggleText: gpuIndicator.gpuUsage ? `${gpuIndicator.loadPercent}%` : "…"

    toggleTextWidest: "100%"

    Item {
        anchors.fill: parent
        anchors.leftMargin: AppConstants.loadBarInset
        anchors.rightMargin: AppConstants.loadBarInset
        z: -1
        Rectangle {
            width: gpuIndicator.hasDedicatedMemory ? parent.width / 2 : parent.width
            height: (gpuIndicator.loadPercent / 100) * parent.height
            color: AppConstants.indicatorBarColor
            anchors.bottom: parent.bottom
            anchors.left: parent.left
        }
        Rectangle {
            visible: gpuIndicator.hasDedicatedMemory
            width: parent.width / 2
            height: (gpuIndicator.memoryPercent / 100) * parent.height
            color: AppConstants.memoryBarColor
            anchors.bottom: parent.bottom
            anchors.right: parent.right
        }
    }

    menuWidth: 450
    opensUpward: true
    menuContent: [
        DropdownMenuItem {
            StyledText {
                anchors.centerIn: undefined
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: 18
                elide: Text.ElideRight
                text: gpuIndicator.gpuName || "…"
            }
        },
        // The usage numbers as a 2×2 grid: each cell half as wide, the four
        // together half as high as the rows they replace. Cells the payload
        // doesn't fill (temperature, power on Intel) drop out and the grid
        // reflows; a cell left alone in its row spans both columns. The
        // columns are separated by a line drawn over the grid — a layout lays
        // anything declared in it out as a cell.
        Item {
            Layout.fillWidth: true
            implicitHeight: usageGrid.implicitHeight

            GridLayout {
                id: usageGrid
                anchors.fill: parent
                columns: 2
                columnSpacing: 0
                rowSpacing: 0

                UsageMenuItem {
                    id: loadCell
                    // The top row sits at y == 0 inside the grid, but there
                    // is a menu row above it to separate it from.
                    showSeparator: true
                    label: "Load"
                    valueText: gpuIndicator.gpuUsage ? `${gpuIndicator.loadPercent}%` : "…"
                    percent: gpuIndicator.loadPercent
                }
                UsageMenuItem {
                    showSeparator: true
                    barColor: AppConstants.memoryBarColor
                    label: "Memory"
                    valueText: {
                        if (!gpuIndicator.gpuUsage) {
                            return "…";
                        }
                        return gpuIndicator.hasDedicatedMemory ? `${gpuIndicator.memoryUsed} / ${gpuIndicator.memoryTotal} MiB · ${gpuIndicator.memoryPercent}%` : "shared";
                    }
                    percent: gpuIndicator.memoryPercent
                }
                UsageMenuItem {
                    // °C, with the bar on a 0–100 scale.
                    visible: gpuIndicator.hasTemperature
                    Layout.columnSpan: gpuIndicator.hasPower ? 1 : 2
                    label: "Temperature"
                    valueText: `${gpuIndicator.temperature}°C`
                    percent: gpuIndicator.hasTemperature ? gpuIndicator.temperature : 0
                }
                UsageMenuItem {
                    // No power ceiling is reported, so there is no bar to fill.
                    visible: gpuIndicator.hasPower
                    Layout.columnSpan: gpuIndicator.hasTemperature ? 1 : 2
                    label: "Power"
                    valueText: `${(gpuIndicator.powerMw / 1000).toFixed(1)} W`
                }
            }

            // Between the two equal columns, inset like the row separators.
            // A lone bottom cell spans both columns, so the line then stops
            // at the top row.
            Separator {
                vertical: true
                thickness: 1
                anchors.horizontalCenter: parent.horizontalCenter
                y: 10
                height: (gpuIndicator.hasTemperature && gpuIndicator.hasPower ? usageGrid.height : loadCell.height) - 20
            }
        },
        DropdownMenuHeader {
            text: "Top processes"
        },
        DropdownMenuItem {
            visible: gpuIndicator.processesError !== ""
            StyledText {
                font.pixelSize: 16
                text: gpuIndicator.processesError
            }
        },
        Repeater {
            // A fixed number of rows that only have their values swapped, so
            // hovering and the menu size stay stable between samples.
            model: gpuIndicator.processesError === "" ? gpuIndicator.topProcessCount : 0
            delegate: UsageMenuItem {
                readonly property var processInfo: gpuIndicator.topProcesses[index] || null
                // There can be fewer GPU clients than rows.
                label: processInfo ? processInfo.name : gpuIndicator.processesLoaded ? "" : "…"
                valueText: processInfo ? processInfo.value : ""
                percent: processInfo ? processInfo.percent : 0
            }
        }
    ]

    DaemonTopic {
        id: gpuDetailsTopic
        topic: "gpu.details"
        active: gpuIndicator.menuVisible
    }

    DaemonTopic {
        id: gpuTopic
        topic: "gpu"
    }
}
