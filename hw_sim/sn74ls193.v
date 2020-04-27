// synchronous 4-bit up/down counter (dual clock with clear)
module sn74ls193
  (// Output
   output p13, // /BO Borrow Out
   output p12, // /CO Carry Out
   output p7,  // QD
   output p6,  // QC
   output p2,  // QB
   output p3,  // QA
   // In
   input  p4,  // DOWN
   input  p5,  // UP
   input  p9,  // D
   input  p10, // C
   input  p1,  // B
   input  p15, // A
   input  p11, // /LOAD
   input  p14  // CLR
   );

    reg   [3:0] count;

    assign {p7, p6, p2, p3} = count;
    assign p12 = !( (count == 4'b1111) & !p5);
    assign p13 = !( (count == 4'b0000) & !p4);

    // CHEATING
    initial begin
        count <= 4'b0000;
    end

    always @(posedge p14 or negedge p11 or posedge p5 or posedge p4) begin
        if (p14 == 1'b1) begin
            count <= 4'b0; // Clear
        end
        else if (p11 == 1'b0) begin
            count <= {p9, p10, p1, p15}; // Load
        end
        else if (p5 == 1'b1) begin
            count <= count + 4'b0001;
        end
        else if (p4 == 1'b1) begin
            count <= count - 4'b0001;
        end
    end

endmodule // sn74ls193
