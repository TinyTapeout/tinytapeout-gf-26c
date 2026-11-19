## How it works

The tile measures how often a flip-flop is still unresolved a short, adjustable time after its clock edge. It holds four flip-flops under test: the GF180 library flip-flop and three custom master-latch designs. `dut_select` (ui[3], uio[6]) chooses which one is observed through a 4:1 multiplexer.

Data on ui[6] is captured asynchronously to the clock. A current-starved delay line, whose delay is set by the analog voltage on ua[0], clocks an early observer flip-flop a short time after the capture edge. When the early sample disagrees with the settled output, the flip-flop had not resolved within that time. The controller counts these events and reports the count on uo[7:0].

## How to test

Hold rst_n low, set `dut_select`, and apply a voltage to ua[0] to set the observation delay. Drive ui[6] from a source asynchronous to clk. Release reset and assert `start` (ui[4]). `busy` (uio[1]) is high during a run and `done` (uio[2]) marks the end; read the event count on uo[7:0]. Sweeping ua[0] gives the count as a function of delay, and the slope of ln(count) against delay gives the resolution time constant tau.

## External hardware

A clock source, an asynchronous data source for ui[6], an adjustable voltage on ua[0], and a logic analyzer or microcontroller to read uo[7:0] and the status pins.
