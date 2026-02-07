import Quickshell.Io

Process {
    command: ["uv", "run", Qt.resolvedUrl(`scripts/${scriptName}.py`).toString().replace(/^file:\/{2}/, "")].concat(scriptArgs)
    workingDirectory: Qt.resolvedUrl(".").toString().replace(/^file:\/{2}/, "")
    required property string scriptName
    property var scriptArgs: []

    stderr: StdioCollector {
        onStreamFinished: {
            if (this.text.trim().length > 0) {
                console.log(`Error in script process (${scriptName})\n`, this.text);
            }
        }
    }
}
