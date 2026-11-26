## How it works

This tile measures how quickly four GF180 flip-flops recover from
metastability: their time constant τ. It uses the on-chip early/late method of
Beer et al. (ISCAS 2011).

One capture edge clocks the same asynchronous data into all four flip-flops
under test:

| DUT | Flip-flop |
| --- | --- |
| 1 | library `dffq_1` |
| 2 | NAND flip-flop, baseline sizing |
| 3 | NAND flip-flop, keeper doubled |
| 4 | NAND flip-flop, forward gate doubled |

A bank of three more flip-flops, two of them faster designs, was added in
December 2026 and is read by the same controller. It is described under "Bank of faster flip-flops" below.

A 4:1 selector picks one output. An early observer samples it a short delay
*d* after capture, and the controller samples it again at 50 ns and 100 ns,
when it has certainly settled. When the early sample disagrees with the late
one, the flip-flop was still undecided at *d*, and that trial counts as an
event.

Each 200 ns trial has five steps. All but the early sample are timed by the
20 MHz clock:

| Time | Step |
| --- | --- |
| 0 ns | capture |
| *d* (about 1.3 to 4.5 ns, set by `ua[0]`) | early sample |
| 50 ns | first late sample |
| 100 ns | second late sample |
| 150 ns | count |

A block is 65,535 trials, about 13.1 ms. The 16-bit result K is the number of
trials whose early sample disagreed with the second late sample. `fault` is set
if the two late samples ever disagreed, which means the reference itself had
not settled.

The fraction of trials still undecided at *d* falls as e^(−d/τ), so the slope
of ln(K) against *d* is −1/τ. The analog voltage on `ua[0]` sets *d*.

Every electrical number on this page comes from circuit simulation of the
extracted layout, at the typical corner, 3.3 V and 27 °C unless stated
otherwise; no chip has been measured. The layout was extracted with two
versions of Magic: 8.3.703, used for the sign-off run in `verification/layout/`,
and 8.3.573, used for the second check in `verification/independent/`. They
extract different capacitance from the wires to ground, and which of the two
is nearer the silicon is not known, so each number names its extraction.

| `ua[0]` | 1.0 V | 1.1 V | 1.2 V | 1.3 V | 1.4 V | 1.5 V | 1.8 V | 2.4 V | 3.0 V | 3.3 V |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| *d*, Magic 8.3.703 | 4.19 ns | 3.36 ns | 2.84 ns | 2.49 ns | 2.24 ns | 2.06 ns | 1.72 ns | 1.44 ns | 1.34 ns | 1.31 ns |
| *d*, Magic 8.3.573 | 4.54 ns | 3.63 ns | 3.07 ns | 2.69 ns | 2.42 ns | 2.21 ns | 1.84 ns | 1.54 ns | 1.43 ns | 1.40 ns |

The useful settings are the low ones. After a capture, the flip-flop's new
value needs 1.7 to 2.4 ns to reach the early observer, depending on the
flip-flop and on which way its output changes (8.3.703), and the observer
needs it some time before its own clock. Below a floor of *d* the early sample
still reads the old value, and K then counts every trial in which the output
changed. The floors in continuous operation (8.3.573, 25 °C):

| Flip-flop | Floor, rising data | Floor, falling data |
| --- | --- | --- |
| DUT1 | 2.35 ns | 2.73 ns |
| DUT2 | 1.69 ns | 2.25 ns |
| DUT3 | 1.83 ns | 2.45 ns |
| DUT4 | 1.77 ns | 2.39 ns |

Above its floor K falls with *d*, slowly at first. For DUT2 the straight part
of ln(K) was computed before the bank was added, when the falling-data floor
was 2.38 ns: it begins near *d* = 3.4 ns (`ua[0]` near 1.14 V), about 1 ns
above that floor, and its slope is that of the selected output:
130 ps over 3.4 to 4.0 ns and 137 ps over 4.4 to 5.4 ns, 0.91 to 0.96 of the
latch's τ (8.3.573). The other three flip-flops were not computed this way.

*d* also moves with process, supply and temperature: at `ua[0]` = 1.3 V it is
1.5 ns at the fast corner (3.6 V, −40 °C) and 4.5 ns at the slow one (3.0 V,
125 °C) with 8.3.703, and 1.6 ns and 4.8 ns with 8.3.573. Calibrate it on the
chip with the monitor pins described below.

τ of the master latch of the three NAND flip-flops:

| Extraction | DUT2 | DUT3 | DUT4 | DUT3 / DUT2 | DUT4 / DUT2 |
| --- | --- | --- | --- | --- | --- |
| Magic 8.3.703 | 136.1 ps | 113.8 ps | 163.1 ps | 0.836 | 1.199 |
| Magic 8.3.573 | 142.6 ps | 119.2 ps | 169.2 ps | 0.836 | 1.187 |

τ of DUT1, the library flip-flop, was not computed on the extracted layout.

## How to test

1. Supply the 20 MHz clock. Hold `rst_n` low for at least two rising clock
   edges, then release it.
2. Choose a flip-flop with `{uio[6], ui[3]}`: 00 = DUT1, 01 = DUT2, 10 = DUT3,
   11 = DUT4.
3. Set the delay with a voltage on `ua[0]`.
4. Drive `ui[6]` (`data_in`) with a free-running square wave that is not
   derived from the 20 MHz clock, so its edges land at random times relative
   to capture.
5. Raise `ui[4]` (`start`) and hold it high. `busy` (`uio[1]`) goes high about
   200 to 400 ns later.
6. Wait for `done` (`uio[2]`), about 13.1 ms later.
7. Read K: with `ui[0]` (`byte_sel`) low, `uo[7:0]` is the low byte; with it
   high, the high byte. Discard the block if `fault` (`uio[3]`) is high.
8. Lower `start`. This clears K, `done` and `fault` for the next block.

Before measuring, check the tile without the square wave. With `data_in` held
constant, every block gives K = 0. With `data_in` changed once per trial, far
from the capture edge (for example toggled at each falling edge of `uio[4]`),
every trial changes the flip-flop's output: with `ua[0]` at 2.5 V the early
sample comes too soon to see the change and K = 65,535; at 1.0 V it sees every
change and K = 0. Stepping `ua[0]` down between the two shows the floors: K
falls to about 32,767 where *d* passes the rising-data floor and to 0 where it
passes the falling-data floor. These limit the measurement from below. The
predicted voltages (8.3.573, typical corner, 25 °C) move with process, supply
and temperature:

| Flip-flop | K falls to about 32,767 at | K falls to 0 at |
| --- | --- | --- |
| DUT1 | 1.43 V | 1.28 V |
| DUT2 | 2.01 V | 1.47 V |
| DUT3 | 1.82 V | 1.38 V |
| DUT4 | 1.89 V | 1.41 V |

Then measure with the square wave on `data_in`, for several `ua[0]` values
and each flip-flop, and fit ln(K) against *d*. Use only settings in the
straight part, which begins about 1 ns above the falling-data floor (DUT2: *d*
above about 3.4 ns, `ua[0]` below about 1.14 V, 8.3.573). There a block holds
about one event or fewer: for DUT2 the simulation gives 0.33 events per block
for each MHz of data frequency at *d* = 3.5 ns and 0.0072 at 4.0 ns (8.3.573).
Sum K over many blocks at each setting (100 events give about 10 % on that
point) and fit the sums. The four flip-flops share one delay line, so ratios
of τ do not depend on the delay calibration.

`uio[4]` and `uio[5]` carry buffered copies of the capture clock and the early
sample clock. They can be used to measure *d* on an oscilloscope. In simulation
the delay between the two pins is shorter than *d* by 0.074 ns at `ua[0]` =
1.0 V and by 0.11 to 0.12 ns at 1.8 V and above (both extractions). A τ fitted
against the pin delay therefore comes out 0.9 to 1.7 % long, depending on the
range of settings and the extraction. Ratios of τ are not affected.

## Bank of faster flip-flops (added 25 November 2026)

The tile holds a second set of flip-flops under test, the bank, read by the
same controller and counter as the four above:

| Bank input | Flip-flop | τ typical | τ slow | τ fast |
| --- | --- | --- | --- | --- |
| N1 | NAND flip-flop of 3.3 V library cells (`gf180mcu_as_sc_mcu7t3v3`), forward and keeper gates of strength 4 | 41.5 ps | 65.6 ps | 29.3 ps |
| N2 | jamb-latch flip-flop drawn from 3.3 V transistors | 29.6 ps | 48.1 ps | 20.3 ps |
| N3 | copy of DUT3 | 119.4 ps | 227.0 ps | 72.3 ps |

τ is that of the master latch, simulated on the extracted layout (8.3.573):
typical corner at 3.3 V and 27 °C, slow corner at 3.0 V and 125 °C, fast
corner at 3.6 V and −40 °C.

The bank has its own data input (`uio[0]`), its own capture edge, made from
the 20 MHz clock once per 200 ns trial, and its own early observer. That
observer is clocked from the pin `ui[5]`, not by the on-chip delay line, so the
bench sets the delay of the early sample. With τ of 30 to 40 ps the delay has
to move in steps of about 15 ps of known size, which the clock manager of an
FPGA provides and the voltage-controlled line does not.

`ui[7]` (`bank_enable`) chooses what the controller reads. Low: the selected
output and early sample of DUT1 to DUT4, and everything above applies
unchanged. High: those of the bank. `{ui[2], ui[1]}` selects the bank input:
00 = N1, 01 = N2, 10 = N3, 11 = a constant 0.

To measure a bank flip-flop:

1. Supply the 20 MHz clock and hold `rst_n` low for at least two rising clock
   edges, so that the bank's trial counter starts in step with the
   controller's.
2. Raise `ui[7]` and choose the flip-flop with `{ui[2], ui[1]}`.
3. Drive `uio[0]` (`bank_data_in`) with a free-running square wave that is not
   derived from the 20 MHz clock.
4. Drive `ui[5]` (`bank_early_clock`) with one rising edge per trial: a 5 MHz
   square wave locked to the 20 MHz clock, whose rising edge follows the
   clock edge that makes the capture edge (the one after which `uio[4]` rises)
   by an adjustable delay *t*.
5. Raise `start`, wait for `done` and read K as in steps 5 to 8 above.
6. Repeat for several values of *t* and fit ln(K) against *t*. The slope is
   −1/τ. Only differences of *t* enter the fit, so the delays of the pads and
   of the board need not be known.

Simulated timing of the bank path (8.3.573, typical corner; in brackets the
fast and the slow corner, from the runs with N2):

| Quantity | Value |
| --- | --- |
| Clock pin to the bank's capture edge at the flip-flops | 1.77 ns (1.05 ns, 3.40 ns) |
| `ui[5]` pin to the clock of the early observer | 0.27 ns (0.17 ns, 0.49 ns) |
| Capture edge to new value at the early observer, N1 | 1.22 ns rising, 1.38 ns falling |
| Capture edge to new value at the early observer, N2 | 1.63 ns rising, 2.24 ns falling (1.02 and 1.42 ns, 3.02 and 4.12 ns) |
| Capture edge to new value at the early observer, N3 | 1.66 ns rising, 1.96 ns falling |

The bank's capture edge comes 0.30 ns before the capture edge of DUT1 to DUT4. An early sample taken before the new value arrives reads the old
one, and K then counts every trial in which the output changed; so K starts
to fall when the `ui[5]` edge is about 2.7 to 3.7 ns after the clock edge at the typical corner, and the straight part of ln(K) lies above that.
One step of 15 ps is half of τ for N2, so the fall from full count to less
than one event per block takes some tens of steps.

**Capture driver of the bank, changed on 26 Nov 2026.** On the layout of 25
Nov the bank's capture edge reached N1, N2 and N3 with a rise time of about 1
ns. The slave of N2 is opened by this edge, and most of the lateness of its
latch was hidden behind it: the simulated count of N2 fell with a local time
constant of 7 to 14 ps, not with the 29.6 ps of the latch. The two inverters
that drive the edge were therefore replaced by stronger ones. The edge now
rises in 0.29 ns, and in the same simulation the last output crossing of N2
follows a time constant of 24 to 29 ps; the predicted count falls with 28.7
ps. Nothing above the bank was changed, and τ of all six latches is the same
as before. Details: `verification/bank_driver/README.md` in the repository.

Check the bank before measuring. With bank input 11 every block gives K = 0.
With `uio[0]` changed once per trial, far from the capture edge, a `ui[5]`
edge 0.2 ns after the clock edge gives K = 65,535 and one 6 ns after it gives
K = 0 (simulated for N2: 4 events in 4 counted trials, and 0 in 4). N3
is the same circuit as DUT3 measured through the bank's path: the two values
of τ from one chip should agree, which tests the new path and its delay
steps against the delay line.

What the bank changes for DUT1 to DUT4, from the extraction of the revised
layout (8.3.573): the controller now takes the selected output and the early
sample through two 2:1 multiplexers, so the net of the selected output is
shorter (7.1 fF of wire in place of 10.6 fF) and the new value reaches the
early observer about 0.1 ns sooner. The floors in the tables above are those
of the revised layout. τ of DUT2, DUT3 and DUT4 is unchanged to 0.001 ps, and
*d* is 1.7 to 1.9 ps longer at every setting. The row of *d* for Magic 8.3.703,
the arrival times of 1.7 to 2.4 ns, the start of the straight part near
3.4 ns and the events per block at 3.5 and 4.0 ns were computed before the
bank was added and were not repeated; the last three are expected to move
down in *d* by about 0.1 ns with the floors.

## Supply current and physical checks

Simulated on the extracted layout at the typical corner, the tile draws about
47 µA from the 3.3 V supply while it counts (53 µA with the bank selected),
about 20 µA in reset with the clock running, and 5 nA with the clock stopped;
the peaks at each capture edge are 1.9 to 4.5 mA. Measure the supply current
before reading any count: a value many times larger points to a fault.

In trials in which `data_in` is high at the capture edge, *d* is about 0.5 %
longer than in trials in which it is low (22 ps at `ua[0]` = 1.0 V). When *d*
is calibrated with the monitor pins, record the two cases separately. The
effect on a fitted τ is below 0.1 %.

The tile's supply is 3.3 V. N1 and N2 are built from 3.3 V transistors and
must not be run above 3.6 V.

The audit of the layout for supply voltage drop, current density, latch-up
distances and coupling, and the list of ways the tile could fail with the
check that covers each, are in the repository: `verification/physical/README.md`
and `verification/FAILURE_SPACE.md`. The audit led to no change of the supply network; `verification/bank_driver/README.md` describes the one change made on 26 Nov, to the driver of the bank's capture edge.

## External hardware

- Asynchronous square-wave source for `data_in` (`ui[6]`): a function
  generator or a crystal oscillator with its own time base, at a few MHz but
  not a multiple or simple fraction of 5 MHz, the trial rate. K is
  proportional to its frequency. A second output of the microcontroller that
  makes the 20 MHz clock will not do: its edges fall at a few fixed points
  relative to capture.
- Adjustable voltage, 0 to 3.3 V, for `ua[0]`: a 16-bit DAC on a quiet
  reference with an RC filter at the pin, or an equally quiet source. Between
  1.0 and 1.4 V, *d* changes by 2.5 to 8.3 ps per mV (8.3.703; 2.7 to 9.1 ps
  per mV with 8.3.573) against τ of 114 to 169 ps, so hold the voltage to
  about 1 mV during a run and record it with a voltmeter of five digits at the
  pin.
- Microcontroller or logic analyzer to raise `start`, wait for `done`, and read
  the two result bytes. `host/metachar_host.py` in the repository does this
  from the demo board's RP2.
- For the bank only: a source of the 20 MHz clock and of a 5 MHz clock for
  `ui[5]` locked to it, with a phase adjustable in steps of about 15 ps of
  known size, such as the clock manager of an FPGA board, and a second
  asynchronous square wave for `uio[0]`. The demo board's RP2 alone cannot
  make these steps.
- Oscilloscope on `uio[4]` and `uio[5]` to calibrate *d*: needed for τ in
  picoseconds, not for ratios of τ.
