import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

DropdownMenu {
    id: volumeIndicator

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool isMuted: sink && sink.audio ? sink.audio.muted : false
    readonly property var channelVolumes: sink && sink.audio ? sink.audio.volumes : []
    readonly property int leftVolume: channelVolumes.length > 0 ? Math.round(channelVolumes[0] * 100) : 0
    readonly property int rightVolume: channelVolumes.length > 1 ? Math.round(channelVolumes[1] * 100) : leftVolume

    // PipeWire's media classes, by the flags Quickshell exposes:
    //   isSink && !isStream: output device     isSink && isStream: app playing audio
    //   !isSink && !isStream: input device     !isSink && isStream: app recording
    readonly property var audioNodes: [...Pipewire.nodes.values].filter(node => node.audio)
    readonly property var outputDevices: audioNodes.filter(node => node.isSink && !node.isStream).sort((lhs, rhs) => nodeName(lhs).localeCompare(nodeName(rhs)))
    readonly property var inputDevices: audioNodes.filter(node => !node.isSink && !node.isStream).sort((lhs, rhs) => nodeName(lhs).localeCompare(nodeName(rhs)))
    readonly property var playbackStreams: audioNodes.filter(node => node.isSink && node.isStream && !isMonitor(node))
    readonly property var recordingStreams: audioNodes.filter(node => !node.isSink && node.isStream && !isMonitor(node))
    readonly property int streamsShown: 4
    readonly property int devicesShown: 3
    property bool outputDevicesExpanded: false
    property bool inputDevicesExpanded: false

    function nodeName(node) {
        return node.description || node.nickname || node.name;
    }

    // e.g. "Firefox: Some video title"
    function streamName(node) {
        let properties = node.properties || {};
        let application = properties["application.name"] || nodeName(node);
        let media = properties["media.name"];
        return media && media !== application ? `${application}: ${media}` : application;
    }

    // Level meters (ours, pavucontrol's, ...) are streams too, but not
    // something to control.
    function isMonitor(node) {
        return node.name === "quickshell-peak-monitor" || (node.properties && node.properties["stream.monitor"] === "true");
    }

    // Volume and mute of the default output on the bar; everything else only
    // while the menu is open.
    PwObjectTracker {
        objects: {
            let objects = [volumeIndicator.sink, volumeIndicator.source];
            if (volumeIndicator.menuVisible) {
                objects = objects.concat(volumeIndicator.audioNodes.filter(node => node.isStream && node.name !== "quickshell-peak-monitor"));
            }
            return objects;
        }
    }

    onMenuVisibleChanged: {
        if (!menuVisible) {
            outputDevicesExpanded = false;
            inputDevicesExpanded = false;
        }
    }

    toggleIconColor: AppConstants.styledTextColor
    toggleIconSource: {
        let iconName = "off";
        if (isMuted) {
            iconName = "xmark";
        } else {
            let volume = leftVolume + rightVolume;
            if (volume > 100) {
                iconName = "high";
            } else if (volume > 0) {
                iconName = "low";
            } else {
                iconName = "off";
            }
        }
        Qt.resolvedUrl(`assets/icons/fontawesome/solid/volume-${iconName}.svg`);
    }

    toggleTextFont.pixelSize: 18
    toggleTextWidest: "100%"
    toggleText: {
        if (!sink || isMuted) {
            return '';
        } else if (leftVolume == rightVolume) {
            return `${leftVolume}%`;
        } else {
            return `L${leftVolume} R${rightVolume}`;
        }
    }

    menuWidth: 450
    menuContent: [
        DropdownMenuHeader {
            text: "Output"
        },
        VolumeMenuItem {
            visible: volumeIndicator.sink !== null
            node: volumeIndicator.sink
            label: volumeIndicator.sink ? volumeIndicator.nodeName(volumeIndicator.sink) : ""
            labelElide: Text.ElideMiddle
            monitorPeaks: volumeIndicator.menuVisible
            extraButtonIcon: volumeIndicator.outputDevices.length > 1 ? "right-left" : ""
            extraButtonHighlighted: volumeIndicator.outputDevicesExpanded
            extraButtonAction: () => {
                volumeIndicator.outputDevicesExpanded = !volumeIndicator.outputDevicesExpanded;
            }
        },
        DropdownMenuItem {
            visible: volumeIndicator.sink === null
            StyledText {
                font.pixelSize: 16
                color: AppConstants.mutedIconColor
                text: "No output device"
            }
        },
        ScrollingMenuList {
            rowCount: volumeIndicator.outputDevicesExpanded ? outputDevicesRepeater.count : 0
            maxVisibleRows: volumeIndicator.devicesShown

            Repeater {
                id: outputDevicesRepeater
                model: ScriptModel {
                    values: volumeIndicator.outputDevices
                }
                delegate: AudioDeviceMenuItem {
                    required property var modelData
                    node: modelData
                    label: volumeIndicator.nodeName(modelData)
                    isDefault: modelData === volumeIndicator.sink
                    action: () => {
                        Pipewire.preferredDefaultAudioSink = modelData;
                    }
                }
            }
        },
        DropdownMenuHeader {
            text: "Input"
        },
        VolumeMenuItem {
            visible: volumeIndicator.source !== null
            node: volumeIndicator.source
            label: volumeIndicator.source ? volumeIndicator.nodeName(volumeIndicator.source) : ""
            labelElide: Text.ElideMiddle
            isInput: true
            monitorPeaks: volumeIndicator.menuVisible
            extraButtonIcon: volumeIndicator.inputDevices.length > 1 ? "right-left" : ""
            extraButtonHighlighted: volumeIndicator.inputDevicesExpanded
            extraButtonAction: () => {
                volumeIndicator.inputDevicesExpanded = !volumeIndicator.inputDevicesExpanded;
            }
        },
        DropdownMenuItem {
            visible: volumeIndicator.source === null
            StyledText {
                font.pixelSize: 16
                color: AppConstants.mutedIconColor
                text: "No input device"
            }
        },
        ScrollingMenuList {
            rowCount: volumeIndicator.inputDevicesExpanded ? inputDevicesRepeater.count : 0
            maxVisibleRows: volumeIndicator.devicesShown

            Repeater {
                id: inputDevicesRepeater
                model: ScriptModel {
                    values: volumeIndicator.inputDevices
                }
                delegate: AudioDeviceMenuItem {
                    required property var modelData
                    node: modelData
                    label: volumeIndicator.nodeName(modelData)
                    isDefault: modelData === volumeIndicator.source
                    action: () => {
                        Pipewire.preferredDefaultAudioSource = modelData;
                    }
                }
            }
        },
        DropdownMenuHeader {
            text: "Playing"
        },
        DropdownMenuItem {
            visible: volumeIndicator.playbackStreams.length === 0
            StyledText {
                font.pixelSize: 16
                color: AppConstants.mutedIconColor
                text: "Nothing is playing"
            }
        },
        ScrollingMenuList {
            rowCount: playbackStreamsRepeater.count
            maxVisibleRows: volumeIndicator.streamsShown

            Repeater {
                id: playbackStreamsRepeater
                model: ScriptModel {
                    values: volumeIndicator.playbackStreams
                }
                delegate: VolumeMenuItem {
                    required property var modelData
                    // The first row is at the top of the scroll area, but
                    // still follows the rows above it.
                    showSeparator: true
                    node: modelData
                    label: volumeIndicator.streamName(modelData)
                    monitorPeaks: volumeIndicator.menuVisible
                }
            }
        },
        // Which apps are listening, e.g. to notice a forgotten call.
        DropdownMenuHeader {
            visible: volumeIndicator.recordingStreams.length > 0
            text: "Recording"
        },
        ScrollingMenuList {
            rowCount: recordingStreamsRepeater.count
            maxVisibleRows: volumeIndicator.streamsShown

            Repeater {
                id: recordingStreamsRepeater
                model: ScriptModel {
                    values: volumeIndicator.recordingStreams
                }
                delegate: VolumeMenuItem {
                    required property var modelData
                    showSeparator: true
                    node: modelData
                    label: volumeIndicator.streamName(modelData)
                    isInput: true
                    monitorPeaks: volumeIndicator.menuVisible
                }
            }
        }
    ]
}
