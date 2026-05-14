module SR(
    input s,
    input r,
    output reg q,
    output reg q_not,
    input clk,
    input rst
    );
    always @(posedge clk)
    begin
    if(rst) begin
    q<=0;
    q_not<=0; end
    else begin
    if (s==0 && r==0) begin
    q<=q;
    q_not<=q_not;
    end
    else if(s==0 && r==1) begin
    q<=0;
    q_not<=1;
    end
    else if(s==1 && r==0) begin
    q<=1;
    q_not<=0;
    end
    else begin
    q<=1;
    q_not<=1;
    end
    end
    end
endmodule

