module mux4to1tb(
);
reg A0,B0,A1,B1,S0,S1;
    wire Z;
    mux4to1 uut (A0,B0,A1,B1,S0,S1,Z);
    initial begin 
    B1=1;A1=0;B0=1;A0=0;S1=0;S0=0;
    #10
    B1=0; A1=1; B0=1; A0=0; S1=1; S0=0;
    #10
    B1=1; A1=0; B0=0; A0=1; S1=0; S0=1;
    #10
    B1=1; A1=1; B0=1; A0=1; S1=1; S0=1;
    #10
    B1=0; A1=0; B0=0; A0=0; S1=0; S0=0;
    #10
    B1=1; A1=1; B0=0; A0=1; S1=0; S0=0;
    #10
    $finish();
    end
endmodule

