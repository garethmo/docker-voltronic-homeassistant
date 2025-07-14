#!/bin/bash

UNBUFFER='stdbuf -i0 -oL -eL'

# stty -F /dev/ttyUSB0 2400 raw

# Init the mqtt server. This creates the config topics in the MQTT server
# that the MQTT integration uses to create entities in HA.
echo "[INFO] Initializing MQTT topics..."
$UNBUFFER /opt/inverter-mqtt/mqtt-init.sh
echo "[INFO] MQTT topic initialization complete."

echo "[INFO] Starting main control loop..."
# This loop now runs both the push (polling) and subscriber (listening)
# scripts one after the other, preventing them from conflicting over the
# serial/USB port.
while :; do
    # 1. Run the push script to get data from the inverter and send it to MQTT.
    echo "[INFO] Polling inverter for data..."
    $UNBUFFER /opt/inverter-mqtt/mqtt-push.sh
    echo "[INFO] Polling complete."

    # 2. Run the subscriber script for a few seconds to check for any incoming commands.
    # The 'timeout' command is crucial here. We now use --signal=SIGINT to send
    # a gentler interrupt signal (like Ctrl+C), which allows the subscriber
    # to shut down cleanly and release the serial port properly.
    echo "[INFO] Listening for commands for 5 seconds..."
    timeout --signal=SIGINT 5s $UNBUFFER /opt/inverter-mqtt/mqtt-subscriber.sh
    echo "[INFO] Listening complete."

    # 3. Wait for 2 seconds before repeating the cycle. The total loop time will be
    # roughly 7 seconds plus the time it takes for the scripts to run.
    echo "[INFO] Waiting for 2 seconds before next cycle..."
    sleep 2s
done
