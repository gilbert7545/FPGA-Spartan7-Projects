module full_subtractor_using_half_subtractor_tb(
);
reg a,b,bin;
wire d,bout;
full_subtractor_using_half_subtractor uut(a,b,bin,d,bout);
initial begin
a=0;b=0;bin=0;
#10 //ns
a=0;b=0;bin=1;
#10
a=0;b=1;bin=0;
#10
a=0;b=1;bin=1;
#10
a=1;b=0;bin=0;
#10
a=1;b=0;bin=1;
#10
a=1;b=1;bin=0;
#10
a=1;b=1;bin=1;
#10
$finish();
end
endmodule

