// Octal bidirectional tri-state buffer, non-inverting
module dp8304
  (// In/Out
   inout p1, // port A
   inout p2,
   inout p3,
   inout p4,
   inout p5,
   inout p6,
   inout p7,
   inout p8,
   //
   inout p19, // port B
   inout p18,
   inout p17,
   inout p16,
   inout p15,
   inout p14,
   inout p13,
   inout p12,
   // In
   input p11_dir,
   input p9_cd // 1 => disable all outputs
   );

    wire [7:0] a_in;
    wire [7:0] b_in;

    assign a_in = {p1,  p2,  p3,  p4,  p5,  p6,  p7,  p8};  // Port A
    assign b_in = {p19, p18, p17, p16, p15, p14, p13, p12}; // Port B

    // Port B
    assign {p19, p18, p17, p16, p15, p14, p13, p12} = p9_cd ? 8'hzz : p11_dir ? a_in : 8'hzz;
    // Port A
    assign  {p1,  p2,  p3,  p4,  p5,  p6,  p7,  p8} = p9_cd ? 8'hzz : p11_dir ? 8'hzz : b_in;

endmodule // dp8304

