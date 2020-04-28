// Verilog netlist for video circuit of nascom2

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
//    wire      allow_feedback;

    // Debug only! Video frame starts with line 15 then goes through lines 0-14.
    wire [3:0] vdu_line;
    assign vdu_line = vdu_a[9:6];



    wire [9:0] vdu_a;
    wire [7:0] vdu_d;
    wire [9:0] mux_a;

    wire [7:0] chr_a;
    wire [7:0] chr_d;
    wire [3:0] chr_rs;
    wire       chr_rs3_n;

    wire       clk_1mhz, clk_2mhz, clk_4mhz, clk_8mhz;
    wire       clk_xx, clk_char_shift, clk_char_ld;
    wire       vid_shift_data;
    wire       div2, div3, div4, div5, div6, div6_n, div7, div7_n;

    wire       blanking_n;
    wire       vram_acc_n;
    wire       vram_stg1;
    wire       vdu_a_clr_n;
    wire       alph_n, graphics_n;
    wire       hblank, hblank_n, vblank_n;

    wire       s1, s2;
    wire       carry1, carry2;
    wire       chr_rst;
    wire       set_n, clr_n;
    wire       vdu_a_clk, vdu_line_clk, vdu_line_clk_n;

    // Make portlist match between N1 and N2
    wire      vram_n;
    assign vram_n = vdusel_n;

    // Make internal probed node match between N1 and N2
    // TODO rename to match N1 if behavour/polarity is correct
    wire      active_v;
    assign active_v = !vblank_n;


    // On the real board there is a jumper for selecting this
    assign clk_cpu = clk_2mhz;


    sn74ls193 ic49 // clock divider
      (// Out
       .p13 (clk_xx),
       .p12 (),
       .p7 (clk_1mhz),
       .p6 (clk_2mhz),
       .p2 (clk_4mhz),
       .p3 (clk_8mhz),
       // In
       .p4 (clk), // 16MHz input clock
       .p1 (1'b1),
       .p5 (1'b1),
       .p9 (1'b1),
       .p10 (1'b1),
       .p11 (1'b1),
       .p15 (1'b1),
       .p14 (1'b0)
       );


    // Gate to generate short load pulse
    sn74ls13 ic71
      (// Out
       .p6  (clk_char_ld),

       // In
       .p1  (clk_8mhz),
       .p2  (clk_4mhz),
       .p4  (clk_2mhz),
       .p5  (clk_1mhz)
       );


    sn74ls165 ic65 // video shift register
      (// Out
       .so (vid_shift_data),
       // In
       .ck (clk_8mhz),
       .ld_n (clk_char_ld),
       .si (chr_d[0]),
       .en_n (clk_8mhz),
       .a (chr_d[0]), // on N1 the data bits are the
       .b (chr_d[1]), // other way around
       .c (chr_d[2]),
       .d (chr_d[3]),
       .e (chr_d[4]),
       .f (chr_d[5]),
       .g (chr_d[6]),
       .h (chr_d[7])
       );


    // Combine active and video blanking
    sn74ls11 ic61
      (// Out
       .p8_co  (vid_sync), // SYNCS on N2 schematic
       .p6_bo  (),
       .p12_ao (vid_data),
       // In
       .p9_ci1 (s2),
       .p10_ci2 (1'b1),
       .p11_ci3 (s1),

       .p3_bi1 (),
       .p4_bi2 (),
       .p5_bi3 (),

       .p1_ai1 (blanking_n),
       .p2_ai2 (vram_acc_n),
       .p13_ai3 (vid_shift_data)
       );


    // Monostable to blank the video when CPU accesses
    // vram ("Black Snow")
    // TODO calculate delay
    // dly1 is associated with p1 trigger, dly2 with p10 trigger
    sn74ls123 #(.dly1(3700), .dly2(246750)) ic58
      (// Out
       .p4  (vram_acc_n),
       .p5  (vram_stg1),
       .p12 (),
       .p13 (),

       // In
       .p1  (vram_stg1),
       .p7  (1'b1), // via pullup resistor
       .p15 (1'b1), // via pullup resistor
       .p2  (1'b1),
       .p3  (1'b1),
       .p9  (vram_n),
       .p10 (1'b1),
       .p11 (1'b1)
       );


    // Monostable to generate video blanking
    // TODO Calculate delays
    // Expect: hsync is 4.7us
    // vsync is ~10h
    // dly1 is associated with p1 trigger, dly2 with p10 trigger
    sn74ls123 #(.dly1(3700), .dly2(246750)) ic57
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
       .p10 (vdu_a_clr_n), // TODO name
       .p11 (1'b1)
       );


    // Clock dividers
    sn74ls163 ic51
      (//Out
       .p15 (carry1),
       .p14 (div2), // names are 2^n divisions from 1MHz, so div2 is 1/2, div3 is 1/4 etc.
       .p13 (div3),
       .p12 (div4),
       .p11 (div5),

       // In
       .p1  (1'b1),
       .p2  (clk_xx),
       .p3  (1'b0),
       .p4  (1'b0),
       .p5  (1'b0),
       .p6  (1'b0),
       .p7  (1'b1),
       .p9  (1'b1),
       .p10 (1'b1)
       );


    sn74ls163 ic52
      (//Out
       .p15 (carry2),
       .p14 (div6),
       .p13 (div7),
       .p12 (),
       .p11 (),

       // In
       .p1  (1'b1),
       .p2  (clk_xx),
       .p3  (1'b0),
       .p4  (1'b0),
       .p5  (1'b0),
       .p6  (1'b0),
       .p7  (carry1),
       .p9  (1'b1),
       .p10 (carry1)
       );


    sn74ls161 ic53
      (//Out
       .p14 (chr_rs[0]),
       .p13 (chr_rs[1]),
       .p12 (chr_rs[2]),
       .p11 (chr_rs[3]),

       // In
       .p1  (chr_rst), // TODO polarity
       .p2  (div7_n),
       .p7  (1'b1),
       .p9  (1'b1),
       .p10 (1'b1),
       .p3  (1'b1), // TODO no connection shown on N2 schematic. Floating to 1? or wired??
       .p4  (1'b1), // TODO no connection shown on N2 schematic. Floating to 1? or wired??
       .p5  (1'b1), // TODO no connection shown on N2 schematic. Floating to 1? or wired??
       .p6  (1'b1)  // TODO no connection shown on N2 schematic. Floating to 1? or wired??
       );


    sn74ls10 ic44
      (// Out
       .p8_co  (chr_rst),
       .p6_bo  (),
       .p12_ao (),
       // In
       .p9_ci1 (chr_rs[1]), // LSW11: chr_rs[1] for 14 rows (625 line). 1'b1 for 12 rows (525 line)
       .p10_ci2 (chr_rs[2]),
       .p11_ci3 (chr_rs[3]),
       //
       .p3_bi1 (),
       .p4_bi2 (),
       .p5_bi3 (),
       //
       .p1_ai1 (),
       .p2_ai2 (),
       .p13_ai3 ()
       );


    // miscellaneous inversions
    // 2 parts of this are used for the 16MHz oscillator, not modelled here
    sn74ls04 ic56 // Actually S04 not LS
      (//Out
       .p6 (chr_rs3_n),
       .p2 (div6_n),
       .p4 (div7_n),
       .p8 (),

       //In
       .p5 (chr_rs[3]),
       .p1 (div6),
       .p3 (div7),
       .p9 ()
       );


    // Gate to decode set/reset control
    sn74ls13 ic55
      (// Out
       .p6  (set_n),
       .p8  (clr_n),

       // In
       .p1  (div5),
       .p2  (div6_n),
       .p4  (div4),
       .p5  (div7_n),
       //
       .p9  (div4),
       .p10 (div5),
       .p12 (div6),
       .p13 (div7)
       );


    // RS latch
    sn74ls00 ic60
      (// Out
       .p3(hblank_n), // TODO
       .p6(hblank),
       .p8(),
       .p11(),

       // In
       .p1(set_n),
       .p2(hblank),

       .p4(hblank_n),
       .p5(clr_n),

       .p9(),
       .p10(),

       .p12(),
       .p13()
       );

    // combine horizontal and vertical blanking
    sn74ls08 ic8
      (// Out
       .p3(blanking_n),
       .p6(),
       .p8(),
       .p11(),

       // In
       .p1(hblank_n), // TODO??
       .p2(vblank_n),

       .p4(),
       .p5(),

       .p9(),
       .p10(),

       .p12(),
       .p13()
       );


    // divider TODO names above or on ic line? Inconsistent on N1
    sn74ls193 ic68
      (// Out
       .p13 (),
       .p12 (vdu_a_clk), // TODO name
       .p7 (vdu_a[9]),
       .p6 (vdu_a[8]),
       .p2 (vdu_a[7]),
       .p3 (vdu_a[6]),
       // In
       .p4 (1'b1),
       .p1 (1'b1),
       .p5 (chr_rs3_n),
       .p9 (1'b1),
       .p10 (1'b0),
       .p11 (vdu_a_clr_n), // /LOAD
       .p15 (1'b1),
       .p14 (1'b0)
       );


    // Divide by 2
    sn74ls74 ic13
      (// Out
       .p5_q1    (),
       .p6_q1_n  (),
       .p9_q2    (vdu_line_clk), // TODO name
       .p8_q2_n  (vdu_line_clk_n),
       // In
       .p3_clk1 (),
       .p2_d1   (),
       .p1_r1_n (),
       .p4_s1_n (),
       //
       .p11_clk2 (vdu_a_clk),
       .p12_d2   (vdu_line_clk_n),
       .p13_r2_n (vdu_a_clr_n), // TODO name
       .p10_s2_n (1'b1)
       );


    // PROM used as decoder
    prom_n2v ic59
      (//Out
       .d1 (vblank_n),
       .d0 (vdu_a_clr_n), // has 330pF to ground. Why? TODO schematic is ambiguous.. connected to 7474 R etc?

       .ce_n (1'b0),
       .a4 (vdu_line_clk),
       .a3 (vdu_a[9]),
       .a2 (vdu_a[8]),
       .a1 (vdu_a[7]),
       .a0 (vdu_a[6])
       );


    assign vdu_a[5] = div7;
    assign vdu_a[4] = div6;
    assign vdu_a[3] = div5;
    assign vdu_a[2] = div4;
    assign vdu_a[1] = div3;
    assign vdu_a[0] = div2;

    // Address mux
    sn74ls157 ic62
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
       .p1_sel (vram_n),
       .p15_enable_n (1'b0)
       );

    sn74ls157 ic63
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
       .p1_sel (vram_n),
       .p15_enable_n (1'b0)
       );

    sn74ls157 ic64
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
       .p1_sel (vram_n),
       .p15_enable_n (1'b0)
       );


    // Video RAM. 1024x8bit decoded at address $0800-$0bff
    mk4118 ic50
      (// In/Out
       .d7 (vdu_d[7]),
       .d6 (vdu_d[6]),
       .d5 (vdu_d[5]),
       .d4 (vdu_d[4]),
       .d3 (vdu_d[3]),
       .d2 (vdu_d[2]),
       .d1 (vdu_d[1]),
       .d0 (vdu_d[0]),
       // In
       .a9 (mux_a[9]),
       .a8 (mux_a[8]),
       .a7 (mux_a[7]),
       .a6 (mux_a[6]),
       .a5 (mux_a[5]),
       .a4 (mux_a[4]),
       .a3 (mux_a[3]),
       .a2 (mux_a[2]),
       .a1 (mux_a[1]),
       .a0 (mux_a[0]),
       //
       .ce_n (1'b0),
       .we_n (1'b1), // TODO driven low during CPU write
       .oe_n (1'b0)  // TODO driven high to allow CPU write
       );


    // Video RAM read data path to CPU
    dp8304 ic70
      (// In/Out
       .p8  (vdu_d[7]), // port A
       .p1  (vdu_d[0]), // note weird ordering
       .p2  (vdu_d[1]),
       .p3  (vdu_d[2]),
       .p4  (vdu_d[3]),
       .p5  (vdu_d[4]),
       .p6  (vdu_d[5]),
       .p7  (vdu_d[6]),
       //
       .p12 (cpu_d[7]), // port B
       .p19 (cpu_d[0]),
       .p18 (cpu_d[1]),
       .p17 (cpu_d[2]),
       .p16 (cpu_d[3]),
       .p15 (cpu_d[4]),
       .p14 (cpu_d[5]),
       .p13 (cpu_d[6]),
       // In
       .p11_dir  (1'b0), // 1 => A->B 0 => B->A        // TODO controlled from CPU
       .p9_cd    (1'b1)  // 1 => tristate all outputs  // TODO controlled from CPU
       );


    // Video RAM read data path to char generator
    sn74ls273 ic67
      (// Out
       .p2  (chr_a[6]), // Weird ordering so 6:0 match N1.
       .p5  (chr_a[5]),
       .p6  (chr_a[4]),
       .p9  (chr_a[3]),
       .p12 (chr_a[2]),
       .p15 (chr_a[1]),
       .p16 (chr_a[0]),
       .p19 (chr_a[7]), // LSW2/9 can force chr_a[7]=0 if no NAS-GRA ROM
       // In
       .p3  (vdu_d[6]),
       .p4  (vdu_d[5]),
       .p7  (vdu_d[4]),
       .p8  (vdu_d[3]),
       .p13 (vdu_d[2]),
       .p14 (vdu_d[1]),
       .p17 (vdu_d[0]),
       .p18 (vdu_d[7]),
       //
       .p11 (clk_char_ld), // clk
       .p1  (1'b1)         // /clr
       );


    assign alph_n = chr_a[7];


    sn74ls14 ic11
      (//Out
       .p10 (graphics_n),

       //In
       .p11 (alph_n)
       );


    // char generator ROM
    eprom2716 ic66
      (// Out
       .p17_d7  (chr_d[7]),
       .p16_d6  (chr_d[6]),
       .p15_d5  (chr_d[5]),
       .p14_d4  (chr_d[4]),
       .p13_d3  (chr_d[3]),
       .p11_d2  (chr_d[2]),
       .p10_d1  (chr_d[1]),
       .p9_d0   (chr_d[0]),
       // In
       .p19_a10 (chr_a[6]),
       .p22_a9  (chr_a[5]),
       .p23_a8  (chr_a[4]),
       .p1_a7   (chr_a[3]),
       .p2_a6   (chr_a[2]),
       .p3_a5   (chr_a[1]),
       .p4_a4   (chr_a[0]),
       .p5_a3   (chr_rs[3]),
       .p6_a2   (chr_rs[2]),
       .p7_a1   (chr_rs[1]),
       .p8_a0   (chr_rs[0]),
       //
       .vpp     (1'b1),
       .cs_n    (alph_n),
       .oe_n    (alph_n)
       );


    // graphics ROM
    eprom2716 ic54
      (// Out
       .p17_d7  (chr_d[7]),
       .p16_d6  (chr_d[6]),
       .p15_d5  (chr_d[5]),
       .p14_d4  (chr_d[4]),
       .p13_d3  (chr_d[3]),
       .p11_d2  (chr_d[2]),
       .p10_d1  (chr_d[1]),
       .p9_d0   (chr_d[0]),
       // In
       .p19_a10 (chr_a[6]),
       .p22_a9  (chr_a[5]),
       .p23_a8  (chr_a[4]),
       .p1_a7   (chr_a[3]),
       .p2_a6   (chr_a[2]),
       .p3_a5   (chr_a[1]),
       .p4_a4   (chr_a[0]),
       .p5_a3   (chr_rs[3]),
       .p6_a2   (chr_rs[2]),
       .p7_a1   (chr_rs[1]),
       .p8_a0   (chr_rs[0]),
       //
       .vpp     (1'b1),
       .cs_n    (graphics_n),
       .oe_n    (graphics_n)
       );

endmodule // nas_vid
