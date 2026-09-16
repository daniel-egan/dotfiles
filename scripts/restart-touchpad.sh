#!/usr/bin/env bash
set -e

QUIRK_FILE=/etc/libinput/local-overrides.quirks
sudo mkdir -p /etc/libinput
sudo tee "$QUIRK_FILE" > /dev/null <<'QUIRK_EOF'
# Elan Touchpad fix - treat as trackpad not touchscreen
[Elan CUST0000:00]
MatchBus=i2c
MatchVendor=04F3
MatchProduct=2A81
MatchName=CUST0000:00 04F3:2A81
AttrPressureRange=0:0
QUIRK_EOF

sudo rmmod i2c_hid_acpi || true
sleep 1
sudo modprobe i2c_hid_acpi
