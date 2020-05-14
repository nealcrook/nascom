`timescale 1ns/1ps
`celldefine
// the models have no delays in them. As a result, an asynchronous
// reset on a counter chain seems to happen without any visible
// reset signal. To make the waveforms easier to follow, it's
// convenient to add a small delay on some signals so that those
// reset pulses become visible.

//  That makes it
// difficult to see t
module delay
  #( parameter dly = 10)

    (output z,
     input a
     );

    assign #dly z = a;

endmodule // delay
`endcelldefine
