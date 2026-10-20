<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

A two-stage Miller-compensated op-amp (NMOS input pair) with digital trims, all set by an on-chip
40-bit serial register:

- tail current (5 bit) and second-stage current (5 bit)
- Miller capacitor (4 bit) and nulling resistor (4 bit, decoded one-hot on chip)
- input offset (sign + 4 bit)
- master bias (5 bit): 40 µA into the op-amp at the reset code, from a 5 µA reference

The reference comes from an on-chip constant-gm bias (BIAS_SEL = 1) or from an external 5 µA sink
on IREF (BIAS_SEL = 0). UNITY_EN closes the op-amp as a unity-gain buffer on chip, so it can be
characterized with four analog pins; it also cuts VINN off from the inverting input. VINP, VINN and
IREF have CDM protection.

| Bits | Field | Reset |
|---|---|---|
| 39:35 | master bias | 16 |
| 34:30 | tail current | 15 |
| 29:25 | second-stage current | 19 |
| 24:20 | offset: sign (bit 24) + magnitude | 0 |
| 19:16 | Miller capacitor | 4 |
| 15:12 | nulling resistor | 14 |
| 11:0 | unused | 1010 1110 0000 |

Reset word 0x83E604EAE0. Offset sign 0 moves the output up, sign 1 down.

Pins: ua[0] VINP, ua[1] VINN, ua[2] VOUT, ua[3] IREF (ua[4] to ua[7] not connected); ui_in[0] DIN,
ui_in[1] SCLK, ui_in[2] LATCH, ui_in[3] AMP_EN, ui_in[4] BIAS_SEL, ui_in[5] UNITY_EN; uo_out[0] DOUT.

## How to test

1. **Power and bias.** VDPWR = 3.3 V. External reference: BIAS_SEL = 0 and sink 5 µA from IREF
   (the pin sits near 2.36 V). On-chip reference: BIAS_SEL = 1 and hold IREF at a fixed voltage;
   it then sources a 5 µA monitor current. Set AMP_EN = 1.
2. **Program.** Pulse rst_n low to load the reset word. To change trims, shift 40 bits into DIN on
   rising SCLK edges (bit 39 first), then pulse LATCH. DOUT is the last stage of the chain, so
   shifting reads the word back. Wait at least 1 µs after LATCH before measuring, and stop SCLK
   while measuring.
3. **Buffer.** Set UNITY_EN = 1: VOUT drives the inverting input on chip and VINN is cut off from it,
   so VINN can stay open. Put 15 pF on VOUT and drive VINP
   at 1.65 V. Measure the offset (VOUT − VINP), a 20 mV step and a ±0.3 V step at VOUT, then repeat
   across trim codes. TT's analog switch and routing sit between the op-amp and the pins, so
   compare against a simulation that includes them.
4. **Open loop.** Set UNITY_EN = 0 and close the loop externally through VINN, for example with a
   high-impedance divider for DC gain.
5. **Supply current.** VDPWR is shared on the chip: read the difference between AMP_EN = 1 and 0.

## External hardware

A 3.3 V supply, an SMU or precision current sink for IREF, a signal source for VINP, a 15 pF load,
an oscilloscope with an active probe (1 pF or less), and a microcontroller (or the TT demo board's
RP2040) for DIN / SCLK / LATCH / rst_n and the control inputs, reading DOUT.