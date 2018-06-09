// octal d-type flop with clear
module sn74ls273
  (
   output p2,
   output p5,
   output p6,
   output p9,
   output p12,
   output p15,
   output p16,
   output p19,

   input  p3,
   input  p4,
   input  p7,
   input  p8,
   input  p13,
   input  p14,
   input  p17,
   input  p18,

   input  p11,
   input  p1
   );

    wire [7:0] d;
    reg [7:0]  q;
    wire       clr_n;
    wire       clk;

    assign d = {p18,p17,p14,p13,p8,p7,p4,p3};
    assign {p19,p16,p15,p12,p9,p6,p5,p2} = q;
    assign clk = p11;
    assign clr_n = p1;

    always @(posedge clk or negedge clr_n) begin
        if (clr_n == 1'b0) begin
            q <= 8'b0;
        end
        else begin
            q <= d;
        end
    end

endmodule // sn74ls273
