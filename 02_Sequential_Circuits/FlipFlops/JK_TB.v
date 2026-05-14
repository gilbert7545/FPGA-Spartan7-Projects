module JK_TB();
  reg clk, j, k, reset;
  wire q, q_not;

  JK uut (.clk(clk),.j(j),.k(k),.reset(reset),.q(q),.q_not(q_not);

  always #5 clk = ~clk;

  initial begin
    clk = 0; j = 0; k = 0; reset = 0;
    #10 j = 0; k = 0;
    #10 j = 0; k = 1;
    #10 j = 1; k = 0;
    #10 j = 1; k = 1;
    #10 j = 1; k = 1;
    #10 reset = 1;
    #10 reset = 0;
    #10 j = 0; k = 0;
    #10 $finish;
  end
endmodule

