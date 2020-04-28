//
module prom_n2v
  (
   output d1,
   output d0,

   input ce_n,
   input a4,
   input a3,
   input a2,
   input a1,
   input a0
   );

    reg [1:0] d_i;
    wire [4:0] a;

    assign {d1, d0} = ce_n ? 2'bzz : d_i;
    assign a = {a4, a3, a2, a1, a0};

    always @(a) begin
        case (a)
          // read off the listing in the NASCOM 2 hardware manual
          0:  d_i = 2'b01;
          1:  d_i = 2'b00;
          2:  d_i = 2'b11;
          3:  d_i = 2'b11;

          4:  d_i = 2'b11;
          5:  d_i = 2'b11;
          6:  d_i = 2'b11;
          7:  d_i = 2'b11;

          8:  d_i = 2'b11;
          9:  d_i = 2'b11;
          10: d_i = 2'b11;
          11: d_i = 2'b01;

          12: d_i = 2'b01;
          13: d_i = 2'b01;
          14: d_i = 2'b01;
          15: d_i = 2'b11;

          16: d_i = 2'b11;
          17: d_i = 2'b11;
          18: d_i = 2'b11;
          19: d_i = 2'b11;

          20: d_i = 2'b11;
          21: d_i = 2'b11;
          22: d_i = 2'b11;
          23: d_i = 2'b11;

          24: d_i = 2'b11;
          25: d_i = 2'b11;
          26: d_i = 2'b11;
          27: d_i = 2'b11;

          28: d_i = 2'b11;
          29: d_i = 2'b11;
          30: d_i = 2'b11;
          31: d_i = 2'b01;

          default: d_i = 2'bxx;
        endcase // case (d_i)
    end // always @ (a)
endmodule // prom_n2v
