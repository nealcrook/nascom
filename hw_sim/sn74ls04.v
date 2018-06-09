//
module sn74ls04
  (
   output p6,
   output p2,
   output p4,
   output p8,

   input  p5,
   input  p1,
   input  p3,
   input  p9
   );

    // NOT
    assign p6 = ~p5;
    assign p2 = ~p1;
    assign p4 = ~p3;
    assign p8 = ~p9;

endmodule // sn74ls04
