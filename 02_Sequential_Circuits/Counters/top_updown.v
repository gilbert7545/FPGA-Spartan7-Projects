//UP DOWN COUNTER
//Design 1
module updowncountr(
    input wire clk_1Hz,
    input wire reset,
    input wire select,        
     output  [6:0] seg1,
     output  [6:0]seg0,
    output reg [3:0] count
 );
wire [3:0] digit1,digit0;

always @(posedge clk_1Hz or posedge reset )
 begin
        if (reset)
            count <= 4'b0000;
        else if (select)
            count <= count + 1;
        else
            count <= count - 1;
    end

   assign digit1 =count/10;  //10s
   assign digit0 =count%10;  //1s
  
  decoder decoder1 (.bin(digit1),.seg(seg1) );
  decoder decoder0 (.bin(digit0),.seg(seg0) );

endmodule

//Design 2
module decoder(
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
          
    endcase
  end
endmodule


//Design 3
module clk(
input wire clk,
input wire reset,
output reg clk_1Hz);
reg [25:0] count;

always @(posedge clk)
begin
if(reset) begin
count<=0;
clk_1Hz<=0;
end else begin
if(count ==26'd49_999_999)
begin
clk_1Hz<= ~clk_1Hz;
count<=0;
end
else
begin
count<=count+1;
end
end
end
endmodule

//Design 4
module top(
    input wire clk,
    input wire reset,
    input wire select,          
    output  [6:0] seg1,
    output[6:0] seg0,
    output q,w,e,r,t,y

);
    wire clk_1Hz;
    wire [3:0] count;
    assign q=1;
    assign w=1;
    assign e=1;
    assign r=1;
    assign t=1;
    assign y=1;
    clk clk1 (
        .clk(clk),
        .reset(reset),
        .clk_1Hz(clk_1Hz)
    );

    updowncountr updown (
        .clk_1Hz(clk_1Hz),
        .reset(reset),
        .select(select),
        .count(count),.seg1(seg1),.seg0(seg0)
    );
endmodule

