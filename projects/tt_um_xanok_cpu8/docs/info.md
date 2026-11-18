<!---
This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

cpu8 is a tiny 8-bit CPU with an accumulator, a 12-bit index register X and a stack (CALL/RET/PUSH/POP). It has no memory on chip. Every instruction and every data byte is read from (or written to) an external SPI RAM, in 23LC512 style: mode 0, READ 0x03 / WRITE 0x02, 16-bit address. Instructions are 2 bytes each. The address space is 4 KB, and the stack is its top 256 bytes.

`ui_in` is an 8-bit input port, read with `IN`. `uo_out` is an 8-bit output port, written with `OUT`. `uio[4]` goes high after a `HLT`. `uio[5]` (OUT_STROBE) toggles on every `OUT`, so the demo board's RP2040 can capture each output byte, repeated values included, and pass it to the PC as text. See [isa.md](isa.md) for the instruction set.

`uio[6]` (MISO_RISE) is an input strap that selects when the CPU samples MISO. Tie it low or high; don't leave it floating, and don't change it while the CPU runs.

- **0:** at the end of the SCK high phase. Use this with a RAM that changes MISO after the falling SCK edge: a real 23LC512, or the modified spi-ram-emu in `rp2040/`.
- **1:** at the SCK rising edge, like a standard SPI mode-0 master. Use this with the stock spi-ram-emu, which changes MISO right after the rising edge.

Reset starts as soon as `rst_n` goes low and needs no clock: the SPI pins go to their idle state (CS high, SCK low), `uo_out` to 0. Its release is synchronised inside the chip, so `rst_n` can go high at any time; the CPU starts 2 clocks later.

## How to test

1. Put the firmware from this repository's `rp2040/` folder on the demo board's microcontroller (it builds for the RP2350B board and for the older RP2040 board). It emulates the SPI RAM (a modified copy of [spi-ram-emu](https://github.com/MichaelBell/spi-ram-emu)) on uio[0] CS#, uio[1] MOSI, uio[2] MISO and uio[3] SCK, and drives the MISO_RISE strap on uio[6]. The unmodified spi-ram-emu does not fit this pin order.
2. Assemble a program (`tools/cpu8asm -o prog.bin prog.asm`) and run `tools/cpu8load -p <project address> -a prog.bin`. It holds the design in reset, copies the program into the emulated RAM at address 0, sets the clock to 10 MHz (SCK = 5 MHz, well under the emulator's 12.5 MHz READ limit) and releases reset.
3. The program's `OUT` bytes are printed as text. `uo_out` also shows on the 7-segment display, and the HALTED pin goes high at `HLT`.

## External hardware

None beyond the demo board: its microcontroller emulates the SPI RAM. A real 23LC512 (16-bit address) in sequential mode should also work, with MISO_RISE tied low; this is untested.
