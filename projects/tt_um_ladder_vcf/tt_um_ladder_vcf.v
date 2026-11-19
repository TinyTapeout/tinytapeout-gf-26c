/*
 * tt_um_ladder_vcf -- 4-pole MOS transistor-ladder VCF (analog, GF180MCU-D)
 * The real design is the custom layout in gds/.
 */
`default_nettype none

(* blackbox *)
module tt_um_ladder_vcf (
    input  wire       VGND,
    input  wire       VDPWR,
    input  wire [7:0] ui_in,    // ui_in[3:0] = resonance code
    output wire [7:0] uo_out,   // tied to VGND in layout
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,  // tied to VGND in layout
    output wire [7:0] uio_oe,   // tied to VGND in layout
    inout  wire [7:0] ua,       // ua[0] VIN, ua[1] OUTP, ua[2] OUTN, ua[3] IREF
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);
endmodule
