//
module mk4118
  (// Input/Output
   inout d7,
   inout d6,
   inout d5,
   inout d4,
   inout d3,
   inout d2,
   inout d1,
   inout d0,
   // In
   input a9,
   input a8,
   input a7,
   input a6,
   input a5,
   input a4,
   input a3,
   input a2,
   input a1,
   input a0,
   //
   input ce_n,
   input we_n,
   input oe_n
   );

    wire [7:0] d_i;
    // for now, just model 1 output value
    assign d_i = 8'b0000_0000;

    assign {d7, d6, d5, d4, d3, d2, d1, d0} = (!oe_n & !oe_n) ? d_i : 8'hzz;

endmodule // mk4118



