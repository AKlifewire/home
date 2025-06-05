@echo off
echo Publishing device configuration to IoT Core...

aws iot-data publish --topic "device/esp32-relay-001/config" --payload file://lambda/ui-generator/examples/relay-controller-config.json

echo Done!