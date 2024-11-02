`include "uvm_macros.svh"
import uvm_pkg::*;
module tb_top;
  

  parameter START_ADDR='h200;
  parameter SIZE='h800;
  parameter OUT_OF_ORDER_RSP_EN=1;

  logic clk;
  logic rstn;
  logic [15:0] addr;
  logic wr;
  logic valid;
  logic [3:0] wdata;
  logic wresp;
  logic wresp_valid;
  logic [3:0] rdata;
  logic rvalid;
  logic rresp;
  logic [1:0] request_id;
  logic [1:0] response_id;
    
  cache#(START_ADDR,SIZE,OUT_OF_ORDER_RSP_EN) cache_inst(.*);

  initial begin
    clk<=0;
    forever begin
      #5ns clk<=~clk;
    end
  end

  initial begin
    rstn<=0;
    #20ns rstn<=1;
  end
  
  initial begin
    #40ns;
    @(posedge clk);
    addr<='h400;
    wr<=1;
    wdata<='hA;
    valid<=1;
    request_id<='h3;
    @(posedge clk);
    addr<='h600;
    wr<=1;
    wdata<='hB;
    valid<=1;
    request_id<='h2;
    @(posedge clk);
    addr<='h800;
    wr<=1;
    wdata<='hC;
    valid<=1;
    request_id<='h1;    
    do begin
      @(posedge clk);
      valid<=0;      
    end while(!wresp_valid);
    $display("WRITE1: RSP: 'h%0h RSP-ID: 'h%0h",wresp,response_id);
    do begin
      @(posedge clk);
      valid<=0;      
    end while(!wresp_valid);
    $display("WRITE2: RSP: 'h%0h RSP-ID: 'h%0h",wresp,response_id);     do begin
      @(posedge clk);
      valid<=0;      
    end while(!wresp_valid);
    $display("WRITE3: RSP: 'h%0h RSP-ID: 'h%0h",wresp,response_id);  
    @(posedge clk);
    addr<='h400;
    wr<=0;
    valid<=1;
    request_id<='h2;
    do begin
      @(posedge clk);
      valid<=0;      
    end while(!rvalid);
    $display("READ: RSP: 'h%0h, DATA: 'h%0h, RSP-ID: 'h%0h",rresp,rdata,response_id);
    #20ns;
    $finish();
  end

endmodule
