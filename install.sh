#!/usr/bin/env bash
# Installs the privileged backend for the omarchy-chargelimit bar widget:
#   - /usr/local/bin/omarchy-chargelimit          (the helper script)
#   - /etc/sudoers.d/omarchy-chargelimit          (%wheel, NOPASSWD, this script only)
#   - /etc/systemd/system/omarchy-chargelimit.service  (re-apply on boot)
#
# The widget itself (manifest.json + ChargeLimit.qml) is a normal Omarchy plugin:
#   omarchy plugin add https://github.com/luisrioja/omarchy-chargelimit.git --enable --yes
# or, if you cloned this repo by hand, copy manifest.json + ChargeLimit.qml into
#   ~/.config/omarchy/plugins/luisrioja.chargelimit/
# then:  omarchy-shell shell rescanPlugins && omarchy plugin enable luisrioja.chargelimit
set -euo pipefail

cd "$(dirname "$0")"

if [ "$(id -u)" -ne 0 ]; then
  echo "Re-running with sudo..." >&2
  exec sudo -- "$0" "$@"
fi

install -m 0755 bin/omarchy-chargelimit /usr/local/bin/omarchy-chargelimit

# Validate the sudoers snippet before dropping it in place.
visudo -cf etc/sudoers.d/omarchy-chargelimit
install -m 0440 etc/sudoers.d/omarchy-chargelimit /etc/sudoers.d/omarchy-chargelimit

install -m 0644 etc/systemd/system/omarchy-chargelimit.service \
  /etc/systemd/system/omarchy-chargelimit.service
systemctl daemon-reload
systemctl enable omarchy-chargelimit.service

echo
echo "Backend installed. Quick check:"
echo "  omarchy-chargelimit list"
echo "  sudo omarchy-chargelimit set 90 && omarchy-chargelimit status"
echo "  sudo -n omarchy-chargelimit cycle          # must work with no password"
echo
echo "Then enable the widget (see this repo's README)."
