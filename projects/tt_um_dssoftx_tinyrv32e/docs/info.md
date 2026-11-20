<!---
This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

tinyrv32e is a small multi-cycle RISC-V CPU implementing the RV32E base
integer instruction set (16 registers, no multiply/divide, no CSRs). It runs
code straight out of an SPI flash and keeps data, the stack and the heap in an
SPI PSRAM. Both chips sit on a Tiny Tapeout QSPI Pmod, used in plain
single-lane SPI mode (commands `0x03` read and `0x02` write, 24-bit address).

Every instruction goes through FETCH → RS1 → RS2 → EXEC, plus MEM for loads and
stores and one cycle per bit for shifts. The design is completely memory-bound.
A fetch that starts a new flash read (command + address + data) takes ~130
clocks. After a fetch the flash chip select stays low, so the next sequential
instruction only needs its 32 data bits (~64 clocks). Straight-line ALU code runs
at 69 clocks per instruction and typical C code averages ~118 (roughly 210k
instructions per second at 25 MHz). Taken branches, jumps and data accesses
end the stream.

Memory map:

| Address                     | What                                 |
|-----------------------------|--------------------------------------|
| `0x0000_0000`–`0x00FF_FFFF` | SPI flash, read-only, reset vector 0 |
| `0x0100_0000`–`0x01FF_FFFF` | SPI PSRAM, read/write                |
| `0x8000_0000`               | GPIO out → `uo_out[7:0]`             |
| `0x8000_0004`               | GPIO in ← `ui_in[7:0]` (read-only)   |

Implementation-defined behaviour: FENCE, ECALL, EBREAK, CSR and unknown
instructions are no-ops; there are no interrupts or traps; misaligned loads and
stores work; jump targets are truncated to a 4-byte boundary; writes to flash
are ignored. The register file is not reset, so startup code must clear it (the
provided `crt0.S` does).

While `rst_n` is low all `uio` pins are inputs, so another SPI master on the
same bus can program the flash without unplugging anything.

## How to test

1. Build a program with the toolchain in `sw/` (needs `riscv64-unknown-elf-gcc`):
   `riscv64-unknown-elf-gcc -march=rv32e -mabi=ilp32e -nostdlib -T sw/link.ld sw/crt0.S sw/examples/blink.c -lgcc -o blink.elf`
   then `riscv64-unknown-elf-objcopy -O binary blink.elf blink.bin`.
2. Write `blink.bin` to offset 0 of the flash on the QSPI Pmod (while the
   design is held in reset or not selected).
3. Plug the Pmod into the bidirectional header, select the design, set the clock
   to 25 MHz and release reset. The first ~8200 clocks after reset are the
   PSRAM power-up wait and reset sequence; the CPU starts after that.
4. The blink example runs a scanner across `uo_out`; `ui_in` sets the speed.

## External hardware

Tiny Tapeout QSPI Pmod (SPI flash on CS0 / `uio[0]`, PSRAM on CS1 / `uio[6]`)
in the bidirectional Pmod header. The second PSRAM (CS2 / `uio[7]`) is not
used, but receives the same power-up reset as the first.

The flash chip select stays low between sequential instruction fetches; this is
fine for SPI NOR flash. Keep the clock at 20 MHz or above when using the PSRAM: a 4-byte access holds
its chip select low for 128 clocks, and APS6404-style PSRAMs limit chip-select
low time to a few microseconds for their internal refresh (check the datasheet
of the part on your Pmod).
