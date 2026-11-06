import Quickshell
import QtQuick
import QtQuick.Layouts

DropdownMenu {
    id: cpuIndicator
    property real barWidth: cpuIndicator.cpuData.length > 16 ? 4 : 10
    implicitWidth: Math.max(contentImplicitWidth, cpuIndicator.cpuData.length * barWidth + 2 * AppConstants.loadBarInset)

    // The daemon's `cpu` topic: {total, cores}; null while it's unreachable.
    readonly property var cpuLoad: Daemon.connected ? cpuTopic.latest : null
    readonly property var cpuData: cpuLoad ? cpuLoad.cores : []
    // The daemon's `cpu.details` topic, sampled while the menu is open:
    // {temperature: {text, hot} | null, processes}.
    readonly property var cpuDetails: Daemon.connected ? cpuDetailsTopic.latest : null
    readonly property var temperature: cpuDetails ? cpuDetails.temperature : null
    readonly property var topProcesses: cpuDetails ? cpuDetails.processes : []
    readonly property int topProcessCount: 5

    toggleTextFont.pixelSize: 18
    toggleTextWidest: "100%"
    toggleText: cpuLoad ? `${cpuLoad.total}%` : "…"
    toggleIconSource: Qt.resolvedUrl("assets/icons/fontawesome/solid/microchip.svg")

    Item {
        anchors.fill: parent
        anchors.leftMargin: AppConstants.loadBarInset
        anchors.rightMargin: AppConstants.loadBarInset
        z: -1
        Repeater {
            // Keyed on the core count only, so bars are updated in place
            // instead of being recreated on every sample.
            model: cpuIndicator.cpuData.length
            Rectangle {
                // Bars share the widget's width, in case the icon and text
                // need more room than barWidth per core.
                x: index * width
                width: parent.width / cpuIndicator.cpuData.length
                height: ((cpuIndicator.cpuData[index] || 0) / 100) * parent.height
                color: AppConstants.indicatorBarColor
                anchors.bottom: parent.bottom
            }
        }
    }

    menuWidth: 400
    opensUpward: true
    menuContent: [
        DropdownMenuItem {
            StyledText {
                font.pixelSize: 18
                color: cpuIndicator.temperature && cpuIndicator.temperature.hot ? AppConstants.dangerColor : AppConstants.styledTextColor
                text: {
                    if (!cpuIndicator.cpuDetails) {
                        return "…";
                    }
                    return cpuIndicator.temperature ? cpuIndicator.temperature.text : "Temperature: n/a";
                }
            }
        },
        DropdownMenuHeader {
            text: "Top processes"
        },
        Repeater {
            // A fixed number of rows that only have their values swapped, so
            // hovering and the menu size stay stable between samples.
            model: cpuIndicator.topProcessCount
            delegate: UsageMenuItem {
                readonly property var processInfo: cpuIndicator.topProcesses[index] || null
                label: processInfo ? processInfo.name : "…"
                valueText: processInfo ? processInfo.value : ""
                percent: processInfo ? processInfo.percent : 0
            }
        }
    ]

    DaemonTopic {
        id: cpuDetailsTopic
        topic: "cpu.details"
        active: cpuIndicator.menuVisible
    }

    DaemonTopic {
        id: cpuTopic
        topic: "cpu"
    }
}
