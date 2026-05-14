module SR_TB;
  reg clk, s, r, rst;
  wire q, q_not;

  SR uut (.clk(clk), .s(s), .r(r), .rst(rst), .q(q), .q_not(q_not));

  always #5 clk = ~clk;

  initial begin
    clk = 0; s = 0; r = 0; rst = 0;
    #10 s = 0; r = 0;
    #10 s = 0; r = 1;
    #10 s = 1; r = 0;
    #10 s = 1; r = 1;
    #10 s = 1; r = 1;
    #10 rst = 1;
    #10 rst = 0;
    #10 s = 0; r = 0;
    #10 $finish;
  end
endmodule



