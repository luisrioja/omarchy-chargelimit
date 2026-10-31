import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Battery charge stop-threshold toggle for the Omarchy (quickshell) bar.
//
//   left click  / wheel up   -> next lower preset  (100 -> 90 -> 80 -> 100)
//   right click / wheel down  -> next higher preset
//
// Presets live in /etc/omarchy-chargelimit.conf, so the tooltip stays generic.
//
// Reads the live threshold from /sys (world-readable); writes it through
// `sudo -n /usr/local/bin/omarchy-chargelimit` (see the repo's install.sh and
// etc/sudoers.d/omarchy-chargelimit). Hides itself on hardware with no
// charge_control_end_threshold support.
BarWidget {
  id: root
  moduleName: "luisrioja.chargelimit"

  // Current stop threshold read from sysfs. 100 == no cap.
  property int limit: 100
  // False when no battery exposes charge_control_end_threshold.
  property bool supported: true
  readonly property bool capped: limit > 0 && limit < 100

  visible: supported
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function refresh() {
    if (!readProc.running) readProc.running = true
  }

  function cycle(back) {
    if (setProc.running) return
    setProc.command = ["sudo", "-n", "/usr/local/bin/omarchy-chargelimit",
                       back ? "cycle-back" : "cycle"]
    setProc.running = true
  }

  Timer {
    interval: 30000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Process {
    id: readProc
    command: ["sh", "-c",
      "cat /sys/class/power_supply/BAT*/charge_control_end_threshold 2>/dev/null | head -n1"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var s = String(text).trim()
        var n = parseInt(s, 10)
        if (s.length > 0 && !isNaN(n) && n > 0) {
          root.limit = n
          root.supported = true
        } else {
          root.supported = false
        }
      }
    }
  }

  Process {
    id: setProc
    onExited: function (code) {
      root.refresh()
      if (code !== 0 && root.bar)
        root.bar.run("notify-send -a 'Battery' -u critical 'Charge limit' " +
                     "'Could not apply (check the omarchy-chargelimit install / sudoers)'")
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    // nf-md-battery-80 when capped, nf-md-battery (full) when not.
    text: (root.capped ? "󰂂 " : "󰁹 ") + root.limit
    fontSize: Style.font.caption
    horizontalMargin: 6
    tooltipText: (root.capped ? ("Charge limit " + root.limit + "%")
                              : "No charge limit (100%)") +
      "\nclick / wheel up: lower preset\nright click / wheel down: higher preset"
    onPressed: function (btn) {
      root.cycle(btn === Qt.RightButton)
    }
    onWheelMoved: function (delta) {
      root.cycle(delta < 0)
    }
  }
}
