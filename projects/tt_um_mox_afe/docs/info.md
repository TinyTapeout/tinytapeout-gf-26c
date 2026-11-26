<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

Readout front end for a metal-oxide (MOX) gas sensor. A current conveyor holds the selected input (sensor, reference
resistor or leakage-test pin) at the bias voltage and integrates its current on a capacitor chosen by RANGE. A comparator
and a one-shot reset the capacitor at a fixed threshold, so the PULSE rate is proportional to the input current.
The ratio of the sensor and reference pulse rates (with two zero readings) gives the result independent of the absolute
capacitor and threshold values.

## How to test

Connect the sensor to ua[0] and the reference resistor to ua[1], apply 0.5 V to ua[2] (VBIAS). Select the input with
INSEL (ui[1:0]: 00 sensor, 01 reference, 10 leakage test, 11 open) and the capacitor with RANGE (ui[3:2]). Count PULSE
(uo[0]) or PULSE_DIV2 (uo[2]) over a fixed gate time for each input and take the ratio. MON_EN (ui[4]) = 1 buffers the
integrator voltage to ua[4] for observation; keep it 0 while measuring.

## External hardware

MOX gas sensor, reference resistor (100 kOhm / 4.7 MOhm / 47 MOhm / 1 GOhm, one per RANGE), 0.5 V bias source and a
pulse counter (e.g. a microcontroller).
