module full_adder_tb();
reg a,b,cin;
wire sum,carry;
full_adder uut(a,b,cin,sum,carry); //uut(.a(A),.b(B).....) (change reg to A)
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

