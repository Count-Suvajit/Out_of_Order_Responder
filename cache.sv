`include "uvm_macros.svh"
import uvm_pkg::*;
module cache#(
  parameter START_ADDR = 0,
  parameter SIZE = 'h100,
  parameter OUT_OF_ORDER_RSP_EN = 1
)
(
  input logic clk,
  input logic rstn,
  input logic [15:0] addr,
  input logic wr,
  input logic valid,
  input logic [3:0] wdata,
  input logic [1:0] request_id,
  output logic wresp,
  output logic wresp_valid,
  output logic [3:0] rdata,
  output logic rvalid,
  output logic rresp,
  output logic [1:0] response_id
);
  
  bit [3:0] mem[bit[15:0]];
  
  bit [22:0] req_q[$]; //access_id+wr+data+addr
  bit [7:0] rsp_q[$]; //access_id+wr+resp+data
  
  bit [1:0] ongoing_xact_stage;
  
  bit [7:0] cnt;
  
  always @(posedge clk, negedge rstn) begin
    if(rstn==1) begin
      if(valid) begin
        req_q.push_back((request_id<<21)+(wr<<20)+(wdata<<16)+addr);
      end
    end
    else begin
      wresp = 0;
      wresp_valid = 0;
      rdata = 0;
      rresp = 0;
      rvalid = 0;
      response_id = 0;
      ongoing_xact_stage = 0;
    end
  end
  
  always @(posedge clk, negedge rstn) begin
    if(rstn==1) begin
      if(req_q.size>0 && ((!OUT_OF_ORDER_RSP_EN) || cnt>20)) begin
        if(OUT_OF_ORDER_RSP_EN) begin
          cnt=0;
          req_q.shuffle();
        end
        if(req_q[0][20]) begin //wr=1
          if(req_q[0][15:0]>=START_ADDR && req_q[0][15:0]<(START_ADDR+SIZE)) begin
            mem[req_q[0][15:0]] = req_q[0][19-:4];
            rsp_q.push_back((req_q[0][22:21]<<6)|(1<<5));
            $display("DBG1");
          end
          else begin
            rsp_q.push_back((req_q[0][22:21]<<6)|(1<<5)|(1<<4));
            $display("DBG2, 'h%0h", req_q[0][15:0]);
          end
        end
        else begin //wr=0
          if(req_q[0][15:0]>=START_ADDR && req_q[0][15:0]<(START_ADDR+SIZE)) begin
            rsp_q.push_back((req_q[0][22:21]<<6)|(mem[req_q[0][15:0]]));
          end
          else begin
            rsp_q.push_back((req_q[0][22:21]<<6)|(1<<4));
          end          
        end
        void'(req_q.pop_front());
      end
      else if(req_q.size>0) begin
        cnt+=1;
      end
    end
    else begin
      req_q.delete();
    end
  end
  
  always @(posedge clk, negedge rstn) begin
    if(rstn == 1) begin
      if(rsp_q.size>0 && ongoing_xact_stage==0) begin
        ongoing_xact_stage = 1;
        $display("STAGE0");
      end
      else if(ongoing_xact_stage==1) begin
        ongoing_xact_stage = 2;
        $display("STAGE1");        
        if(rsp_q[0][5]) begin //wr=1
          wresp_valid = 1;
          wresp = rsp_q[0][4];
          response_id = rsp_q[0][7:6];
        end
        else begin //wr=0
          rvalid = 1;
          rresp = rsp_q[0][4];
          rdata = rsp_q[0][3:0];
          response_id = rsp_q[0][7:6];          
        end
      end
      else if(ongoing_xact_stage==2) begin
        ongoing_xact_stage=0;
        $display("STAGE2");        
        if(rsp_q[0][5]) begin //wr=1
          wresp_valid = 0;
          wresp = 0;
          response_id = 0;
        end
        else begin //wr=0
          rvalid = 0;
          rresp = 0;
          rdata = 0;
          response_id = 0;
        end
        void'(rsp_q.pop_front());              
      end
    end
    else begin
      rsp_q.delete();
    end
  end

endmodule
