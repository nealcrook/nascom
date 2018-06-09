// 4-bit binary counter with synchronous reset
module sn74ls163
  (
   output p11,
   output p12,
   output p13,
   output p14,
   output p15,

   input  p1,
   input  p2,
   input  p3,
   input  p4,
   input  p5,
   input  p6,
   input  p7,
   input  p9,
   input  p10
   );



    wire  cet, cep, cp, sr, pe;
    wire [3:0] d;
    reg [3:0] count;
    wire      tc;

    assign {p11,p12,p13,p14} = count;
    assign d = {p6,p5,p4,p3};
    assign p15 = tc;
    assign {cet,cep,cp,sr,pe} = {p10,p7,p2,p1,p9};

    // CHEATING
    initial begin
        count <= 4'b0;
    end

    assign tc = cet & (count == 4'b1111);

    always @(posedge cp) begin
        if (sr == 1'b0) begin
            // synchronous reset, active low
            count <= 4'b0;
        end
        else if (pe == 1'b0) begin
            // synchronous parallel (load) enable, active low
            count <= d;
        end
        else if (cet & cep) begin
            count <= count + 4'b0001;
        end
    end // always @ (posedge cp)


endmodule // sn74ls163
