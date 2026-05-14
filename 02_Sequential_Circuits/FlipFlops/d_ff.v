module dflipflop(
input d,
    input clk,
    input rst,
    output reg q,
    output reg q_not
);
    always @(posedge clk) begin
    if(rst)begin
    q<=0;
    q_not<=1;
    end
    else begin
    q<=d;
    q_not<=~d;
    end
    end
endmodule




module d_flipfloptb();
 reg clk, d, rst;
    wire q, q_not;

    // Instantiate the module
    dflipflop uut (.d(d), .clk(clk), .rst(rst), .q(q), .q_not(q_not));

    // Clock generation: Toggle clk every 5 ns
    always #5 clk = ~clk;

    initial begin
        // Initial values
        clk = 0;
        d = 0;
        rst = 1;     // Reset is active

        #10 rst = 0; // Release reset after 10 ns
        #10 d = 1;   // At rising edge, q should become 1
        #10 d = 0;   // q should become 0 at next clock
        #10 rst = 1; // Activate reset again
        #10 rst = 0; // Deactivate reset
        #10 d = 1;   // q should follow d again

        #20 $finish;
    end

endmodule
module dflipflop_4bit(
    input [3:0] d,
    input clk,
    input rst,
    output [3:0] q,
    output [3:0] q_not
    );
    dflipflop dff0(.d(d[0]),.clk(clk),.rst(rst),.q(q[0]),.q_not(q_not[0]));
    dflipflop dff1(.d(d[1]),.clk(clk),.rst(rst),.q(q[1]),.q_not(q_not[1]));
    dflipflop dff2(.d(d[2]),.clk(clk),.rst(rst),.q(q[2]),.q_not(q_not[2]));
    dflipflop dff3(.d(d[3]),.clk(clk),.rst(rst),.q(q[3]),.q_not(q_not[3]));

endmodule

