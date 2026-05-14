//Design1
module Counter_4bit(
    input wire clk,        // Clock input
    input wire rst,        // Synchronous reset (active high
    output reg [3:0] count // 4-bit output count
);
wire clk_1hz;

clock_div uut (.clk_100MHz(clk),.rst(reset),.clk_1hz(clk_1hz));

always @(posedge clk_1hz) begin
    if (rst)
        count <= 4'b0000; // Reset counter to 0
    else 
        count <= count + 1; // Increment counter by 1
end

endmodule



//Design2
module clock_div(
  input wire clk_100MHz,
  input wire rst ,
  output reg clk_1hz

    );
    
    reg [25:0] count;
    always@(posedge clk_100MHz)
    begin
    if (rst) begin 
    count<=0;
    clk_1hz<=0;
    end 
    else begin 
    if(count==26'd49000000) begin
    clk_1hz=~clk_1hz;
    count<=0;
    end else begin 
    count<=count+1;
    end
    end
    end
    
endmodule

