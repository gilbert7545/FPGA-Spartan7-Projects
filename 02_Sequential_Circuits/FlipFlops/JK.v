
module JK(
  input clk,       // Clock input
  input j,         // J input
  input k,         // K input
  input reset,     // Asynchronous reset
  output reg q,    // Output
  output q_not     // Complement output
);

  assign q_not = ~q;

  always @(posedge clk or posedge reset) begin
    if (reset)
      q <= 0;                   // Reset output to 0
    else begin
      case ({j, k})
        2'b00: q <= q;          // No change
        2'b01: q <= 0;          // Reset
        2'b10: q <= 1;          // Set
        2'b11: q <= ~q;         // Toggle
      endcase
    end
  end

endmodule

