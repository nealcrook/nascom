//
module prom_n2v
  (
   output d7,
   output d6,
   output d5,
   output d4,
   output d3,
   output d2,
   output d1,
   output d0,

   input ce_n,
   input a4,
   input a3,
   input a2,
   input a1,
   input a0
   );

    reg [7:0] d_i;
    wire [4:0] a;

    assign {d7, d6, d5, d4, d3, d2, d1, d0} = ce_n ? 8'bzz : d_i;
    assign a = {a4, a3, a2, a1, a0};

    always @(a) begin
        case (a)
          // high 6 bits unused. Wot a waste!
          // read off the listing in the NASCOM 2 hardware manual
          //
          //                  +--- /vblank
          //                  |+-- /ld pulse to line counter
          //                  ||
          0:  d_i = 8'b0000_0001; // /vblank continues
          1:  d_i = 8'b0000_0000; // /ld pulse to IC68 reloads it to 1011
          2:  d_i = 8'b0000_0011; // skip
          3:  d_i = 8'b0000_0011; // .

          4:  d_i = 8'b0000_0011; // .
          5:  d_i = 8'b0000_0011; // .
          6:  d_i = 8'b0000_0011; // .
          7:  d_i = 8'b0000_0011; // .

          8:  d_i = 8'b0000_0011; // .
          9:  d_i = 8'b0000_0011; // .
          10: d_i = 8'b0000_0011; // .
          11: d_i = 8'b0000_0001; // skip to here.. more /vblank

          12: d_i = 8'b0000_0001; // /vblank
          13: d_i = 8'b0000_0001; // /vblank
          14: d_i = 8'b0000_0001; // /vblank
          15: d_i = 8'b0000_0011; // VDU line 15 (top line)

          16: d_i = 8'b0000_0011; // VDU line 0
          17: d_i = 8'b0000_0011; // VDU line 1
          18: d_i = 8'b0000_0011; // VDU line 2
          19: d_i = 8'b0000_0011; // VDU line 3

          20: d_i = 8'b0000_0011; // VDU line 4
          21: d_i = 8'b0000_0011; // VDU line 5
          22: d_i = 8'b0000_0011; // VDU line 6
          23: d_i = 8'b0000_0011; // VDU line 7

          24: d_i = 8'b0000_0011; // VDU line 8
          25: d_i = 8'b0000_0011; // VDU line 9
          26: d_i = 8'b0000_0011; // VDU line 10
          27: d_i = 8'b0000_0011; // VDU line 11

          28: d_i = 8'b0000_0011; // VDU line 12
          29: d_i = 8'b0000_0011; // VDU line 13
          30: d_i = 8'b0000_0011; // VDU line 14 (bottom line)
          31: d_i = 8'b0000_0001; // start of /vblank

          default: d_i = 8'bxxxx_xxxx;
        endcase // case (d_i)
    end // always @ (a)
endmodule // prom_n2v
