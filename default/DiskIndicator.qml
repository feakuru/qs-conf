import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

DropdownMenu {
    id: diskIndicator
    property int busyPercent: 0
    // From disk_details.py: `disks` is the layout of the menu and only
    // reassigned when it changes, so its rows are kept while `diskStats`
    // updates their values.
    property var disks: []
    property string disksJson: ""
    property var diskStats: ({})
    property bool detailsLoaded: false
    property var topProcesses: []
    readonly property int topProcessesShown: 3
    // Filesystems at least this full get a red bar.
    readonly property int fullPercent: 90

    toggleIconSource: Qt.resolvedUrl("assets/icons/fontawesome/solid/hard-drive.svg")
    toggleIconColor: AppConstants.styledTextColor

    // How busy the busiest disk is.
    Rectangle {
        z: -1
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: AppConstants.loadBarInset
        anchors.right: parent.right
        anchors.rightMargin: AppConstants.loadBarInset
        height: (diskIndicator.busyPercent / 100) * parent.height
        color: AppConstants.indicatorBarColor
    }

    menuWidth: 450
    menuContent: [
        DropdownMenuItem {
            visible: !diskIndicator.detailsLoaded
            StyledText {
                font.pixelSize: 16
                text: "…"
            }
        },
        Repeater {
            model: diskIndicator.disks
            delegate: ColumnLayout {
                id: diskSection
                required property var modelData
                readonly property var diskStats: diskIndicator.diskStats[`disk:${modelData.name}`] || null

                Layout.fillWidth: true
                spacing: 0

                DropdownMenuHeader {
                    text: diskSection.modelData.title
                }

                // Activity, for actual disks (not the "Other" group).
                UsageMenuItem {
                    visible: diskSection.modelData.name !== ""
                    label: diskSection.diskStats ? diskSection.diskStats.label : "…"
                    valueText: diskSection.diskStats ? diskSection.diskStats.value : ""
                    percent: diskSection.diskStats ? diskSection.diskStats.percent : 0
                }

                Repeater {
                    model: diskSection.modelData.mounts
                    delegate: UsageMenuItem {
                        required property var modelData
                        readonly property var mountStats: diskIndicator.diskStats[`mount:${modelData.id}`] || null

                        label: modelData.label
                        labelElide: Text.ElideMiddle
                        valueText: mountStats ? mountStats.value : "…"
                        detailLabel: modelData.details
                        detailValueText: mountStats ? mountStats.detail : ""
                        percent: mountStats ? mountStats.percent : 0
                        barColor: percent >= diskIndicator.fullPercent ? AppConstants.dangerBarColor : AppConstants.memoryBarColor
                    }
                }
            }
        },
        DropdownMenuHeader {
            // Other users' processes, including root's, can't be inspected.
            text: "Top processes (yours)"
        },
        DropdownMenuItem {
            visible: diskIndicator.detailsLoaded && diskIndicator.topProcesses.length === 0
            StyledText {
                font.pixelSize: 16
                color: AppConstants.mutedIconColor
                text: "No disk I/O"
            }
        },
        ScrollingMenuList {
            rowCount: processesRepeater.count
            maxVisibleRows: diskIndicator.topProcessesShown

            Repeater {
                id: processesRepeater
                // Keyed on the number of processes only, so rows are only
                // recreated when it changes; their values are swapped in place.
                model: diskIndicator.topProcesses.length
                delegate: UsageMenuItem {
                    required property int index
                    readonly property var processInfo: diskIndicator.topProcesses[index] || null
                    // The first row is at the top of the scroll area, but
                    // still follows the rows above it.
                    showSeparator: true
                    label: processInfo ? processInfo.name : ""
                    valueText: processInfo ? processInfo.value : ""
                    percent: processInfo ? processInfo.percent : 0
                }
            }
        }
    ]

    ScriptProcess {
        id: diskIoProcess
        scriptName: "disk_io"
        running: true

        stdout: SplitParser {
            onRead: data => {
                let usage;
                try {
                    usage = JSON.parse(data);
                } catch (e) {
                    return;
                }
                diskIndicator.busyPercent = usage.busy || 0;
            }
        }
    }

    ScriptProcess {
        id: diskDetailsProcess
        scriptName: "disk_details"
        running: diskIndicator.menuVisible

        stdout: SplitParser {
            onRead: data => {
                let details;
                try {
                    details = JSON.parse(data);
                } catch (e) {
                    return;
                }
                let disksJson = JSON.stringify(details.disks || []);
                if (disksJson !== diskIndicator.disksJson) {
                    diskIndicator.disksJson = disksJson;
                    diskIndicator.disks = details.disks || [];
                }
                diskIndicator.diskStats = details.stats || {};
                diskIndicator.topProcesses = details.processes || [];
                diskIndicator.detailsLoaded = true;
            }
        }
    }
}
