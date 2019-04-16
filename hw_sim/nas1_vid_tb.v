module nas1_vid_tb
  (
   );

    reg clk;
    reg reset_n;
    time frame_start;

    // UUT
    nas1_vid u_nas1_vid
      ( // Out
        .clk_cpu (),
        .to_ic32_p12 (),
        .to_lk4 (),

        .vid_sync(),
        .vid_data(),

        // In
        .clk (clk),
        .vdusel_n (1'b1),
        .wr_n  (1'b1),
        .rd_n  (1'b1),
        .cpu_d (8'b0),
        .cpu_a (16'b0)
        );

    initial begin
        frame_start = 0;
        reset_n = 1'b0;
        // CHEAT for debug
//        force u_nas1_vid.allow_feedback = 1'b0;

        clk = 1'b0;
        #31.250;                 // 16MHz half period is 31.25ns
        clk = 1'b1;
        #31.250;
        clk = 1'b0;
        #31.250;
        reset_n = 1'b1;
        forever begin
            clk = 1'b1;
            #31.250;
            clk = 1'b0;
            #31.250;
        end
    end

    integer i;
    initial begin
        $dumpfile("nas1_vid_tb.vcd");
        $dumpvars(0,nas1_vid_tb);
        for (i = 1; i<10; i=i+1) begin
            $display("%d..", i);
            #40000000;
        end
        $display("End");
        $finish();
    end

    always @(posedge u_nas1_vid.active_v) begin
        if (frame_start != 0) begin
            $display("Frame period is %t ns",$time - frame_start);
        end
        frame_start = $time;
    end

endmodule // nas1_vid_tb
