//
module mcm6576
  (
   output p17,
   output p7,
   output p18,
   output p6,
   output p19,
   output p5,
   output p20,

   input  p4,
   input  p8,
   input  p9,
   input  p11,
   input  p12,
   input  p14,
   input  p15,

   input  p24,
   input  p23,
   input  p22,
   input  p21
   );

    wire [6:0] d;
    wire [3:0] rs;

    assign rs = {p24, p23, p22, p21};
    assign {p17, p7, p18, p6, p19, p5, p20} = d[6:0];

    // TODO temporary
    assign d = 7'b1010101;


endmodule // mcm6576

