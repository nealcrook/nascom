// parallel-load 8-bit shift register
module sn74ls165
  (
   output reg so,
   output so_n,

   input  ck,
   input  en_n,
   input  ld_n,

   input  si,

   input  a,
   input  b,
   input  c,
   input  d,
   input  e,
   input  f,
   input  g,
   input  h
   );

    reg [7:0] dat;
    assign so_n = ~ so;

    wire  clk;

    assign clk = ck | en_n;

    always @(posedge clk or negedge ld_n) begin
        if (ld_n == 1'b0) begin
            dat <= {h,g,f,e,d,c,b,a};
        end
        else begin
            so <= dat[7];
            dat <= {dat[6:0], si};
        end
    end


endmodule // sn74ls165
