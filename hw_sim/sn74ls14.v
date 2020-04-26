// hex schmitt inverter
// schmitt function not modelled.
module sn74ls14
  (
   output p2,
   output p4,
   output p6,
   output p8,
   output p10,
   output p12,

   input  p1,
   input  p3,
   input  p5,
   input  p9,
   input  p11,
   input  p13
   );

    // NOT
    assign p2 = ~p1;
    assign p4 = ~p3;
    assign p6 = ~p5;
    assign p8 = ~p9;
    assign p10 = ~p11;
    assign p12 = ~p13;

endmodule // sn74ls14
