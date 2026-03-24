module FA_1_TB();
reg a,b,cin;
wire sum,carry;
FA_1 uut(a,b,cin,sum,carry); //uut(.a(A),.b(B).....) (change reg to A)
initial begin
a=0;b=0;cin=0;
#10 //ns
a=0;b=0;cin=1;
#10
a=0;b=1;cin=0;
#10
a=0;b=1;cin=1;
#10
a=1;b=0;cin=0;
#10
a=1;b=0;cin=1;
#10
a=1;b=1;cin=0;
#10
a=1;b=1;cin=1;
#10
$finish();
end
endmodule
