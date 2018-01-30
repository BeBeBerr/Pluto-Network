clearvars -except times;close all;warning off;
set(0,'defaultfigurecolor','w');
addpath ..\..\library
addpath ..\..\library\matlab

ip = '192.168.2.1';
addpath BPSK\transmitter
addpath BPSK\receiver

%% Transmit and Receive using MATLAB libiio

% System Object Configuration
s = iio_sys_obj_matlab; % MATLAB libiio Constructor
s.ip_address = ip;
s.dev_name = 'ad9361';
s.in_ch_no = 2;
s.out_ch_no = 2;
s.in_ch_size = 42568;%length(txdata);
s.out_ch_size = 42568.*8;%length(txdata).*8;

s = s.setupImpl();

input = cell(1, s.in_ch_no + length(s.iio_dev_cfg.cfg_ch));
output = cell(1, s.out_ch_no + length(s.iio_dev_cfg.mon_ch));

% Set the attributes of AD9361
input{s.getInChannel('RX_LO_FREQ')} = 2e9;
input{s.getInChannel('RX_SAMPLING_FREQ')} = 40e6;
input{s.getInChannel('RX_RF_BANDWIDTH')} = 20e6;
input{s.getInChannel('RX1_GAIN_MODE')} = 'manual';%% slow_attack manual
input{s.getInChannel('RX1_GAIN')} = 10;
% input{s.getInChannel('RX2_GAIN_MODE')} = 'slow_attack';
% input{s.getInChannel('RX2_GAIN')} = 0;
input{s.getInChannel('TX_LO_FREQ')} = 1e9;
input{s.getInChannel('TX_SAMPLING_FREQ')} = 40e6;
input{s.getInChannel('TX_RF_BANDWIDTH')} = 20e6;

expectedSeqNum = 1;
allowedSeqNum = 5;
lastRecivedNum = 0;
window = {'','','','',''};
lastSeqNum = 0;
receivedStr = '';
while(1)
    output = readRxData(s);
    I = output{1};
    Q = output{2};
    Rx = I+1i*Q;
    [rStr, crcResult] = bpsk_rx_func(Rx);
    %disp(['received:',rStr]);
    seq = rStr(1:3);
    if crcResult == 1
        %成功接收到消息，回复收到的帧序号
        strToReply = '0';
        disp(['received:',rStr]);
        if seq== 'BYE'
            strToReply = 'ACK';
            txdata = bpsk_tx_func(strToReply);
            txdata = round(txdata .* 2^14);
            txdata=repmat(txdata, 8,1);
            input{1} = real(txdata);
            input{2} = imag(txdata);
            for i = 1:10
                writeTxData(s, input);
                disp('send ack');
                pause(0.1);
            end
            break;
        end
        seq = str2num(seq);
        if expectedSeqNum < allowedSeqNum
            if ((expectedSeqNum <= seq) && (seq<=allowedSeqNum))
                index = seq - expectedSeqNum + 1;
                window{index} =  rStr;
            end
        else
            if (expectedSeqNum <= seq) && (seq <= 10)
                index = seq - expectedSeqNum + 1;
                window{index} =  rStr;
            end
            if (seq>=1) && (seq<=allowedSeqNum)
                index = seq + 11 - expectedSeqNum;
                window{index} = rStr;
            end
        end
        if expectedSeqNum == seq
            for j = 1:5
                if isempty(window{j})
                    expectedSeqNum = expectedSeqNum + j - 1;
                    allowedSeqNum = allowedSeqNum + j - 1;
                    lastRecivedNum = str2num(window{j-1}(1:3));
                    if expectedSeqNum>10
                        expectedSeqNum = expectedSeqNum - 10;
                    end
                    if allowedSeqNum>10
                        allowedSeqNum = allowedSeqNum - 10;
                    end
                    tempWindow={'','','','',''};
                    if j== 5
                        window= tempWindow;
                    else
                        for m = j:5
                            tempWindow{m-j+1}=window{m};
                        end
                        window = tempWindow;
                    end
                    break
                end
                disp(['!!!success received:',window{j}]); 
                receivedStr = [receivedStr, window{j}(4:end)];
                if j==5 && ~isempty(window{j})
                    lastRecivedNum = str2num(window{j}(1:3));
                    
                    window = {'','','','',''};
                    expectedSeqNum = expectedSeqNum + 5;
                    allowedSeqNum = allowedSeqNum +5;
                    if expectedSeqNum>10
                        expectedSeqNum = expectedSeqNum -10;
                    end
                    if allowedSeqNum>10
                        allowedSeqNum = allowedSeqNum - 10;
                    end
                end
                
            end
            disp(['i receive', num2str(lastRecivedNum)]);
            strToReply = num2str(lastRecivedNum);
            txdata = bpsk_tx_func(strToReply);
            txdata = round(txdata .* 2^14);
            txdata=repmat(txdata, 8,1);
            input{1} = real(txdata);
            input{2} = imag(txdata);
            writeTxData(s, input);
        else
        strToReply = num2str(lastRecivedNum);
        txdata = bpsk_tx_func(strToReply);
        txdata = round(txdata .* 2^14);
        txdata=repmat(txdata, 8,1);
        input{1} = real(txdata);
        input{2} = imag(txdata);
        disp(['i receive ', num2str(lastRecivedNum)]);
        writeTxData(s, input);
        end
    end
end

disp(receivedStr);
file = matlab.net.base64decode(receivedStr);
fid = fopen('received', 'wb+');
if fid>0
    fwrite(fid, file);
end
fclose(fid);
% Read the RSSI attributes of both channels
rssi1 = output{s.getOutChannel('RX1_RSSI')};
% rssi2 = output{s.getOutChannel('RX2_RSSI')};

s.releaseImpl();
