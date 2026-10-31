# omarchy-chargelimit

A tiny bar widget for [Omarchy](https://omarchy.org) 4 (which runs its bar on
[Quickshell](https://quickshell.org), not Waybar) to **cycle the battery charge
stop threshold** from the bar — `100 → 90 → 80` by default.

Keeping a laptop battery pinned at 100% while it lives on AC ages it faster. A
lower charge ceiling helps, but a fixed low ceiling costs you runtime when you're
actually mobile. This lets you flip it per situation with one click:

| Preset | When |
|---|---|
| **100** | travelling / away from a socket — full runtime |
| **90** | normal desk use plugged in |
| **80** | plugged in for days without moving |

```
󰁹 100     ← click →     󰂂 90     ← click →     󰂂 80
```

Left click / wheel up = next lower preset (wrapping to the highest).
Right click / wheel down = next higher preset (wrapping to the lowest).
The widget reads the live value from `/sys` and hides itself on hardware with no
charge-threshold support.

## Requirements

- Omarchy 4+ (Quickshell bar / `omarchy-shell`).
- A laptop whose kernel exposes
  `/sys/class/power_supply/BAT*/charge_control_end_threshold`. That's every
  ThinkPad with `thinkpad_acpi`, and many other laptops on recent kernels.
- Dual-battery ThinkPads (T470s, T480 + slice, …) are handled — every supported
  `BAT*` gets the same threshold.

## Install

**1. The privileged backend** (helper script + a `%wheel` NOPASSWD sudoers line
scoped to that one script + a boot service and udev rule that re-apply the
threshold, since the EC forgets it on power-off):

```bash
git clone https://github.com/luisrioja/omarchy-chargelimit.git
cd omarchy-chargelimit
./install.sh          # asks for sudo
```

**2. The widget** (a normal Omarchy plugin):

```bash
omarchy plugin add https://github.com/luisrioja/omarchy-chargelimit.git --enable --yes
```

or, from the clone you already have:

```bash
mkdir -p ~/.config/omarchy/plugins/luisrioja.chargelimit
cp manifest.json ChargeLimit.qml ~/.config/omarchy/plugins/luisrioja.chargelimit/
omarchy-shell shell rescanPlugins
omarchy plugin enable luisrioja.chargelimit
```

Reposition it with `omarchy bar move luisrioja.chargelimit …` or by dragging.

## Configure

Presets and the start/stop gap live in `/etc/omarchy-chargelimit.conf`
(installed by `install.sh`, kept on reinstall). Both the widget and the boot
service read it, and changes apply on the next click — no restart needed:

```bash
sudoedit /etc/omarchy-chargelimit.conf
```

```ini
PRESETS="100 85 70"   # stop thresholds to cycle (40–100), any order
GAP=5                 # start_threshold = stop − GAP (hysteresis)
```

The widget goes through `sudo`, which wipes the environment, so environment
variables (`CHARGE_LIMIT_PRESETS`, `CHARGE_LIMIT_GAP`) only take effect when you
run the CLI as root directly; there they override the file.

If the current threshold isn't one of the presets (say it's 85 with the
default `100 90 80`), a click moves to the nearest preset below it (80) and a
right click to the nearest one above it (90).

## CLI

```
omarchy-chargelimit status        # current stop threshold
omarchy-chargelimit list          # battery sysfs dirs it will touch
omarchy-chargelimit presets       # presets it cycles through
sudo omarchy-chargelimit set 80   # set + persist
sudo omarchy-chargelimit cycle    # next preset
```

## How it works

- `charge_control_end_threshold` / `charge_control_start_threshold` are the
  native kernel knobs (no `tlp`, `tp_smapi` or `acpi_call` needed).
- The value you pick is saved to `/var/lib/omarchy-chargelimit/limit` (only
  once the kernel has accepted it); the
  `omarchy-chargelimit.service` oneshot re-applies it on every boot.
- A udev rule (`/etc/udev/rules.d/90-omarchy-chargelimit.rules`) starts that
  service when a battery appears or when a driver that adds the threshold knob
  (`thinkpad_acpi`, `asus_wmi`, …) finishes loading, so the value lands even if
  the driver loads late in boot, and again when you hot-plug a battery.
- The QML widget never touches `/sys` directly — it shells out to
  `sudo -n /usr/local/bin/omarchy-chargelimit`, which the sudoers snippet allows
  for the `wheel` group without a password. Prefer polkit? Drop the sudoers file
  and add a `pkexec` rule instead; the widget command is a one-line change.

## Uninstall

```bash
omarchy plugin disable luisrioja.chargelimit
./uninstall.sh
```

## License

MIT — see [LICENSE](LICENSE).
