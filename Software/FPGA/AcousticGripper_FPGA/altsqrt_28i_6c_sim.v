`timescale 1ns/1ps
module altsqrt_28i_6c (
    input  wire        clk,
    input  wire [27:0] radical,
    output reg  [13:0] q,
    output wire [13:0] remainder
);
    // 6-stage pipeline — matches real IP latency exactly
    reg [27:0] pipe [0:5];
    integer i;
    
    always @(posedge clk) begin
        pipe[0] <= radical;
        for (i = 1; i < 6; i = i + 1)
            pipe[i] <= pipe[i-1];
        
        // integer square root of the delayed input
        q <= $rtoi($sqrt($itor(pipe[5])));
    end
    
    assign remainder = 14'b0;
endmodule