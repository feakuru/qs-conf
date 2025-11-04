import Quickshell.Io

Process {
    command: ["uv", "run", Qt.resolvedUrl(`scripts/${scriptName}.py`).toString().replace(/^file:\/{2}/, ""),]
    workingDirectory: Qt.resolvedUrl(".").toString().replace(/^file:\/{2}/, "")
    required property string scriptName

    stderr: StdioCollector {
        onStreamFinished: {
            if (this.text.trim().length > 0) {
                console.log(`Error in script process (${scriptName})\n`, this.text);
            }
        }
    }
}
