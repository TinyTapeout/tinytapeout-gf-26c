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

A 4:1 selector picks one output. An early observer samples it a short delay
*d* after capture, and the controller samples it again at 50 ns and 100 ns,
when it has certainly settled. When the early sample disagrees with the late
one, the flip-flop was still undecided at *d*, and that trial counts as an
event.

Each 200 ns trial has four steps, all driven by the 20 MHz clock:

| Time | Step |
| --- | --- |
| 0 ns | capture |
| *d* (1.3 to 4.2 ns) | early sample |
| 50 ns | first late sample |
| 100 ns | second late sample |
| 150 ns | count |

A block is 65,535 trials, about 13.1 ms. The 16-bit result K is the number of
trials whose early sample disagreed with the second late sample. `fault` is set
if the two late samples ever disagreed, which means the reference itself had
not settled.

The fraction of trials still undecided at *d* falls as e^(−d/τ), so the slope
of ln(K) against *d* is −1/τ. The analog voltage on `ua[0]` sets *d*
(simulated on the extracted layout, typical corner, 3.3 V, 27 °C):

| `ua[0]` | 1.0 V | 1.1 V | 1.2 V | 1.3 V | 1.4 V | 1.5 V | 1.8 V | 2.4 V | 3.0 V | 3.3 V |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| *d* | 4.19 ns | 3.36 ns | 2.84 ns | 2.49 ns | 2.24 ns | 2.06 ns | 1.72 ns | 1.44 ns | 1.34 ns | 1.31 ns |

The useful settings are the low ones. In the same simulation the flip-flop's
new value needs 1.7 to 2.4 ns to reach the early observer, depending on the
flip-flop and on which way its output changes, and the observer needs it some
time before its own clock: half a nanosecond was enough at this corner. A
sample taken earlier reads the old value, and K then counts every trial in
which the data changed. Beyond that, K falls with *d* as described.

*d* also moves with process, supply and temperature: at `ua[0]` = 1.3 V it is
1.5 ns at the fast corner (3.6 V, −40 °C) and 4.5 ns at the slow one (3.0 V,
125 °C). Calibrate it on the chip with the monitor pins described below.

The same simulation gives τ of 136 ps for DUT2, 114 ps for DUT3 and 163 ps for
DUT4 at the typical corner.

## How to test

1. Supply the 20 MHz clock. Hold `rst_n` low, then release it.
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

Repeat for several `ua[0]` values and each flip-flop, then fit ln(K) against
*d*. The four flip-flops share one delay line, so ratios of τ do not depend on
the delay calibration.

`uio[4]` and `uio[5]` carry buffered copies of the capture clock and the early
sample clock. They can be used to measure *d* on an oscilloscope. In simulation
the delay between the two pins is about 0.1 ns shorter than *d*.

## External hardware

- Asynchronous square-wave source for `data_in` (`ui[6]`): a function
  generator or a second oscillator.
- Adjustable voltage, 1.0 V to 3.3 V, for `ua[0]`: a bench supply or a DAC.
  In the useful range, below about 1.4 V, *d* changes by 2.5 to 8 ns per
  volt, so steps of a few millivolts are needed.
- Microcontroller or logic analyzer to raise `start`, wait for `done`, and read
  the two result bytes.
- Optional: oscilloscope on `uio[4]` and `uio[5]` to calibrate *d*.
