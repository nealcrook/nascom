// synchronous 4-bit counter
module sn74ls161
  (//Out
   output reg p15, // RCO
   output p14, // QA LSB
   output p13, // QB
   output p12, // QC
   output p11, // QD MSB
   // In
   input  p1, // /CLR
   input  p2, // CLK
   input  p7, // ENP
   input  p9, // /LOAD
   input  p10, // ENT
   input  p3, // A
   input  p4, // B
   input  p5, // C
   input  p6  // D
   );

    reg [3:0] count;
    assign {p11, p12, p13, p14} = count;

    // CHEATING
    initial begin
        count <= 4'b0000;
    end

    always @(negedge p1 or posedge p2) begin
        if (p1 == 1'b0) begin
            // Async /CLR
            count <= 4'b0000;
        end
        else begin
            if (p9 == 1'b0) begin
                // Synchronous load
                count <= {p6, p5, p4, p3};
            end
            else if ((p7 == 1'b1) && (p10 == 1'b1)) begin
                count <= count + 4'b0001;
                p15 <= count == 4'b1111;
            end
        end
    end

endmodule // sn74ls161
