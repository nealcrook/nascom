// triple 3-input NAND
module sn74ls10
  (// Out
   output p8_co,
   output p6_bo,
   output p12_ao,
   // In
   input p9_ci1,
   input p10_ci2,
   input p11_ci3,
   //
   input p3_bi1,
   input p4_bi2,
   input p5_bi3,
   //
   input p1_ai1,
   input p2_ai2,
   input p13_ai3
   );

    assign p8_co =  !(p9_ci1 & p10_ci2 & p11_ci3);
    assign p6_bo =  !(p3_bi1 &  p4_bi2 &  p5_bi3);
    assign p12_ao = !(p1_ai1 &  p2_ai2 & p13_ai3);

endmodule // sn74ls10
