## How it works

A small 16-bit CPU running a subset of RV32E (4 registers, 16-bit datapath,
32-bit instructions), with an FP16 CORDIC coprocessor as custom instructions:

- `cordic.rot rd, rs1, rs2`: rd = cos(rs1), rd+1 = sin(rs1) (angle in radians, FP16)
- `cordic.vec rd, rs1, rs2`: rd = hypot(rs1, rs2), rd+1 = atan2(rs2, rs1)

The CPU's instruction and data memory are not on the chip: the RP2040 on the
demo board serves them over a byte-wide bus. Whenever the CPU needs an
instruction fetch, a load or a store, the chip freezes the CPU, does one bus
transaction, then lets it continue, so programs see zero-wait memory. When
the program executes `ebreak`, the chip reports the number of CPU cycles it
took and stops.

### Bus protocol

Each transaction is a sequence of beats. In each beat the chip sends one byte
on `uo_out` and the RP2040 answers with one byte on `ui_in`, using a 4-phase
handshake:

1. Chip (once ACK is low): puts its byte on `uo_out`, then raises REQ (`uio[0]`).
2. RP2040: reads `uo_out`, puts its answer on `ui_in`, raises ACK (`uio[1]`).
3. Chip: captures `ui_in`, drops REQ.
4. RP2040: drops ACK.

| Transaction | Chip bytes | RP2040 bytes | Meaning |
|---|---|---|---|
| FETCH | `'F'` A0 A1 0 0 0 0 | x x x I0 I1 I2 I3 | 32-bit instruction at byte address A |
| LOAD  | `'L'` A0 A1 0 0     | x x x D0 D1       | 16-bit data at byte address A |
| STORE | `'S'` A0 A1 D0 D1   | x x x x x         | write 16-bit D to byte address A |
| HALT  | `'H'` C0 C1         | x x x             | program finished after C CPU cycles |

Multi-byte values are little-endian; x = don't care. Instruction memory
(FETCH) and data memory (LOAD/STORE) are separate address spaces. HALTED
(`uio[2]`) goes high when the program has finished. Reset (`rst_n`) restarts
the program from address 0.

## How to test

On the demo board, copy `rp2040/fpucordic_mem.py`, `rp2040/fpucordic_tt.py`
and `test/vectors.csv` to the RP2040 filesystem, then at the MicroPython REPL:

```
import fpucordic_tt
fpucordic_tt.run()
```

It runs a smoke test and 79 CORDIC cases (rotation and vectoring) and checks
the results and cycle counts bit-for-bit against the RTL simulation. It ends
with `PASS: 80/80 programs bit-identical to RTL sim`.

To run your own program, use `MemProtocol` from `fpucordic_mem.py`: load the
instruction words, reset the chip, answer bus beats until HALT, then read
the data memory.

## External hardware

None. Only the RP2040 on the Tiny Tapeout demo board is used.
