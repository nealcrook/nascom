//
module sn74ls30
  (
   output p8,

   input  p1,
   input  p2,
   input  p3,
   input  p4,
   input  p5,
   input  p6,
   input  p11,
   input  p12
   );

    assign p8 = ~(p1 & p2 & p3 & p4 & p5 & p6 & p11 & p12);

endmodule // sn74ls30
