pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The connection to qs-conf-daemon, the companion daemon that serves system
// data (topics) and actions (methods) over a Unix socket, one JSON object per
// line. See the daemon's README for the protocol, topics and methods.
//
// Subscribe to topics with DaemonTopic; call methods with Daemon.call().
// Socket never reconnects on its own once it has been connected, so a Timer
// retries while disconnected (the daemon may restart), and every topic that
// is still wanted is subscribed again after reconnecting.
Singleton {
    id: daemon

    readonly property string socketPath: `${Quickshell.env("XDG_RUNTIME_DIR")}/qs-conf-daemon.sock`
    readonly property int protocol: 1
    // Connected, and the daemon speaks our protocol version.
    readonly property bool connected: socket.connected && daemon.helloReceived
    // "connected", "connecting" (waiting for the daemon's hello),
    // "incompatible" (another protocol version) or "disconnected".
    readonly property string connectionState: {
        if (!socket.connected) {
            return "disconnected";
        }
        if (daemon.helloReceived) {
            return "connected";
        }
        return daemon.daemonProtocol !== 0 ? "incompatible" : "connecting";
    }
    // From the daemon's hello; empty/0 while not connected.
    property string daemonVersion: ""
    property int daemonProtocol: 0

    property bool helloReceived: false
    // Topic -> the DaemonTopics that want it.
    readonly property var listeners: ({})
    // Topic -> its last payload, for DaemonTopics that join an active topic.
    readonly property var lastPayloads: ({})
    // Call id -> callback.
    readonly property var pendingCalls: ({})
    property int nextCallId: 1

    // Each failed attempt logs a warning, so retries back off.
    readonly property int minRetryDelay: 250
    readonly property int maxRetryDelay: 5000
    property int retryDelay: minRetryDelay

    // Calls `method` with `params` (any JSON value, or undefined). With a
    // callback, it is called as callback(result, error) once the daemon
    // replies: `error` is a string if the call failed, otherwise undefined.
    // Without one, the call is fire-and-forget: the daemon sends no reply.
    // Returns false (and calls back with an error) if not connected.
    function call(method: string, params, callback): bool {
        if (!daemon.connected) {
            if (callback) {
                callback(undefined, "not connected to qs-conf-daemon");
            }
            return false;
        }
        let request = {
            op: "call",
            method: method
        };
        if (params !== undefined) {
            request.params = params;
        }
        if (callback) {
            request.id = daemon.nextCallId++;
            daemon.pendingCalls[request.id] = callback;
        }
        daemon.send(request);
        return true;
    }

    // Calls daemon.ping and reports the round trip as callback(ms, error).
    function ping(callback): void {
        let start = Date.now();
        daemon.call("daemon.ping", undefined, (result, error) => callback(Date.now() - start, error));
    }

    // For DaemonTopic.
    function addListener(topic: string, listener): void {
        let list = daemon.listeners[topic];
        if (list === undefined) {
            list = [];
            daemon.listeners[topic] = list;
        }
        if (list.includes(listener)) {
            return;
        }
        list.push(listener);
        if (list.length === 1) {
            if (daemon.connected) {
                daemon.send({
                    op: "subscribe",
                    topic: topic
                });
            }
        } else if (topic in daemon.lastPayloads) {
            listener.receive(daemon.lastPayloads[topic]);
        }
    }

    // For DaemonTopic.
    function removeListener(topic: string, listener): void {
        let list = daemon.listeners[topic];
        if (list === undefined || !list.includes(listener)) {
            return;
        }
        list.splice(list.indexOf(listener), 1);
        if (list.length === 0) {
            delete daemon.listeners[topic];
            delete daemon.lastPayloads[topic];
            if (daemon.connected) {
                daemon.send({
                    op: "unsubscribe",
                    topic: topic
                });
            }
        }
    }

    function send(message): void {
        socket.write(JSON.stringify(message) + "\n");
        socket.flush();
    }

    function handleLine(line: string): void {
        let message;
        try {
            message = JSON.parse(line);
        } catch (e) {
            console.warn("Daemon: invalid line:", line);
            return;
        }
        if (message.topic !== undefined) {
            daemon.deliver(message.topic, message.data);
        } else if (message.hello !== undefined) {
            daemon.handleHello(message.hello);
        } else if (message.id !== undefined) {
            let callback = daemon.pendingCalls[message.id];
            delete daemon.pendingCalls[message.id];
            if (callback) {
                callback(message.result, message.error);
            }
        }
    }

    function deliver(topic: string, payload): void {
        let list = daemon.listeners[topic];
        if (list === undefined) {
            // Sent before our unsubscribe arrived.
            return;
        }
        daemon.lastPayloads[topic] = payload;
        // A listener may unsubscribe while handling its payload.
        for (let listener of list.slice()) {
            listener.receive(payload);
        }
    }

    function handleHello(hello): void {
        daemon.daemonVersion = hello.version;
        daemon.daemonProtocol = hello.protocol;
        if (hello.protocol !== daemon.protocol) {
            console.warn(`Daemon: qs-conf-daemon ${hello.version} speaks protocol ${hello.protocol}, the shell ${daemon.protocol}`);
            return;
        }
        daemon.helloReceived = true;
        for (let topic in daemon.listeners) {
            daemon.send({
                op: "subscribe",
                topic: topic
            });
        }
    }

    // Fails the calls still waiting for a reply and forgets the payloads,
    // which won't be updated until the next connection.
    function handleDisconnect(): void {
        daemon.helloReceived = false;
        daemon.daemonVersion = "";
        daemon.daemonProtocol = 0;
        for (let topic in daemon.lastPayloads) {
            delete daemon.lastPayloads[topic];
        }
        let callbacks = Object.values(daemon.pendingCalls);
        for (let id in daemon.pendingCalls) {
            delete daemon.pendingCalls[id];
        }
        for (let callback of callbacks) {
            callback(undefined, "disconnected from qs-conf-daemon");
        }
    }

    // For checking the connection from a terminal:
    //   qs ipc call daemon status
    //   qs ipc call daemon ping    (the result goes to the log: qs log)
    IpcHandler {
        target: "daemon"

        function status(): string {
            return daemon.daemonVersion !== "" ? `${daemon.connectionState} (qs-conf-daemon ${daemon.daemonVersion}, protocol ${daemon.daemonProtocol})` : daemon.connectionState;
        }

        function ping(): void {
            daemon.ping((ms, error) => {
                if (error !== undefined) {
                    console.warn("Daemon: ping failed:", error);
                } else {
                    console.log(`Daemon: pong in ${ms} ms`);
                }
            });
        }
    }

    Socket {
        id: socket
        path: daemon.socketPath
        connected: true

        onConnectedChanged: {
            if (socket.connected) {
                daemon.retryDelay = daemon.minRetryDelay;
            } else {
                daemon.handleDisconnect();
            }
        }

        parser: SplitParser {
            onRead: data => daemon.handleLine(data)
        }
    }

    Timer {
        id: reconnectTimer
        interval: daemon.retryDelay
        running: !socket.connected
        repeat: true
        onTriggered: {
            socket.connected = true;
            daemon.retryDelay = Math.min(daemon.retryDelay * 2, daemon.maxRetryDelay);
        }
    }
}
