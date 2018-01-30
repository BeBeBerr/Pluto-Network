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

expectedSeqNum = 0;
lastSeqNum = 0;
while(1)
    output = readRxData(s);
    I = output{1};
    Q = output{2};
    Rx = I+1i*Q;
    [rStr, crcResult] = bpsk_rx_func(Rx);
    disp(['received:',rStr]);
    seq = rStr(1:3);
    if crcResult == 1
        %成功接收到消息，回复收到的帧序号
        strToReply = '0';
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
        if expectedSeqNum == str2num(seq)
            disp(['!!!success received:',rStr]);
            lastSeqNum = expectedSeqNum;
            if expectedSeqNum == 0
                expectedSeqNum = 1;
            else 
                expectedSeqNum = 0;
            end
            strToReply = int2str(str2num(seq));
        else
            strToReply = int2str(lastSeqNum);
        end
            disp(['reply:', strToReply]);
            txdata = bpsk_tx_func(strToReply);
            txdata = round(txdata .* 2^14);
            txdata=repmat(txdata, 8,1);
            input{1} = real(txdata);
            input{2} = imag(txdata);
            writeTxData(s, input);
    end
end













%{

strToSend = 'hello world! This is a testing message, which length is more than 60. It should divide in to several parts, and each part will has 60 characters. Bye!';

arrLength = ceil(length(strToSend)/60);

sendArray = cell(1,arrLength);
for index = 1:arrLength
    if index*60 > length(strToSend)
        sendArray(index) = {strToSend(index*60-59:length(strToSend))};
    else
        sendArray(index) = {strToSend(index*60-59:index*60)};
    end
end

index = 1;

disp('[[sending:]]');
disp(strToSend);
disp('[[receiving:]]');
isSuccess = 0;

    while(1)
        output = readRxData(s);
        %output = stepImpl(s, input);
        %fprintf('Data Block %i Received...\n',currentIndex);
        I = output{1};
        Q = output{2};
        Rx = I+1i*Q;
        [rStr, crcResult] = bpsk_rx_func(Rx);%bpsk_rx_func(Rx(end/2:end));
        seq = rStr(1:3);
        seqNum = str2num(seq);
        if crcResult == 1
            
            isSuccess = 1;
            fprintf(rStr);
            %disp(rStr);
        end
    end 

%{
for currentIndex = 1:length(sendArray)
    %fprintf('txdata number %i ...\n',currentIndex);
    isSuccess = 0;
    while(~isSuccess)
        index = index+1;
        txdata = bpsk_tx_func(sendArray{mod(index, length(sendArray))+1});
        txdata = round(txdata .* 2^14);
        txdata=repmat(txdata, 8,1);
        %fprintf('Transmitting Data Block %i ...\n',currentIndex);
        input{1} = real(txdata);
        input{2} = imag(txdata);
        writeTxData(s, input);
        output = readRxData(s);
        %output = stepImpl(s, input);
        %fprintf('Data Block %i Received...\n',currentIndex);
        I = output{1};
        Q = output{2};
        Rx = I+1i*Q;
        [rStr, crcResult] = bpsk_rx_func(Rx);%bpsk_rx_func(Rx(end/2:end));
        if crcResult == 1
            isSuccess = 1;
            fprintf(rStr);
            %disp(rStr);
        end
        pause(0.1);
    end 
end
%}

%fprintf('Transmission and reception finished\n');

%}

% Read the RSSI attributes of both channels
rssi1 = output{s.getOutChannel('RX1_RSSI')};
% rssi2 = output{s.getOutChannel('RX2_RSSI')};

s.releaseImpl();



