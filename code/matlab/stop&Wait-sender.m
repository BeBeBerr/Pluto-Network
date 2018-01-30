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
input{s.getInChannel('RX_LO_FREQ')} = 1e9;
input{s.getInChannel('RX_SAMPLING_FREQ')} = 40e6;
input{s.getInChannel('RX_RF_BANDWIDTH')} = 20e6;
input{s.getInChannel('RX1_GAIN_MODE')} = 'manual';%% slow_attack manual
input{s.getInChannel('RX1_GAIN')} = 10;
% input{s.getInChannel('RX2_GAIN_MODE')} = 'slow_attack';
% input{s.getInChannel('RX2_GAIN')} = 0;
input{s.getInChannel('TX_LO_FREQ')} = 2e9;
input{s.getInChannel('TX_SAMPLING_FREQ')} = 40e6;
input{s.getInChannel('TX_RF_BANDWIDTH')} = 20e6;

strToSend = 'We all know that rumor goes very fast from person to person. With the development of Internet, the infor '

%在每60个字符之前插入3位帧序号信息  
arrLength = ceil(length(strToSend)/57);
sendArray = cell(1,arrLength);
seqNum = 0;
for index = 1:arrLength
    seqNumStr = ['00', int2str(seqNum)];
    if seqNum == 0 
        seqNum = 1;
    else 
        seqNum = 0;
    end
    if index*57 > length(strToSend)
        sendArray(index) = {[seqNumStr,strToSend(index*57-56:length(strToSend))]};
    else
        sendArray(index) = {[seqNumStr,strToSend(index*57-56:index*57)]};
    end
end

%开始发送
seqNum = 0;
for index = 1:length(sendArray)
    receivedACK = 0;
    while(~receivedACK) %自动请求重传
        disp(['sending num:', int2str(seqNum), 'context:', sendArray{index}]);
        txdata = bpsk_tx_func(sendArray{index});
        txdata = round(txdata .* 2^14);
        txdata=repmat(txdata, 8,1);
        input{1} = real(txdata);
        input{2} = imag(txdata);
        writeTxData(s, input); %发送数据
        pause(0.1);
        sendTime = clock;
        while(etime(clock, sendTime) < 10) %未超时，一直监听回复的ACK
            output = readRxData(s);
            I = output{1};
            Q = output{2};
            Rx = I+1i*Q;
            [rStr, crcResult] = bpsk_rx_func(Rx);
            disp(['received:', rStr]);
            if crcResult == 1 && strcmp(rStr, int2str(seqNum))
                receivedACK = 1; %收到ACK，准备发送下一条
                break;
            end
        end
    end
    if seqNum == 0
        seqNum = 1;
    else
        seqNum = 0;
    end
end
            
%发送完毕，挥手再见
receivedACK = 0;
for i = 1:10 %发送十次再见，若十次还没有回应，自己关闭
    if(receivedACK == 1)
        break;
    end
    txdata = bpsk_tx_func('BYE');
    txdata = round(txdata .* 2^14);
    txdata=repmat(txdata, 8,1);
    input{1} = real(txdata);
    input{2} = imag(txdata);
    writeTxData(s, input); %发送再见信息  
    disp('BYE');
    pause(0.1);
    sendTime = clock;
    while(etime(clock, sendTime) < 10) %未超时，一直监听回复的ACK
        output = readRxData(s);
        I = output{1};
        Q = output{2};
        Rx = I+1i*Q;
        [rStr, crcResult] = bpsk_rx_func(Rx);
        disp(['received:', rStr]);
        if crcResult == 1 && strcmp(rStr, 'ACK')
            receivedACK = 1; %收到ACK 关闭会话
            break;
        end
    end
end








%{
index = 1;

disp('[[sending:]]');
disp(strToSend);
disp('[[receiving:]]');
while(1)
for currentIndex = 1:length(sendArray)
    %fprintf('txdata number %i ...\n',currentIndex);
    isSuccess = 0;
    %while(~isSuccess)
        index = index+1;
        txdata = bpsk_tx_func(sendArray{mod(index, length(sendArray))+1});
        txdata = round(txdata .* 2^14);
        txdata=repmat(txdata, 8,1);
        %fprintf('Transmitting Data Block %i ...\n',currentIndex);
        input{1} = real(txdata);
        input{2} = imag(txdata);
        writeTxData(s, input);
        %{
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
        %}
        pause(0.1);
    %end 
end
end

%}

%fprintf('Transmission and reception finished\n');

% Read the RSSI attributes of both channels
rssi1 = output{s.getOutChannel('RX1_RSSI')};
% rssi2 = output{s.getOutChannel('RX2_RSSI')};

s.releaseImpl();



