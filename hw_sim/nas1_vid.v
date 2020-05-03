// Verilog netlist for video circuit of nascom1

module nas_vid
(
 output       clk_cpu,
 output       to_ic32_p12,
 output       to_lk4,

 output       vid_sync, // these two are combined at the video modulator
 output       vid_data,

 input        clk, // 16MHz. On the schematic this is the output of IC6E
 input        vdusel_n,
 input        wr_n,
 input        rd_n,
 input [7:0]  cpu_d,
 input [15:0] cpu_a

 // TODO no reset input.. will need to add one.
 );

    // TODO hack: break feedback loop of latches to aid debug
    // (forced from test-bench)
    wire      allow_feedback;

    // Debug only! Video frame starts with line 15 then goes through lines 0-14.
    wire [3:0] vdu_line;
    assign vdu_line = vdu_a[9:6];
    // Debug only! Divider chain - I did not name this sensibly
    wire [16:0] div;
    assign div = {div16, div15, div14, div13, div12, div10, div9, div8, div7, div6, div5, div4, div3, div2, 1'b0, 1'b0};

    wire [9:0] vdu_a;
    wire [7:0] vdu_d;
    wire [9:0] mux_a;

    wire [6:0] chr_a;
    wire [6:0] chr_d;
    wire [3:0] chr_rs;

    wire       clk_1mhz, clk_2mhz, clk_4mhz, clk_8mhz;
    wire       clk_1mhz_pulse, clk_char_shift, clk_char_ld;
    wire       vid_shift_data;
    wire       active, active_v, active_h, active_v_n, active_h_n;
    wire       s1, s2;
    wire       div2, div3, div4, div5, div6, div7, div8;
    wire       div9, div10, div11, div12, div13, div14, div15, div16;
    wire       div16_n, div6_n, div7_n;
    wire       carry1, carry2, carry3, carry4, carry4_n;
    wire       av_set, av_clr, ah_set, ah_clr; // TODO these should all be _n
    wire       vdu_wr_n, vdu_rd_n;

    // On the real board there is a jumper for selecting this
    assign clk_cpu = clk_2mhz;


    sn74ls163 ic19 // clock divider
      (// Out
       .p11 (clk_1mhz),
       .p12 (clk_2mhz),
       .p13 (clk_4mhz),
       .p14 (clk_8mhz),
       // In
       .p2 (clk),
       .p1 (1'b1),
       .p7 (1'b1),
       .p9 (1'b1),
       .p10 (1'b1),

       .p3 (1'b1), // dangling on NASCOM schematic but unused parallel load and will float high
       .p4 (1'b1), // dangling on NASCOM schematic but unused parallel load and will float high
       .p5 (1'b1), // dangling on NASCOM schematic but unused parallel load and will float high
       .p6 (1'b1) // dangling on NASCOM schematic but unused parallel load and will float high
       );

    // Monostable to generate short load pulse
    // dly1 is associated with p1 trigger, dly2 with p10 trigger
    sn74ls123 #(.dly1(100), .dly2(100)) ic18
      (// Out
       .p4  (),
       .p5  (clk_1mhz_pulse),
       .p12 (clk_char_ld),
       .p13 (clk_char_shift),
       // In
       .p1  (clk_8mhz),
       .p9  (clk_1mhz),
       .p7 (1'b1), // via pullup resistor
       .p15 (1'b1), // via pullup resistor
       .p2 (1'b1),
       .p3 (1'b1),
       .p10 (1'b1),
       .p11(1'b1)
       );

    sn74ls165 ic15 // video shift register
      (// Out
       .so (vid_shift_data),
       // In
       .ck (clk_char_shift),
       .ld_n (clk_char_ld),
       .si (1'b0),
       .en_n (1'b0),
       .a (chr_d[6]),
       .b (chr_d[5]),
       .c (chr_d[4]),
       .d (chr_d[3]),
       .e (chr_d[2]),
       .f (chr_d[1]),
       .g (chr_d[0]),
       .h (1'b0) // last or first dot (the 8th) is always CLEAR
       );

    // Combine active and video
    sn74ls11 ic11
      (// Out
       .p8_co  (vid_data),
       .p6_bo  (active),
       .p12_ao (vid_sync),
       // In
       .p9_ci1 (active),
       .p10_ci2 (vid_shift_data),
       .p11_ci3 (vid_shift_data),

       .p3_bi1 (active_h),
       .p4_bi2 (active_v),
       .p5_bi3 (vdusel_n),

       .p1_ai1 (s2),
       .p2_ai2 (s2),
       .p13_ai3 (s1)
       );


    // Clock dividers
    sn74ls163 ic1
      (//Out
       .p15 (carry1),
       .p14 (div2), // names are 2^n divisions from 1MHz, so div2 is 1/2, div3 is 1/4 etc.
       .p13 (div3),
       .p12 (div4),
       .p11 (div5),

       // In
       .p1  (1'b1),
       .p2  (clk_1mhz_pulse),
       .p3  (1'b0),
       .p4  (1'b0),
       .p5  (1'b0),
       .p6  (1'b0),
       .p7  (1'b1),
       .p9  (carry4_n),
       .p10 (1'b1)
       );


    sn74ls163 ic2
      (//Out
       .p15 (carry2),
       .p14 (div6),
       .p13 (div7), //
       .p12 (div8),
       .p11 (div9),

       // In
       .p1  (1'b1),
       .p2  (clk_1mhz_pulse),
       .p3  (1'b0),
       .p4  (1'b0),
       .p5  (1'b0),
       .p6  (1'b0),
       .p7  (carry1),
       .p9  (carry4_n),
       .p10 (carry1)
       );

    sn74ls163 ic3
      (//Out
       .p15 (carry3),
       .p14 (div10),
       .p13 (div11),
       .p12 (div12),
       .p11 (div13),

       // In
       .p1  (1'b1),
       .p2  (clk_1mhz_pulse),
       .p3  (1'b0),
       .p4  (1'b1),
       .p5  (1'b0),
       .p6  (1'b0),
       .p7  (carry1),
       .p9  (carry4_n),
       .p10 (carry2)
       );

    sn74ls163 ic4
      (//Out
       .p15 (carry4),
       .p14 (div14),
       .p13 (div15),
       .p12 (div16),
       .p11 (),

       // In
       .p1  (1'b1),
       .p2  (clk_1mhz_pulse),
       .p3  (1'b1),
       .p4  (1'b1),
       .p5  (1'b0),
       .p6  (1'b1),
       .p7  (carry1),
       .p9  (carry4_n),
       .p10 (carry3)
       );

    assign chr_rs[3] = div11;
    assign chr_rs[2] = div10;
    assign chr_rs[1] = div9;
    assign chr_rs[0] = div8;

    assign vdu_a[9] = div15;
    assign vdu_a[8] = div14;
    assign vdu_a[7] = div13;
    assign vdu_a[6] = div12;
    assign vdu_a[5] = div7;
    assign vdu_a[4] = div6;
    assign vdu_a[3] = div5;
    assign vdu_a[2] = div4;
    assign vdu_a[1] = div3;
    assign vdu_a[0] = div2;

    // Address mux
    sn74ls157 ic12
      (// Out
       .p4_o1 (mux_a[3]),
       .p7_o2 (mux_a[2]),
       .p9_o3 (mux_a[1]),
       .p12_o4 (mux_a[0]),
       // In
       .p2_a1 (cpu_a[3]),
       .p3_b1 (vdu_a[3]),
       .p5_a2 (cpu_a[2]),
       .p6_b2 (vdu_a[2]),
       .p11_a3 (cpu_a[1]),
       .p10_b3 (vdu_a[1]),
       .p14_a4 (cpu_a[0]),
       .p13_b4 (vdu_a[0]),
       .p1_sel (vdusel_n),
       .p15_enable_n (1'b0)
       );

    sn74ls157 ic13
      (// Out
       .p4_o1 (mux_a[5]),
       .p7_o2 (mux_a[4]),
       .p9_o3 (),
       .p12_o4 (),
       // In
       .p2_a1 (cpu_a[5]),
       .p3_b1 (vdu_a[5]),
       .p5_a2 (cpu_a[4]),
       .p6_b2 (vdu_a[4]),
       .p11_a3 (), // TODO are these really floating?
       .p10_b3 (),
       .p14_a4 (),
       .p13_b4 (),
       .p1_sel (vdusel_n),
       .p15_enable_n (1'b0)
       );

    sn74ls157 ic14
      (// Out
       .p4_o1 (mux_a[9]),
       .p7_o2 (mux_a[8]),
       .p9_o3 (mux_a[7]),
       .p12_o4 (mux_a[6]),
       // In
       .p2_a1 (cpu_a[9]),
       .p3_b1 (vdu_a[9]),
       .p5_a2 (cpu_a[8]),
       .p6_b2 (vdu_a[8]),
       .p11_a3 (cpu_a[7]),
       .p10_b3 (vdu_a[7]),
       .p14_a4 (cpu_a[6]),
       .p13_b4 (vdu_a[6]),
       .p1_sel (vdusel_n),
       .p15_enable_n (1'b0)
       );

    // Video RAM. 1024x1bit decoded at address $0800-$0bff
    x2102an ic20  (.dout (vdu_d[7]), .din (cpu_d[7]), .a (mux_a[9:0]), .cs_n (1'b0), .r_nw (vdu_wr_n));
    x2102an ic27  (.dout (vdu_d[6]), .din (cpu_d[6]), .a (mux_a[9:0]), .cs_n (1'b0), .r_nw (vdu_wr_n));
    x2102an ic26  (.dout (vdu_d[5]), .din (cpu_d[5]), .a (mux_a[9:0]), .cs_n (1'b0), .r_nw (vdu_wr_n));
    x2102an ic25  (.dout (vdu_d[4]), .din (cpu_d[4]), .a (mux_a[9:0]), .cs_n (1'b0), .r_nw (vdu_wr_n));
    x2102an ic24  (.dout (vdu_d[3]), .din (cpu_d[3]), .a (mux_a[9:0]), .cs_n (1'b0), .r_nw (vdu_wr_n));
    x2102an ic23  (.dout (vdu_d[2]), .din (cpu_d[2]), .a (mux_a[9:0]), .cs_n (1'b0), .r_nw (vdu_wr_n));
    x2102an ic22  (.dout (vdu_d[1]), .din (cpu_d[1]), .a (mux_a[9:0]), .cs_n (1'b0), .r_nw (vdu_wr_n));
    x2102an ic21  (.dout (vdu_d[0]), .din (cpu_d[0]), .a (mux_a[9:0]), .cs_n (1'b0), .r_nw (vdu_wr_n));

    // Video RAM read data path to CPU and char generator
    sn81ls97 ic28
      (// Out
       .p17 (cpu_d[7]),
       .p3  (cpu_d[6]),
       .p5  (cpu_d[5]),
       .p7  (cpu_d[4]),
       .p9  (cpu_d[3]),
       .p11 (cpu_d[2]),
       .p13 (cpu_d[1]),
       .p15 (cpu_d[0]),
       // In
       .p18 (vdu_d[7]),
       .p2  (vdu_d[6]),
       .p4  (vdu_d[5]),
       .p6  (vdu_d[4]),
       .p8  (vdu_d[3]),
       .p12 (vdu_d[2]),
       .p14 (vdu_d[1]),
       .p16 (vdu_d[0]),
       //
       .p1  (vdu_rd_n), // /OE
       .p19 (vdu_rd_n)  // /OE
       );


    sn74ls273 ic17
      (// Out
       .p2  (chr_a[6]),
       .p5  (chr_a[5]),
       .p6  (chr_a[4]),
       .p9  (chr_a[3]),
       .p12 (chr_a[2]),
       .p15 (chr_a[1]),
       .p16 (chr_a[0]),
       .p19 (),
       // In
       .p3  (vdu_d[6]),
       .p4  (vdu_d[5]),
       .p7  (vdu_d[4]),
       .p8  (vdu_d[3]),
       .p13 (vdu_d[2]),
       .p14 (vdu_d[1]),
       .p17 (vdu_d[0]),
       .p18 (1'b1), // dangling on NASCOM schematic but unused
       //
       .p11 (clk_1mhz_pulse), // clk
       .p1  (1'b1)            // clr
       );


    sn74ls32 ic45 // ?? quad OR gate
      (// Out
       .p11 (vdu_wr_n),
       .p8  (vdu_rd_n),

       //In
       .p12 (wr_n), // CPU
       .p13 (vdusel_n),
       //
       .p9  (vdusel_n),
       .p10 (rd_n)

       );


    // char generator
    mcm6576 ic16
      (// Out
       .p17 (chr_d[6]),
       .p7  (chr_d[5]),
       .p18 (chr_d[4]),
       .p6  (chr_d[3]),
       .p19 (chr_d[2]),
       .p5  (chr_d[1]),
       .p20 (chr_d[0]),
       // In
       .p4  (chr_a[6]),
       .p8  (chr_a[5]),
       .p9  (chr_a[4]),
       .p11 (chr_a[3]),
       .p12 (chr_a[2]),
       .p14 (chr_a[1]),
       .p15 (chr_a[0]),

       .p24 (chr_rs[3]),
       .p23 (chr_rs[2]),
       .p22 (chr_rs[1]),
       .p21 (chr_rs[0])
       );


    // Monostable to generate video blanking
    // Expect: hsync is 4.7us
    // vsync is ~10h
    // dly1 is associated with p1 trigger, dly2 with p10 trigger
    sn74ls123 #(.dly1(3700), .dly2(246750)) ic7
      (// Out
       .p4  (s2),
       .p5  (),
       .p12 (s1),
       .p13 (),

       // In
       .p1  (div7),
       .p7  (1'b1), // via pullup resistor
       .p15 (1'b1), // via pullup resistor
       .p2  (1'b1),
       .p3  (1'b1),
       .p9  (1'b0),
       .p10 (div16_n),
       .p11 (1'b1)
       );


    // active_b decode
    sn74ls30 ic8
      (// Out
       .p8 (av_clr),
       // In
       .p1 (div14),
       .p2 (div13),
       .p3 (div12),
       .p4 (div12),
       .p5 (div12),
       .p6 (div12),
       .p11 (div16),
       .p12 (div15)
       );

    sn74ls30 ic9
      (// Out
       .p8 (av_set),
       // In
       .p1 (div13),
       .p2 (div12),
       .p3 (div16_n),
       .p4 (div16_n),
       .p5 (div16_n),
       .p6 (div16_n),
       .p11 (div15),
       .p12 (div14)
       );


    // active_c decode
    sn74ls20 ic5
      (// Out
       .p6  (ah_set),
       .p8  (ah_clr),

       // In
       .p1  (div5),
       .p2  (div4),
       .p4  (div7_n),
       .p5  (div6_n),

       .p9  (div4),
       .p10 (div5),
       .p12 (div7),
       .p13 (div6)
       );

    // 2 RS latches
    sn74ls00 ic10
      (// Out
       .p3(active_h),
       .p6(active_h_n),
       .p8(active_v),
       .p11(active_v_n),

       // In
       .p1(ah_set),
       .p2(active_h_n),

       .p4(active_h),
       .p5(ah_clr),

       .p9(av_set),
       .p10(active_v_n),

       .p12(av_clr),
       .p13(active_v)
       );

    // misc
    sn74ls04 ic6 // Actually S04 not LS
      (//Out
       .p2 (div6_n),
       .p4 (div7_n),
       .p6 (carry4_n),
       .p8 (div16_n),
       .p10 (),
       .p12 (),

       //In
       .p1 (div6),
       .p3 (div7),
       .p5 (carry4),
       .p9 (div16),
       .p11(),
       .p13()
       );

endmodule // nas1_vid
