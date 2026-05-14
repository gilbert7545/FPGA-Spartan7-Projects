module mux4to1(
 input A0,
 input B0,
 input A1,
 input B1,
 input S0,
 input S1,
 output Z
    );
    wire Z1,Z2;
    mux2to1 m1(.s(S0),.a(A0),.b(B0),.y(Z1));
    mux2to1 m2(.s(S0),.a(A1),.b(B1),.y(Z2));
    mux2to1 m3(.s(S1),.a(Z1),.b(Z2),.y(Z));
    
endmodule

