## How it works
A 4-pole resonant low pass filter (Moog transistor ladder). Moog used bipolar transistors; this version uses the 3.3 V NMOS devices from GF180MCU biased below threshold (weak inversion). In weak inversion the drain current is exponential in V_GS (same as I_C vs V_BE in a BJT), so the ladder works that way too. IREF sets cutoff (roughly 18 Hz to 48 kHz); `ui_in[3:0]` sets resonance.

### Ladder
Two columns of NMOS five transistors high on tail current I_f. The bottom pair is. the input, VIN against vcm. The four pairs above it have their gates tied to fixed bias voltages (g1 to g4) and there’s a capacitor across each pair’s two nodes.

Signal goes up the ladder through the sources. In weak inversion the source impedance is n · U_T/I so each pair plus its capacitor is one RC pole with R set by current. Each column carries I_f/2. Four poles:

```
f_pole ≈ I_f / (8π · n · U_T · C)        f(−3 dB) ≈ 0.435 · f_pole
```
Cutoff follows I_f and nothing else so 2x current is +1 octave. From extracted. layout, 27 °C, resonance off:

| IREF | 2.5 nA | 25 nA | 250 nA | 1.25 µA | 10 µA |
|---|---|---|---|---|---|
| Cutoff | 18 Hz | 170 Hz | 1.6 kHz | 7.2 kHz | 48 kHz |

### Current mirrors
IREF goes through a mirror tree (L = 4 µm devices) which divides it into u = IREF/128. The tail of the ladder is 4u (i.e. I_f = IREF/32). The resonance DAC bits are 4u, 8u, 16u, 32u. With the ÷32 pin current is within a range you can actually set from outside and. the ladder runs tens to hundreds of nA.

### Bias string
The gate voltages are from a poly resistor string fed by about 2.2 µA:

```
g4 ─3R─ g3 ─3R─ g2 ─3R─ g1 ─3R─ vcm ─11R─ GND (vcm ≈ 1.2 V, steps ≈ 0.33 V)
```
0.33 V per rung is enough to saturate each one, vcm also decides how much voltage the tail mirror gets. Design has two resistor units under vcm (1.2 V) and the sweep is clean.

### Capacitors
Each pole has PMOS gate caps (W 14 µm,. L 20 µm) from ladder nodes to VDPWR about 3.4 pF/pole. The nodes are 1.3–2 V below VDPWR so the caps are in strong inversion and their value doesn’t change with signal. Each is split in two and placed P N N P.

### Resonance
A PMOS diff pair (8+8 fingers) senses pole 4 and injects into pole 1 inverted. Four poles give 180° at f_pole inversion gives another 180° so it's positive feedback at f_pole tail of the pair comes from DAC on `ui_in[3:0]`:
```
Ik = code · I_f
```
Loop gain is about code. An ideal ladder oscillates at 4. This one starts. around 7 (6-9 over process, temp and supply) because stages are not lossless. Once it oscillates you get a sine of about 50 mV pp differential; the tanh of the feedback pair limits the amplitude.

Ik is derived from I_f so resonance per code is the same at any cutoff. The feedback pair pulls Ik out of pole 1 and the same code adds Ik to tail of input so ladder current stays at I_f and cutoff doesn’t move when you change resonance.

Input / output
VIN first passes a small CDM clamp at the pad (about 2.2 kΩ of poly and a diode to each rail), then is biased to vcm through 20 resistor units (1.4 MΩ), so just AC-couple into it. Use 10–40 mV peak. THD at 10 mV is 0.5 % and at 40 mV 2.3 %; above that soft-clips.

Each pole-4 node drives a PMOS source follower (about 17 µA each in its own n-well with body tied to source). Outputs sit at VDPWR − 0.85 V = about 2.4 V Take OUTP − OUTN. Gain from VIN to differential output is about −6 dB.

## How to test

Note that VDPWR is 3.3 V for GF180MCUD. Either use the testboard or use lab instruments to setup the pins as follows -

| Pin | Use |
|---|---|
| `ua[0]` VIN | audio in, AC-coupled (1 µF or more), 10–40 mV peak |
| `ua[1]` OUTP, `ua[2]` OUTN | differential out, ~2.4 V DC |
| `ua[3]` IREF | sink 2.5 nA – 10 µA into it; pin is at ~0.6 V |
| `ui_in[3:0]` | resonance, 0–15 |

1. Power VDPWR = 3.3 V.
2. Sink a current into **ua[3] (IREF)**. A resistor to 3.3 V works (≈ 2.7 V / I).
   With `ui_in[3:0] = 0`, f₋₃dB ≈ 5 kHz per µA of IREF (18 Hz at 2.5 nA to 48 kHz at 10 µA); see the README for the
   full curve.
3. AC-couple an audio signal (≥ 1 µF, ~10–40 mV peak) into **ua[0] (VIN)**. An
   on-chip ≈1.4 MΩ resistor biases it.
4. Take the output differentially between **ua[1] (OUTP)** and **ua[2] (OUTN)**
   (both ≈2.45 V DC), for example with an instrumentation amplifier, or
   AC-coupled from ua[1] alone.
5. Step `ui_in[3:0]` from 0 up to about 5 for increasing resonance. From about
   7 up it self-oscillates.

## External hardware
3.3 V supply (TT demo board), audio source, resistor or current source for IREF, scope,. switches on `ui_in[3:0]`.

There's also a test board. It plugs into the demo board analog. header with ribbon cable; on it is an input jack with ÷101 divider, 1 V/oct exponential IREF source and linear one (3 ranges), INA333 which turns OUTP − OUTN. into normal audio output.

