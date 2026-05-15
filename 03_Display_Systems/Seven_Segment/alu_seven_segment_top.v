//Design 1
module sev_segment(
 input [3:0] bin,
  output reg [6:0] seg
);
  always @(*) begin
    case (bin)
            4'h0: seg = 7'b0000001;
            4'h1: seg = 7'b1001111;
            4'h2: seg = 7'b0010010;
            4'h3: seg = 7'b0000110;
            4'h4: seg = 7'b1001100;
            4'h5: seg = 7'b0100100;
            4'h6: seg = 7'b0100000;
            4'h7: seg = 7'b0001111;
            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0000100;
            4'hA: seg = 7'b0001000;
            4'hB: seg = 7'b1100000;
            4'hC: seg = 7'b0110000;
            4'hD: seg = 7'b1000010;
            4'hE: seg = 7'b0110000;
            4'hF: seg = 7'b0111000;
      default: seg = 7'b1111111; // Blank
    endcase
  end
endmodule



//Design 2
module arith_logic_unit(
  input  [3:0] a,       
  input  [3:0] b,      
  input  [1:0] s,       
  output [6:0] seg1,    // msb
  output [6:0] seg0,     // lsb
  output q,t,r,x,y,z
  
);

  reg [7:0] result;
  reg [3:0] quotient, remainder;
  reg [3:0] digit1, digit0;
  assign q=1;
  assign t=1;
  assign r=1;
  assign x=1;
  assign y=1;
  assign z=1;
  
  always @(*) begin
    // Default values
    result = 8'b0;
    quotient = 4'b0000;
    remainder = 4'b0000;

    case (s)
      2'b00: result = a + b;      
      2'b01: result = a - b;      
      2'b10: result = a * b;     
      2'b11: begin               
        if (b != 0) begin
          quotient = a / b;
          remainder = a % b;
        end else begin
          quotient = 4'b1111; // Indicate error
          remainder = 4'b1111;
        end
      end
      default: result = 8'b00000000;
    endcase
  end

  // Select digits to display
  always @(*) begin
    if (s == 2'b11) begin
      digit1 = quotient;
      digit0 = remainder;
    end else begin
      digit1 = (result % 100) / 10;  //10s
      digit0 = (result % 100) % 10;  //1s
    end
  end
  sev_segment decoder1 (.bin(digit1),.seg(seg1) );
  sev_segment decoder0 (.bin(digit0),.seg(seg0) );
endmodule

