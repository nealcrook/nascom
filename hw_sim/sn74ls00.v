//
module sn74ls00
  (
   output p3,
   output p6,
   output p8,
   output p11,

   input  p1,
   input  p2,

   input  p4,
   input  p5,

   input  p9,
   input  p10,

   input  p12,
   input  p13
   );

    // NAND
    assign #1 p3  = ~(p1 & p2);
    assign #1 p6  = ~(p4 & p5);
    assign #1 p8  = ~(p9 & p10);
    assign #1 p11 = ~(p12 & p13);

endmodule // sn74ls00
