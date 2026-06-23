# ESP32 Code

This folder contains the ESP32 firmware for the Radar Project.

## Purpose

The ESP32 code is responsible for:

* initializing the laser time-of-flight sensor,
* controlling the SG90 servo motor,
* receiving start and stop commands from MATLAB,
* performing angular scanning,
* reading distance measurements,
* sending angle and distance data through serial communication.

## Main Functionality

The firmware creates the embedded control layer of the project. During operation, the ESP32 performs the following tasks:

1. Initializes serial communication at **115200 baud**
2. Initializes I2C communication for the distance sensor
3. Starts continuous distance measurement
4. Attaches and controls the servo motor
5. Waits for commands from MATLAB
6. Starts scanning when the `START` command is received
7. Stops scanning and returns the servo to the center position when the `STOP` command is received
8. Sends measurement data in text format for MATLAB processing

## Current Implementation

The current code uses:

* **VL53L1X** laser time-of-flight sensor
* **ESP32Servo** library for servo control
* **Wire** library for I2C communication

The servo scans between **0° and 180°**. For each angular position, the ESP32 reads the current distance and sends the result through serial communication.

The output format is:

```text
Angle: <value> | Distance: <value> mm
```

This format is used by the MATLAB application to parse and process the incoming measurements.

## Used Pins

The current implementation uses:

* **Servo signal pin:** GPIO 18
* **I2C SDA:** GPIO 21
* **I2C SCL:** GPIO 22

## Workflow

The firmware logic can be summarized as follows:

* system starts in idle mode
* servo is positioned at the center angle
* MATLAB sends `START`
* ESP32 begins scanning
* angle changes step by step between 0° and 180°
* distance is measured at each angle
* data is transmitted through serial output
* MATLAB sends `STOP`
* ESP32 stops scanning and returns servo to the center position

## File Contents

Typical file in this folder:

* `RadarProjectIDE.ino` — main ESP32 source file for sensor reading, servo control, and serial communication

## Notes

This code is designed to work together with the MATLAB App in the `matlab_app` folder. The MATLAB application reads the serial output, extracts angle and distance values, and performs visualization and signal processing.

## Future Improvements

Possible improvements for the ESP32 code include:

* faster and more stable timing control
* configurable scan range and scan speed
* improved command handling
* error handling for sensor read failures
* timestamp transmission from the embedded side
* support for object motion analysis
