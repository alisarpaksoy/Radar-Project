# MATLAB App

This folder contains the MATLAB App Designer implementation used in the Radar Project.

## Purpose

The MATLAB application is the main software interface of the project. It receives measurement data from the ESP32, processes the incoming signals, and visualizes the results in real time.

The app was developed to support both system monitoring and signal analysis. It allows the user to observe the scanned environment, compare raw and filtered distance signals, and inspect the frequency content of the measured data.

## Main Functions

The MATLAB App performs the following tasks:

* opens serial communication with the ESP32,
* receives angle and distance data in real time,
* stores distance, angle, and timestamp values,
* displays a radar-like spatial map,
* plots raw distance versus time,
* applies moving average filtering,
* computes the FFT of the first 10 seconds of data,
* displays the one-sided magnitude spectrum,
* plots the live servo angle over time.

## Included File

The main file in this folder is:

* `Radartestapp.mlapp` — MATLAB App Designer file containing the graphical user interface, serial communication logic, live plotting, and signal processing implementation.

## App Views

The MATLAB App includes three main visualization modes.

### Radar View

This mode displays detected object positions on a radar-like map. The measured angle and distance are converted from polar coordinates into Cartesian coordinates to generate a two-dimensional spatial representation.

### Distance View

This mode displays:

* the raw distance signal,
* the filtered distance signal,
* the FFT spectrum of the first 10 seconds of the measured signal.

This is the most important mode for signal processing analysis.

### Angle View

This mode displays the servo angle as a function of time. It helps monitor the scanning motion and verify the angular behavior of the system.

## Signal Processing Implementation

The MATLAB App contains the main signal processing stage of the project.

### Moving Average Filtering

The raw distance signal is smoothed using a moving average filter. This reduces short-term fluctuations and measurement noise while preserving the general trend of the signal.

### DC Offset Removal

Before computing the FFT, the mean value of the selected signal segment is subtracted. This removes the DC offset and allows the spectral analysis to focus on variations in the signal rather than the average distance level.

### Sampling Frequency Estimation

Since the data is acquired in real time through serial communication, the sampling interval is not perfectly constant. The app therefore estimates the effective sampling frequency from the recorded timestamps.

### Fast Fourier Transform

The FFT is applied to the first 10 seconds of the distance signal. The resulting one-sided magnitude spectrum is displayed in the app to show dominant frequency components in the measured motion.

## Role in the Project

The MATLAB App is the main analysis environment of the Radar Project. It transforms raw embedded measurements into clear engineering outputs by combining:

* acquisition,
* visualization,
* filtering,
* spectral analysis.

This makes the software a key part of the overall system, not just a display tool.

## Notes

This folder is intended for MATLAB App files only.

Related folders:

* `images/app/` — screenshots of the MATLAB interface
* `images/results/` — plots and processed output images
* `docs/` — article drafts and written documentation

## Future Improvements

Possible future developments for the MATLAB App include:

* direct velocity estimation from distance-time data,
* acceleration estimation,
* more advanced filtering methods,
* automatic peak detection in the FFT spectrum,
* data export and logging features,
* a more advanced user interface.
