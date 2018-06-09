//
module sn74ls20
  (
   output p6,
   output p8,

   input  p1,
   input  p2,
   input  p4,
   input  p5,

   input  p9,
   input  p10,
   input  p12,
   input  p13
   );

    // 4-in NAND
    assign p6 = ~(p1 & p2 & p4 & p5);
    assign p8 = ~(p9 & p10 & p12 & p13);

endmodule // sn74ls20
