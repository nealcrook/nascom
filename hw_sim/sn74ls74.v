//
module sn74ls74
  (// Out
   output reg p5_q1,
   output reg p6_q1_n,
   output reg p9_q2,
   output reg p8_q2_n,
   // In
   input      p3_clk1,
   input      p2_d1,
   input      p1_r1_n,
   input      p4_s1_n,
   //
   input      p11_clk2,
   input      p12_d2,
   input      p13_r2_n,
   input      p10_s2_n
   );

    always @(posedge p3_clk1 or negedge p1_r1_n or negedge p4_s1_n) begin
        if ((p1_r1_n == 1'b0) && (p4_s1_n == 1'b0)) begin
            $display("%0t - %m section1 set and reset asserted together: next-state is indeterminate",$time);
            p5_q1 <= 1'b1; // Motorola: both outputs high. YMMV
            p6_q1_n <= 1'b1;
        end
        else if (p1_r1_n == 1'b0) begin
            p5_q1 <= 1'b0;
            p6_q1_n <= 1'b1;
        end
        else if (p4_s1_n == 1'b0) begin
            p5_q1 <= 1'b1;
            p6_q1_n <= 1'b0;
        end
        else begin
            p5_q1 <= p2_d1;
            p6_q1_n <= !p2_d1;
        end
    end

    always @(posedge p11_clk2 or negedge p13_r2_n or negedge p10_s2_n) begin
        if ((p13_r2_n == 1'b0) && (p10_s2_n == 1'b0)) begin
            $display("%0t - %m section 2 set and reset asserted together: next-state is indeterminate",$time);
            p9_q2 <= 1'b1; // Motorola: both outputs high. YMMV
            p8_q2_n <= 1'b1;
        end
        else if (p13_r2_n == 1'b0) begin
            p9_q2 <= 1'b0;
            p8_q2_n <= 1'b1;
        end
        else if (p10_s2_n == 1'b0) begin
            p9_q2 <= 1'b1;
            p8_q2_n <= 1'b0;
        end
        else begin
            p9_q2 <= p12_d2;
            p8_q2_n <= !p12_d2;
        end
    end

endmodule // sn74ls74
