`timescale 1ns / 1ps
module i2c_master(
input clk,rst,start,rw,
input [6:0]slave_addr,
input [1:0]reg_addr,
input [7:0]data_in,
output reg SCL,busy_master,
output [7:0]data_out,
inout SDA
);
    
localparam IDLE=5'b00000,
           REST_1=5'b00001,
           ADDR_W=5'b00010,
           ADDR_W_ACK=5'b00011,
           REST_2=5'b00100,
           REG=5'b00101,
           REG_ACK=5'b00110,
           REST_3=5'b00111,
           WRITE_DATA=5'b01000,
           WRITE_ACK=5'b01001,
           REST_4=5'b01010,
           REPEAT_START=5'b01011,
           ADDR_R=5'b01100,
           ADDR_R_ACK=5'b01101,
           REST_5=5'b01110,
           READ_DATA=5'b01111,
           REST_6=5'b10000,
           SEND_NACK=5'b10001,
           EXTRA=5'b10010,
           STOP=5'b10011;
           
reg [4:0]state;
reg [7:0]tx_data_reg;
reg [7:0]slave_addr_reg1;
reg [7:0]slave_addr_reg2;
reg [1:0]reg_addr_reg;
reg [9:0]divider_count;
reg [3:0]bit_count;
reg [7:0]rx_data_reg;
reg sda_en;
wire sda_in;
 
pullup(SDA);
assign SDA = sda_en?0:1'bz;
assign sda_in = SDA;
assign data_out = rx_data_reg;

always @(posedge clk)
begin
if(rst)
   begin
   state<=IDLE;
   busy_master<=0;
   SCL<=1;
   divider_count<=0;
   bit_count<=0;
   sda_en<=0;
   end
else
   begin
   case(state)
   IDLE:begin
        busy_master<=0;
        if(start)
           begin
           state<=REST_1;
           tx_data_reg<=data_in;
           slave_addr_reg1<={slave_addr,1'b0};
           slave_addr_reg2<={slave_addr,1'b1};
           reg_addr_reg<=reg_addr;
           sda_en<=1;
           busy_master<=1;
           end
        end
    REST_1:begin
         if(divider_count == 10'd499)
                   begin
                   SCL<=~SCL;
                   divider_count<=divider_count+1;
                   end 
                else if(divider_count == 10'd999)
                        begin
                        SCL<=~SCL;
                        divider_count<=0;
                        state<=ADDR_W;
                        end
                else
                   divider_count<=divider_count+1;
                end 
    ADDR_W:begin
           if(bit_count == 4'd8)
             begin
             if(divider_count == 10'd999)
                begin
                SCL<=~SCL;
                divider_count<=0;
                state<=ADDR_W_ACK; 
                bit_count<=0;
                end
             else
                divider_count<=divider_count+1;
             end
          else
             begin
             if(divider_count == 10'd499)
                begin
                SCL<=~SCL;
                divider_count<=divider_count+1;
                bit_count<=bit_count+1;
                if(slave_addr_reg1[7] == 0)
                   begin
                   sda_en<=1;
                   bit_count<=bit_count+1;
                   end
                else 
                   begin
                   sda_en<=0;
                   bit_count<=bit_count+1;
                   end
                end
             else if(divider_count == 10'd999)
                  begin
                  SCL<=~SCL;
                  slave_addr_reg1<=slave_addr_reg1<<1;
                  divider_count<=0;
                  end
             else
                 divider_count<=divider_count+1;
             end
          end
      ADDR_W_ACK:begin
               if(divider_count == 10'd499)
                  begin
                  SCL<=~SCL;
                  divider_count<=divider_count+1;
                  end
               else if(divider_count == 10'd999)
                       begin
                       SCL<=~SCL;
                       if(sda_in == 0)
                            begin
                            divider_count<=0;
                            state<=REST_2;
                            end
                       else
                           begin
                           divider_count<=0;
                           state<=STOP;
                           end
                       end
               else
                  divider_count<=divider_count+1;
               end  
       REST_2:begin
                if(divider_count == 10'd499)
                   begin
                   SCL<=~SCL;
                   sda_en<=1;
                   divider_count<=divider_count+1;
                   end 
                else if(divider_count == 10'd999)
                        begin
                        SCL<=~SCL;
                        divider_count<=0;
                        state<=REG;
                        end 
                else
                   divider_count<=divider_count+1;
                end
      REG:begin
          if (bit_count == 4'd2)
              begin
              if(divider_count == 10'd999)
                begin
                SCL<=~SCL;
                divider_count<=0;
                bit_count<=0;
                 state<=REG_ACK;
                end
              else
                divider_count<=divider_count+1;
              end
          else
             begin
             if(divider_count == 10'd499)
                begin
                SCL<=~SCL;
                divider_count<=divider_count+1;
                if(reg_addr_reg[1] == 0)
                   begin
                   sda_en<=1;
                   bit_count<=bit_count+1;
                   end
                else if(reg_addr_reg[1] == 1)
                   begin
                   sda_en<=0;
                   bit_count<=bit_count+1;
                   end 
                end
             else if(divider_count == 10'd999)
                  begin
                  SCL<=~SCL;
                  reg_addr_reg<=reg_addr_reg<<1;
                  divider_count<=0;
                  end
             else
                 divider_count<=divider_count+1;
             end
         end
      REG_ACK:begin
              if(divider_count == 10'd499)
                 begin
                 SCL<=~SCL;
                 divider_count<=divider_count+1;
                 end
              else if(divider_count == 10'd999)
                      begin
                      SCL<=~SCL;
                      divider_count<=0;
                      if(sda_in == 0)
                         begin
                         if(!rw)
                             begin
                             state<=REST_3;
                             end
                         else if(rw)
                                 begin
                                 state<=REST_4;
                                 end
                         end
                     else
                        state<=STOP;
                     end 
              else
                 divider_count<=divider_count+1;
              end   
        REST_3:begin
                if(divider_count == 10'd499)
                   begin
                   SCL<=~SCL;
                   sda_en<=1;
                   divider_count<=divider_count+1;
                   end 
                else if(divider_count == 10'd999)
                        begin
                        SCL<=~SCL;
                        divider_count<=0;
                        state<=WRITE_DATA;
                        end 
                else
                   divider_count<=divider_count+1;
                end
        WRITE_DATA:begin
             if(bit_count == 4'd8)
             begin
             if(divider_count == 10'd999)
                begin
                SCL<=~SCL;
                divider_count<=0;
                state<=WRITE_ACK;
                bit_count<=0;
                end
             else
                divider_count<=divider_count+1;
             end
          else
             begin
             if(divider_count == 10'd499)
                begin
                SCL<=~SCL;
                divider_count<=divider_count+1;
                if(tx_data_reg[7] == 0)
                   begin
                   sda_en<=1;
                   bit_count<=bit_count+1;
                   end 
                else 
                   begin
                   sda_en<=0;
                   bit_count<=bit_count+1;
                   end
                end
             else if(divider_count == 10'd999)
                  begin
                  SCL<=~SCL;
                  tx_data_reg<=tx_data_reg<<1;
                  divider_count<=0;
                  end
             else
                 divider_count<=divider_count+1;
             end   
          end
      WRITE_ACK:begin
                if(divider_count == 10'd499)
                   begin
                   SCL<=~SCL;
                   divider_count<=divider_count+1;
                   end 
                else if(divider_count == 10'd999)
                        begin
                        SCL<=~SCL;
                        divider_count<=0;
                        if(sda_in == 0)
                           begin
                           state<=EXTRA;
                           end
                        end 
                else
                   divider_count<=divider_count+1;
                end
       REST_4:begin
                if(divider_count == 10'd499)
                   begin
                   SCL<=~SCL;
                   sda_en<=1;
                   divider_count<=divider_count+1;
                   end 
                else if(divider_count == 10'd999)
                        begin
                        SCL<=~SCL;
                        divider_count<=0;
                        state<=REPEAT_START;
                        end 
                else
                   divider_count<=divider_count+1;
                end 
      REPEAT_START:begin
                   if(divider_count == 10'd499)
                      begin
                      SCL<=~SCL;
                      sda_en<=0;
                      divider_count<=divider_count+1;
                      end
                   else if(divider_count == 10'd999)
                           begin
                           SCL<=~SCL;
                           sda_en<=1;
                           state<=ADDR_R;
                           divider_count<=0;
                           end
                   else
                      divider_count<=divider_count+1;
                   end
     ADDR_R:begin
           if(bit_count == 4'd8)
             begin
             if(divider_count == 10'd999)
                begin
                SCL<=~SCL;
                divider_count<=0;
                state<=ADDR_R_ACK; 
                bit_count<=0;
                end
             else
                divider_count<=divider_count+1;
             end
          else
             begin
             if(divider_count == 10'd499)
                begin
                SCL<=~SCL;
                divider_count<=divider_count+1;
                bit_count<=bit_count+1;
                if(slave_addr_reg2[7] == 0)
                   begin
                   sda_en<=1;
                   bit_count<=bit_count+1;
                   end
                else 
                   begin
                   sda_en<=0;
                   bit_count<=bit_count+1;
                   end
                end
             else if(divider_count == 10'd999)
                  begin
                  SCL<=~SCL;
                  slave_addr_reg2<=slave_addr_reg2<<1;
                  divider_count<=0;
                  end
             else
                 divider_count<=divider_count+1;
             end
          end
      ADDR_R_ACK:begin
               if(divider_count == 10'd499)
                  begin
                  SCL<=~SCL;
                  divider_count<=divider_count+1;
                  end
               else if(divider_count == 10'd999)
                       begin
                       SCL<=~SCL;
                       if(sda_in == 0)
                            begin
                            divider_count<=0;
                            state<=REST_5;
                            end
                       else
                           begin
                           divider_count<=0;
                           state<=STOP;
                           end
                       end
               else
                  divider_count<=divider_count+1;
               end 
      REST_5:begin
                if(divider_count == 10'd499)
                   begin
                   SCL<=~SCL;
                   divider_count<=divider_count+1;
                   end 
                else if(divider_count == 10'd999)
                        begin
                        SCL<=~SCL;
                        divider_count<=0;
                        state<=READ_DATA;
                        end 
                else
                   divider_count<=divider_count+1;
                end
      READ_DATA:begin
                if(bit_count == 4'd8)
                   begin
                   if(divider_count == 10'd999)
                      begin
                      SCL<=~SCL;
                      divider_count<=0;
                      rx_data_reg[0]<=sda_in;
                      state<=REST_6; 
                      bit_count<=0;
                   end
                else
                   divider_count<=divider_count+1;
                end
                else
                   begin
                if(divider_count == 10'd499)
                   begin
                   SCL<=~SCL;
                   rx_data_reg<=rx_data_reg<<1;
                   divider_count<=divider_count+1;
                   bit_count<=bit_count+1;
                   end
                else if(divider_count == 10'd999)
                        begin
                        SCL<=~SCL;
                        rx_data_reg[0]<=sda_in;
                        divider_count<=0;
                        end 
                else
                   divider_count<=divider_count+1;
                end
              end
        REST_6:begin
                if(divider_count == 10'd499)
                   begin
                   SCL<=~SCL;
                   divider_count<=divider_count+1;
                   end 
                else if(divider_count == 10'd999)
                        begin
                        SCL<=~SCL;
                        divider_count<=0;
                        state<=SEND_NACK;
                        end 
                else
                   divider_count<=divider_count+1;
                end
       SEND_NACK:begin
                 if(divider_count == 10'd499)
                    begin
                    SCL<=~SCL;
                    sda_en<=0;
                    divider_count<=divider_count+1;
                    end
                 else if(divider_count == 10'd999)
                         begin
                         SCL<=~SCL;
                         divider_count<=0;
                         state<=EXTRA;
                         end
                 else
                    divider_count<=divider_count+1;
                 end
           EXTRA:begin
                 if(divider_count == 10'd499)
                    begin
                    SCL<=~SCL;
                    sda_en<=1;
                    divider_count<=divider_count+1;
                    end
                 else if(divider_count == 10'd999)
                         begin
                         SCL<=~SCL;
                         divider_count<=0;
                         state<=STOP;
                         end
                 else
                    divider_count<=divider_count+1;
                 end
           STOP:begin
                busy_master<=0;
                if(divider_count == 10'd499)
                    begin
                    sda_en<=0;
                    divider_count<=divider_count+1;
                    end
                 else if(divider_count == 10'd999)
                         begin
                         divider_count<=0;
                         state<=IDLE;
                         end
                 else
                    divider_count<=divider_count+1;
                 end
       endcase
     end
  end
endmodule
