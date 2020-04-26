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

    reg [1:0] d;
    reg [4:0] a;

    assign {d1, d0} = ce_n ? 2'bzz : d;
    assign a = {a4, a3, a2, a1, a0};

    always @(a) begin
        case (d)
          // read off the listing in the Nascom 2 hardware manual
          0: d = 2'b01;
          1: d = 2'b00;
          2: d = 2'b11;
          3: d = 2'b11;

          4: d = 2'b11;
          5: d = 2'b11;
          6: d = 2'b11;
          7: d = 2'b11;

          8: d = 2'b11;
          9: d = 2'b11;
          10: d = 2'b11;
          11: d = 2'b01;

          12: d = 2'b01;
          13: d = 2'b01;
          14: d = 2'b01;
          15: d = 2'b11;

          16: d = 2'b11;
          17: d = 2'b11;
          18: d = 2'b11;
          19: d = 2'b11;

          20: d = 2'b11;
          21: d = 2'b11;
          22: d = 2'b11;
          23: d = 2'b11;

          24: d = 2'b11;
          25: d = 2'b11;
          26: d = 2'b11;
          27: d = 2'b11;

          28: d = 2'b11;
          29: d = 2'b11;
          30: d = 2'b11;
          31: d = 2'b01;

          default: d = 2'bxx;
        endcase // case (d)
    end // always @ (a)
endmodule // prom_n2v
