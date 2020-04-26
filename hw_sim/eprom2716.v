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

    initial $display("%m not yet modelled!!");
endmodule // eprom2716

