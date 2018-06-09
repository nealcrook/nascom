// quad 2-input MUX
`celldefine
module sn74ls157
  (
   output p4_o1,
   output p7_o2,
   output p9_o3,
   output p12_o4,


   input  p2_a1,
   input  p3_b1,
   input  p5_a2,
   input  p6_b2,
   input  p11_a3,
   input  p10_b3,
   input  p14_a4,
   input  p13_b4,
   input  p1_sel,
   input  p15_enable_n
   );

    // TODO these 1/2/3/4 don't match the data sheet order!!
    assign {p9_o3, p12_o4, p7_o2, p4_o1} = (p15_enable_n == 1'b1) ? 4'b0 : p1_sel ? {p10_b3, p13_b4, p6_b2, p3_b1} : {p11_a3, p14_a4, p5_a2, p2_a1};

endmodule // sn74ls157
`endcelldefine
