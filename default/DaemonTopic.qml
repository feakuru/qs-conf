import QtQuick

// A subscription to one of qs-conf-daemon's topics, held while `active`:
//
//     DaemonTopic {
//         topic: "cpu.details"
//         active: cpuIndicator.menuVisible
//         onData: payload => { ... }
//     }
//
// The daemon only samples a topic while something is subscribed to it.
// Several DaemonTopics with the same topic share one subscription.
QtObject {
    id: daemonTopic

    required property string topic
    property bool active: true
    // The last payload, or null before the first one. Kept while inactive.
    property var latest: null

    signal data(var payload)

    // The topic currently subscribed to, if any.
    property string subscribedTopic: ""

    // For Daemon.
    function receive(payload): void {
        daemonTopic.latest = payload;
        daemonTopic.data(payload);
    }

    function updateSubscription(): void {
        let wanted = daemonTopic.active ? daemonTopic.topic : "";
        if (wanted === daemonTopic.subscribedTopic) {
            return;
        }
        if (daemonTopic.subscribedTopic !== "") {
            Daemon.removeListener(daemonTopic.subscribedTopic, daemonTopic);
        }
        daemonTopic.subscribedTopic = wanted;
        if (wanted !== "") {
            Daemon.addListener(wanted, daemonTopic);
        }
    }

    onActiveChanged: daemonTopic.updateSubscription()
    onTopicChanged: daemonTopic.updateSubscription()
    Component.onCompleted: daemonTopic.updateSubscription()
    Component.onDestruction: {
        if (daemonTopic.subscribedTopic !== "") {
            Daemon.removeListener(daemonTopic.subscribedTopic, daemonTopic);
        }
    }
}
