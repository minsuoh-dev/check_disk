#!/bin/bash

DEVICE_NAME=$1

create_gpt_partition() {
    echo "Creating GPT partition..."
    parted /dev/$DEVICE_NAME mklabel gpt
    parted /dev/$DEVICE_NAME mkpart primary 0 100%
    parted /dev/$DEVICE_NAME align-check optimal 1
}

create_partition_fdisk() {
    echo "Creating a partition using fdisk..."
    (
        echo n  # New partition
        echo p  # Primary partition
        echo    # Default: First partition
        echo    # Default: First sector
        echo    # Default: Last sector (full disk)
        echo w  # Write changes
    ) | fdisk /dev/$DEVICE_NAME
}

format_device() {
    echo "Formatting device..."
    mkfs.ext4 /dev/${DEVICE_NAME}1
}

mount_check() {
    echo "Performing mount check..."
    mkdir -p /back
    mount /dev/${DEVICE_NAME}1 /back
    MOUNT_STATUS=$?
    if [ $MOUNT_STATUS -eq 0 ]; then
        echo "Mount OK: True"
        df -Th
        umount /back
    else
        echo "Mount OK: False"
    fi
}

test_storage() {
    echo "Testing storage device..."
    ./HDsentinel
    smartctl -a /dev/$DEVICE_NAME
}

get_smartctl_value() {
    ATTRIBUTE_NAME=$1
    smartctl -A /dev/$DEVICE_NAME | grep -i "$ATTRIBUTE_NAME" | awk '{print $10}'
}

if [ -z "$DEVICE_NAME" ]; then
    echo "Usage: $0 <device_name>"
    exit 1
fi

echo "Checking storage size..."
STORAGE_SIZE=$(parted /dev/$DEVICE_NAME unit GB print | grep Disk | awk '{print $3}' | sed 's/GB//')

if [ $(echo "$STORAGE_SIZE > 1900" | bc) -eq 1 ]; then
    create_gpt_partition
    DEVICE_PARTITION_TYPE="GPT"
else
    create_partition_fdisk
    DEVICE_PARTITION_TYPE="MBR"
fi

format_device
mount_check
test_storage

DEVICE_TYPE=$(hdparm -I /dev/$DEVICE_NAME | grep "Model Number" | awk -F':' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//')
DEVICE_HEALTH=$(./HDsentinel | grep "Health:" | awk '{print $2}')

echo "Summary:"
echo "DEVICE_NAME: $DEVICE_NAME"
echo "DEVICE_TYPE: $DEVICE_TYPE"
echo "DEVICE_SIZE: $STORAGE_SIZE GB"
echo "DEVICE_PARTITION_TYPE: $DEVICE_PARTITION_TYPE"
echo "DEVICE_HEALTH: $DEVICE_HEALTH"

echo "Finished."
