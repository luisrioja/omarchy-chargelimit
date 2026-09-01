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

Left click / wheel up = next preset. Right click / wheel down = previous.
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
scoped to that one script + a boot service that re-applies the threshold, since
the EC forgets it on power-off):

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

The cycle presets and the start/stop gap are environment overrides read by the
service and the CLI:

| Variable | Default | Meaning |
|---|---|---|
| `CHARGE_LIMIT_PRESETS` | `100 90 80` | presets to cycle, high to low |
| `CHARGE_LIMIT_GAP` | `5` | `start_threshold = stop − GAP` (hysteresis; it won't recharge until it drops below `start`) |

To change them for the boot service, add a drop-in:

```bash
sudo systemctl edit omarchy-chargelimit.service
# [Service]
# Environment=CHARGE_LIMIT_PRESETS=100 85 70
```

## CLI

```
omarchy-chargelimit status        # current stop threshold
omarchy-chargelimit list          # battery sysfs dirs it will touch
sudo omarchy-chargelimit set 80   # set + persist
sudo omarchy-chargelimit cycle    # next preset
```

## How it works

- `charge_control_end_threshold` / `charge_control_start_threshold` are the
  native kernel knobs (no `tlp`, `tp_smapi` or `acpi_call` needed).
- The value you pick is saved to `/var/lib/omarchy-chargelimit/limit`; the
  `omarchy-chargelimit.service` oneshot re-applies it on every boot.
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
