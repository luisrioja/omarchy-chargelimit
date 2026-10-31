#!/usr/bin/env bash
# Removes the omarchy-chargelimit backend. Does not touch the plugin —
# use `omarchy plugin disable luisrioja.chargelimit` for that.
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  exec sudo -- bash "$(readlink -f -- "$0")" "$@"
fi

systemctl disable --now omarchy-chargelimit.service 2>/dev/null || true
rm -f /etc/udev/rules.d/90-omarchy-chargelimit.rules
udevadm control --reload 2>/dev/null || true
rm -f /etc/systemd/system/omarchy-chargelimit.service
rm -f /etc/sudoers.d/omarchy-chargelimit
rm -f /usr/local/bin/omarchy-chargelimit
rm -f /etc/omarchy-chargelimit.conf
rm -rf /var/lib/omarchy-chargelimit
systemctl daemon-reload

echo "Backend removed. The thresholds currently set in the EC stay until reboot;"
echo "clear them now with, e.g.:"
echo "  for b in /sys/class/power_supply/BAT*; do echo 100 | sudo tee \$b/charge_control_end_threshold; done"
