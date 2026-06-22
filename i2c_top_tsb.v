`timescale 1ns / 1ps
module i2c_top_tsb();
reg clk,rst,start,rw;
reg [6:0]slave_addr;
reg [1:0]reg_addr;
reg [7:0]data_in;
wire SCL,busy_slave_1,busy_slave_2,busy_slave_3,busy_master;
wire [7:0]data_out_master;
wire SDA;

pullup(SDA);

i2c_top dut (.clk(clk),.rst(rst),.start(start),.rw(rw),.slave_addr(slave_addr),.reg_addr(reg_addr),.data_in(data_in),
.SCL(SCL),.busy_slave_1(busy_slave_1),.busy_slave_2(busy_slave_2),.busy_slave_3(busy_slave_3),.busy_master(busy_master),
.data_out_master(data_out_master),.SDA(SDA));

always #5 clk=~clk;
initial 
begin
clk=0;rst=1;start=0;
repeat(10)@(posedge clk);
rst=0;start=1;slave_addr=7'h35;reg_addr=2'h1;data_in=8'ha6;rw=0;//write a6 to slave 2 register 1
repeat(10)@(posedge clk);                                     
start=0;
repeat(30000)@(posedge clk);
start=1;slave_addr=7'h4d;reg_addr=2'h2;data_in=8'hc5;rw=0;//write c5 to slave 1 register 2
repeat(10)@(posedge clk);
start=0;
repeat(30000)@(posedge clk);
start=1;slave_addr=7'h62;reg_addr=2'h0;data_in=8'hb3;rw=0;//write b3 to slave 3 register 0
repeat(10)@(posedge clk);
start=0;
repeat(30000)@(posedge clk);

start=1;slave_addr=7'h35;reg_addr=2'h1;rw=1;//read from slave 2
repeat(10)@(posedge clk);                                     
start=0;
repeat(50000)@(posedge clk);
start=1;slave_addr=7'h4d;reg_addr=2'h2;rw=1;//read from slave 1
repeat(10)@(posedge clk);
start=0;
repeat(50000)@(posedge clk);
start=1;slave_addr=7'h62;reg_addr=2'h0;rw=1;//read from slave 3
repeat(10)@(posedge clk);
start=0;
repeat(70000)@(posedge clk);
#8000;
$finish;
end
endmodule
