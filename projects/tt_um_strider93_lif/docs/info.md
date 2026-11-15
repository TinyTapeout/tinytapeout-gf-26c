## How it works

This project contains one **leaky integrate-and-fire (LIF) processing element** taken from a convolutional
spiking neural network (CSNN) accelerator developed in a master thesis (TUM / Lund University).
In the full accelerator a 4x4 array of these PEs is fed by an FSM and SRAM-based input, weight and
membrane memories. On this tile only the PE is implemented; the microcontroller on the demo board takes
over the role of the FSM and memories. The PE arithmetic is bit-exact to the thesis RTL.

Per time step the PE does:

1. **accumulate** (once per input event): `acc += weight` if the input spike is 1 (8-bit two's complement accumulator, 4-bit signed weight)
2. **updateLIF**:
   - `sum = acc + leak + Vmem_in` and `sub_th = sum + thr` (16 bit, wrap-around)
   - `spike = (sub_th >= 0)`
   - `Vmem_out = spike ? sub_th : sum` (reset by subtraction)
   - the spike is shifted into a 32-bit spike vector, and the accumulator is cleared

As in the thesis, leakage and threshold are only ever *added*, so you write them **negated**
(`LEAK = -leak`, `THR = -Vth`).

### Interface

| Pin | Direction | Function |
|---|---|---|
| `ui[7:0]` | in | DATA byte to write |
| `uio[3:0]` | in | ADDR: picks the register to write and the byte to read back |
| `uio[4]` | in | WR: a rising edge writes DATA to ADDR (synchronised to `clk`, so any strobe speed works) |
| `uio[6]` | out | spike result of the last updateLIF |
| `uio[7]` | out | spike vector full |
| `uo[7:0]` | out | read-back byte for ADDR (registered: valid 1 clock after ADDR changes) |

Hold DATA/ADDR stable while WR is high. Keep WR high for at least 3 clock cycles and low for at least 3 cycles before the next write.

### Register map

| ADDR | Write | Read |
|---|---|---|
| 0x0 / 0x1 | LEAK low / high (store -leak) | LEAK |
| 0x2 / 0x3 | THR low / high (store -Vth) | THR |
| 0x4 / 0x5 | VMEM_IN low / high | VMEM_IN |
| 0x6 | ACC: `[3:0]` weight (signed), `[4]` input spike. Triggers one accumulate | accumulator |
| 0x7 | CTRL: `[0]` updateLIF pulse, `[1]` membrane_out_lower_bity_n (0 = result in Vmem bytes 0-1, 1 = bytes 2-3), `[2]` clear spike vector, `[3]` feedback enable | status `{full, last_spike, spike_now, counter[4:0]}` |
| 0x8 - 0xB | - | membrane_out bytes 0..3 |
| 0xC - 0xF | - | spike vector bytes 0..3 |

**Feedback mode** (CTRL[3] = 1): after each updateLIF, the new Vmem is copied back into VMEM_IN, so the neuron
keeps its state between time steps without the MCU reloading it. This logic sits outside the PE.

Thesis behaviour to note: write at least one ACC per time step (with spike = 0 if there is no input). An
updateLIF that follows another updateLIF without an accumulate in between does not store a new spike-vector bit,
and in upper-half mode it does not update Vmem.

## How to test

MicroPython on the demo board (names follow the tt-micropython SDK and may differ between firmware versions):

```python
from ttboard.demoboard import DemoBoard
tt = DemoBoard.get()
tt.shuttle.tt_um_strider93_lif.enable()
tt.uio_oe_pico.value = 0b0011_1111      # Pico drives uio[5:0], reads uio[7:6]
tt.clock_project_PWM(10_000_000)
tt.reset_project(True); tt.reset_project(False)

def wr(addr, data):
    tt.ui_in.value = data & 0xFF
    tt.uio_in.value = addr
    tt.uio_in.value = addr | 0x10       # WR rising edge
    tt.uio_in.value = addr

def rd(addr):
    tt.uio_in.value = addr
    return int(tt.uo_out.value)

def wr16(addr, v):
    wr(addr, v & 0xFF); wr(addr + 1, (v >> 8) & 0xFF)

wr16(0x0, -1)    # leak = 1
wr16(0x2, -10)   # Vth = 10
wr16(0x4, 0)     # Vmem = 0

for t in range(8):                       # 8 time steps
    for _ in range(3):
        wr(0x6, 0x10 | 2)                # input spike, weight +2
    wr(0x7, 0b1001)                      # updateLIF, feedback on
    vmem = rd(0x8) | (rd(0x9) << 8)
    if vmem & 0x8000: vmem -= 0x10000
    print(t, "spike", (rd(0x7) >> 6) & 1, "Vmem", vmem)
# expected: spikes at t = 1, 3, 5, 7
```

The MicroPython statements are slow compared to the 10 MHz clock, so the WR timing rules hold without extra delays.

## External hardware

None. Only the RP2040 / RP2350 on the Tiny Tapeout demo board.
