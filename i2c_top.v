`timescale 1ns / 1ps
module i2c_top(
input clk,rst,start,rw,
input [6:0]slave_addr,
input [1:0]reg_addr,
input [7:0]data_in,
output SCL,busy_slave_1,busy_slave_2,busy_slave_3,busy_master,
output [7:0]data_out_master,
inout SDA
);

wire sda;
pullup(sda);

assign SDA=sda;

i2c_master master (.clk(clk),.rst(rst),.start(start),.rw(rw),.slave_addr(slave_addr),.reg_addr(reg_addr),.data_in(data_in),
.SCL(SCL),.busy_master(busy_master),.data_out(data_out_master),.SDA(sda));

i2c_slave #(.address(7'h4d))slave_1 (.clk(SCL),.rst(rst),.rw(rw),.busy_slave(busy_slave_1),.SDA(sda),.start(start));

i2c_slave #(.address(7'h35))slave_2 (.clk(SCL),.rst(rst),.rw(rw),.busy_slave(busy_slave_2),.SDA(sda),.start(start));

i2c_slave #(.address(7'h62))slave_3 (.clk(SCL),.rst(rst),.rw(rw),.busy_slave(busy_slave_3),.SDA(sda),.start(start));

endmodule
