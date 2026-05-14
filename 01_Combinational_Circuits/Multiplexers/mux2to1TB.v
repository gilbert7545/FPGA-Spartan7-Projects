module mux2to1TB(
    );
reg s,a,b;
wire y;
mux2to1 uut(s,a,b,y);
initial begin
s=0;a=0;b=0;
#10 //ns
s=0;a=0;b=1;
#10
s=0;a=1;b=0;
#10
s=0;a=1;b=1;
#10
s=1;a=0;b=0;
#10
s=1;a=0;b=1;
#10
s=1;a=1;b=0;
#10
s=1;a=1;b=1;
#10
$finish();
end
endmodule


