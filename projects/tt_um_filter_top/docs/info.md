<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This chip implements an adaptive filter targeting interference cancellation and system identification applications. It includes a 4-tap FIR filter, on-chip error computation, and a coefficient update engine based on the sign-sign LMS algorithm.

The input and reference signals are received as two simultaneous lanes of 8-bit serial streams in the input serial-clock domain. Once a complete input frame has been received, the samples are held and a toggle-based CDC mechanism transfers the frames to the system-clock domain.

For each accepted sample, the core executes:
IDLE: waits for a new input sample
MAC (17 cycles) : computes the four-tap response via radix-4 booth partial product and Horner accumulation
FIN (1 cycle) : Computes the error e = r - y
UPD (4 cycles) : Updates the four coefficients using sign-sign LMS algorithm when adaptation enabled.

The filtered output, error, and one weight are captured into 8-bit transmit registers and serialized through three parallel serial data lanes. The monitored coefficient rotates across the four taps on successive frames. The output serializer generates its serial clock and frame-sync signal from the system clock.

Further architectural details may be found under spi_arch.pdf and core_arch.pdf.

## Design Specifications

| Specification                  | Value       |
| :----------------------------- | :---------- |
| Number of FIR taps             | 4           |
| Input precision (Q1.7)         | 8 bits      |
| Output precision (Q1.7)        | 8 bits      |
| Error precision (Q1.7)         | 8 bits      |
| Weight readout (Q2.6)          | 8 bits      |
| Internal weight precision (Q2.12) | 14 bits  |
| Input signal frequency         | 833.33 kHz  |
| System clock frequency         | 40 MHz      |
| Serial clock frequency         | 20 MHz      |

## Pin Mappings

### Input Pins

| Pin        | Signal      | Description       |
| :--------- | :---------- | :---------------- |
| `ui_in[0]` | `SCLK_IN`   | Serial clock in   |
| `ui_in[1]` | `CS_IN`     | Chip select       |
| `ui_in[2]` | `MOSI_u_in` | Input signal      |
| `ui_in[3]` | `MOSI_r_in` | Reference signal  |

### Output Pins

| Pin         | Signal       | Description         |
| :---------- | :----------- | :------------------ |
| `uo_out[0]` | `SCLK_OUT`   | Serial clock out    |
| `uo_out[1]` | `FS_OUT`     | Frame synchronization |
| `uo_out[2]` | `MOSI_y_out` | Filter output       |
| `uo_out[3]` | `MOSI_e_out` | Error signal        |
| `uo_out[4]` | `MOSI_w_out` | Weight readout      |
| `uo_out[5]` | `debug_o1`   | Dropped sample flag |
| `uo_out[6]` | `debug_o2`   | Saturation flag     |

### Bidirectional Pins (Configured as Inputs)

| Pin           | Signal     | Description                    |
| :------------ | :--------- | :----------------------------- |
| `uio_in[0]`   | `adapt_en` | Enable coefficient adaptation  |
| `uio_in[3:1]` | `mu_sel`   | Learning rate selection        |

The learning rate is configured as:

$$
\mu = 2^{(\text{mu\_sel}-12)}
$$

## How to test

TODO

## External hardware

None used.
