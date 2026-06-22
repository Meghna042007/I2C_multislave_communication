`timescale 1ns / 1ps
module i2c_slave#(parameter address = 7'b0110101)(
input clk,rst,rw,start,
output reg busy_slave,
inout SDA
);

localparam IDLE_1=4'b0000,
           START=4'b0001,
           ADDR_W=4'b0010,
           ADDR_W_ACK=4'b0011,
           GET_REG=4'b0100,
           REG_ACK=4'b0101,
           GET_DATA=4'b0110,
           GET_DATA_ACK=4'b0111,
           REST_1=4'b1000,
           REPEATED_START=4'b1001,
           ADDR_R=4'b1010,
           ADDR_R_ACK=4'b1011,
           SEND_DATA=4'b1100,
           GET_NACK=4'b1101;

reg [3:0]state;
reg[7:0]slave_addr_W;
reg [7:0]slave_addr_R;
reg [1:0]reg_addr;
reg [7:0]data_reg[0:2];
reg [7:0]dummy_reg;
reg [3:0] bit_count;
reg sda_en;
wire sda_in;  

pullup(SDA);
assign SDA = sda_en?0:1'bz;
assign sda_in = SDA;

always @(posedge clk)
begin
if(rst)
   begin
   state<=IDLE_1;
   sda_en<=0;
   busy_slave<=0;
   bit_count<=0;
   end
else
   begin
   case(state)
   REPEATED_START:begin
                   if(sda_in == 0 && clk == 1)
                      begin
                      state<=ADDR_R;
                      dummy_reg<=data_reg[reg_addr];
                      end
                   end
       endcase
   end
end

always @(negedge SDA)
   begin
   case(state)
   IDLE_1:begin
          busy_slave<=0;
          if(start)
             begin
             if(sda_in ==0 && clk==1)
                begin
                state<=START;
                busy_slave<=1;
                end 
             end
          end
    endcase
    end   

always @(negedge clk)
begin
   case(state)
   START:begin
        state<=ADDR_W;
        end
    ADDR_W:begin
           if(bit_count == 4'd8)
                  begin
                  if(slave_addr_W[7:1] == address)
                     begin
                     bit_count<=0;
                     state<=ADDR_W_ACK;
                     sda_en<=1;
                     end
                  else
                     begin
                     state<=IDLE_1;
                     busy_slave<=0;
                     sda_en<=0;
                     bit_count<=0;
                     end
                  end
          else
             begin
             slave_addr_W<={slave_addr_W[6:0],sda_in};
             bit_count<=bit_count+1;
             end
          end
     ADDR_W_ACK:begin
                   state<=GET_REG;
                   sda_en<=0;
                end
      GET_REG:begin
              if(bit_count == 4'd2)
                 begin
                 bit_count<=0;
                 sda_en<=1;
                 state<=REG_ACK;
                 end
              else
                 begin
                 sda_en<=0;
                 reg_addr<={reg_addr[0],sda_in};
                 bit_count<=bit_count+1;
                 end
             end 
     REG_ACK:begin
             if(!rw)
                begin
                state<=GET_DATA;
                sda_en<=0;
                end
             else
                begin
                state<=REST_1;
                sda_en<=0;
                end
             end
     GET_DATA:begin
              if(bit_count == 4'd8)
                 begin
                 state<=GET_DATA_ACK;
                 sda_en<=1;
                 bit_count<=0;
                 end
              else
                 begin
                 data_reg[reg_addr]<={data_reg[reg_addr][6:0],sda_in};
                 bit_count<=bit_count+1;
                 end
              end 
      GET_DATA_ACK:begin
                   busy_slave<=0;
                   sda_en<=0;
                   state<=IDLE_1;
                   end
         REST_1:begin
              state<=REPEATED_START;
              end
     ADDR_R:begin
           if(bit_count == 4'd8)
                  begin
                  if(slave_addr_W[7:1] == address)
                     begin
                     bit_count<=0;
                     state<=ADDR_R_ACK;
                     sda_en<=1;
                     end
                  else
                     begin
                     state<=IDLE_1;
                     busy_slave<=0;
                     end
                  end
          else
             begin
             slave_addr_W<={slave_addr_W[6:0],sda_in};
             bit_count<=bit_count+1;
             end
          end
     ADDR_R_ACK:begin
                state<=SEND_DATA;
                sda_en<=1;
                end 
      SEND_DATA:begin
                if(bit_count == 4'd8)
                   begin
                   state<=GET_NACK;
                   bit_count<=0;
                   sda_en<=0;
                   end 
                else
                   begin
                   if(dummy_reg[7]==0)
                   begin
                   sda_en<=1;
                   dummy_reg<=dummy_reg<<1;
                   bit_count<=bit_count+1;
                   end
                   else
                      begin
                      sda_en<=0;
                      dummy_reg<=dummy_reg<<1;
                      bit_count<=bit_count+1;
                      end  
                   end
                end
        GET_NACK:begin
                 if(sda_in == 1)
                    begin
                    busy_slave<=0;
                    state<=IDLE_1;
                    end
                 end
          endcase
       end
endmodule
