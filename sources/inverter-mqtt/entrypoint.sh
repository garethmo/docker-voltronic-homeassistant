#!/bin/bash

UNBUFFER='stdbuf -i0 -oL -eL'

# stty -F /dev/ttyUSB0 2400 raw

# Init the mqtt server. This creates the config topics in the MQTT server
# that the MQTT integration uses to create entities in HA.
echo "[INFO] Initializing MQTT topics..."
$UNBUFFER /opt/inverter-mqtt/mqtt-init.sh

echo "[INFO] Starting main control loop..."
# This loop now runs both the push (polling) and subscriber (listening)
# scripts one after the other, preventing them from conflicting over the
# serial/USB port.
while :; do
    # 1. Run the push script to get data from the inverter and send it to MQTT.
    # This is the script that was crashing due to the conflict.
    $UNBUFFER /opt/inverter-mqtt/mqtt-push.sh

    # 2. Run the subscriber script for a few seconds to check for any incoming commands.
    # The 'timeout' command is crucial here. It runs the subscriber for 5 seconds
    # and then stops it, ensuring it doesn't block the loop forever and releases
    # the port for the next polling cycle.
    timeout 5s $UNBUFFER /opt/inverter-mqtt/mqtt-subscriber.sh

    # 3. Wait for 2 seconds before repeating the cycle. The total loop time will be
    # roughly 7 seconds plus the time it takes for the scripts to run.
    sleep 2s
done
