//
module eprom2716
  (// Output
   output p17_d7,
   output p16_d6,
   output p15_d5,
   output p14_d4,
   output p13_d3,
   output p11_d2,
   output p10_d1,
   output p9_d0,
   // In
   input  p19_a10,
   input  p22_a9,
   input  p23_a8,
   input  p1_a7,
   input  p2_a6,
   input  p3_a5,
   input  p4_a4,
   input  p5_a3,
   input  p6_a2,
   input  p7_a1,
   input  p8_a0,
   //
   input  vpp,
   input  cs_n,
   input  oe_n
   );

    wire [7:0] d_i;
    // for now, just model 1 output value
    assign d_i = 8'b1001_0011;

    assign {p17_d7, p16_d6, p15_d5, p14_d4, p13_d3, p11_d2, p10_d1, p9_d0} = (!oe_n & !cs_n) ? d_i : 8'hzz;

endmodule // eprom2716

