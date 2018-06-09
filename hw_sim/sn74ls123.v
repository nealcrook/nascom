`timescale 1ns/1ps
`celldefine
// dual retriggerable one-shot
module sn74ls123
  #( parameter dly1 = 10000, dly2 = 10000)

  (
   output p4,
   output p5,
   output p12,
   output p13,

   input  p1,
   input  p2,
   input  p3,
   input  p7,
   input  p9,
   input  p10,
   input  p11,
   input  p15
   );

    sub_123 #( .dly(dly1)) u_a
      (.q   (p13),
       .q_n (p4),

       .a   (p1),
       .b   (p2),
       .clr (p3)
       );

    sub_123 #( .dly(dly2)) u_b
      (.q   (p5),
       .q_n (p12),

       .a   (p9),
       .b   (p10),
       .clr (p11)
       );

endmodule // sn74ls123


module sub_123 #( parameter dly=100 )
  (// Out
   output q,
   output q_n,

   // Input
   input a,
   input b,
   input clr
   );

    reg q;
    wire q_n;

    wire trigger_gated;
    event trigger;    // for debug
    event force_low;  //

    assign q_n = ~q;
    assign trigger_gated = ~a & b & clr;

    // CHEAT
    initial begin
        q <= 1'b0;
    end

    always @(negedge clr or posedge trigger_gated) begin
        if (clr == 1'b0) begin
            ->force_low;
            q <= 1'b0;
        end
        else begin
            ->trigger;
            q <= 1'b1;
            #dly;
            q <= 1'b0;
        end
    end

endmodule // sub_123
`endcelldefine
