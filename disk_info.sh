#!/bin/bash

DEVICE_NAME=$1

if [ -z "$DEVICE_NAME" ]; then
    echo "Usage: $0 <device_name>"
    exit 1
fi

DEVICE_MODEL=$(smartctl -i /dev/$DEVICE_NAME | grep "Device Model" | awk -F':' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//')
DEVICE_SERIAL=$(smartctl -i /dev/$DEVICE_NAME | grep "Serial Number" | awk -F':' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//')
DEVICE_HEALTH=$(./HDSentinel | grep "Health:" | awk '{print $2}')
DEVICE_SIZE=$(lsblk -o NAME,SIZE -b /dev/$DEVICE_NAME | grep $DEVICE_NAME$ | awk '{print $2}' | numfmt --to=iec-i --suffix=B --format="%.0f")

echo "DEVICE_NAME: $DEVICE_NAME"
echo "DEVICE_MODEL: $DEVICE_MODEL"
echo "DEVICE_SERIAL: $DEVICE_SERIAL"
echo "DEVICE_HEALTH: $DEVICE_HEALTH"
echo "DEVICE_SIZE: $DEVICE_SIZE"
