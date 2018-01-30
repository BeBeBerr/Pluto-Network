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

%strToSend = 'HomePod is a powerful speaker that sounds amazing and adapts to wherever it��s playing. It��s the ultimate music authority, bringing together Apple Music and Siri to learn your taste in music. It��s also an intelligent home assistant, capable of handling everyday tasks �� and controlling your smart home. HomePod takes the listening experience to a whole new level. And that��s just the beginning. We completely reimagined how music should sound in the home. HomePod combines Apple-engineered audio technology and advanced software to deliver the highest-fidelity sound throughout the room, anywhere it��s placed. This elegantly designed, compact speaker totally rocks the house. Setting up HomePod is quick and magical. Simply plug it in and your iOS device will detect it. Equipped with spatial awareness, HomePod automatically adjusts to give you optimal sound �� wherever it��s placed. It can even hear your requests from across the room while loud songs are playing. All you need to do is enjoy your music. HomePod is great at playing your music. But it can also tell you the latest news, traffic, sports, and weather. Set reminders and tasks. Send messages. Hand off phone calls. And HomePod is a hub for controlling your smart home accessories �� from a single light bulb to the whole house �� with just your voice.';
fid = fopen('C:\Users\Berr\Desktop\ok.txt','rb');
bytes = fread(fid);
fclose(fid);
encoder = org.apache.commons.codec.binary.Base64;
strToSend = char(encoder.encode(bytes))';


%��ÿ60���ַ�֮ǰ����3λ֡�����Ϣ  
%֡����Ǵ��ڵ�������1-10
arrLength = ceil(length(strToSend)/57);
sendArray = cell(1,arrLength);
seqNum = 1;
for index = 1:arrLength
    if seqNum < 10
        seqNumStr = ['00', int2str(seqNum)];
    else
        seqNumStr = ['0', int2str(seqNum)];
    end
    if seqNum == 10 
        seqNum = 1;
    else 
        seqNum = seqNum + 1;
    end
    if index*57 > length(strToSend)
        sendArray(index) = {[seqNumStr,strToSend(index*57-56:length(strToSend))]};
    else
        sendArray(index) = {[seqNumStr,strToSend(index*57-56:index*57)]};
    end
end


disp('start sending...');
disp(['totoal packet count: ', int2str(length(sendArray))]);
sendTime = clock;

%��ʼ���� - ��������
%���ڳ���Ϊ5
startIndex = 1; %��sendArray�ϻ������ʹ���
lastSendIndex = 0;
receivedSeqNum = 0;
lastReceivedSeqNum = 0;
roundCount = 0; %��Żع��˼�Ȧ

while startIndex <= length(sendArray)
    isTimeOut = 1;
    while isTimeOut %��ʱ�Զ��ش�
        finishIndex = startIndex + 4;
        if startIndex + 4 > length(sendArray)
            finishIndex = length(sendArray);
        end
        for i = lastSendIndex+1 : finishIndex
            disp(['sending: ', sendArray{i}]);
            txdata = bpsk_tx_func(sendArray{i});
            txdata = round(txdata .* 2^14);
            txdata=repmat(txdata, 8,1);
            input{1} = real(txdata);
            input{2} = imag(txdata);
            writeTxData(s, input); %��������
            lastSendIndex = i;
            pause(0.5);
        end
        t1 = clock;
        isSlide = 0; %�Ƿ񻬶�
        while 1
            if etime(clock, t1) > 10 %��ʱ
                isTimeOut = 1;
                disp('timeOut');
                if ~isSlide
                    lastSendIndex = startIndex - 1;
                end
                break;
            end
            output = readRxData(s);
            I = output{1};
            Q = output{2};
            Rx = I+1i*Q;
            [rStr, crcResult] = bpsk_rx_func(Rx);
            if crcResult == 1
                disp(['receivedSeq: ', rStr]);
                receivedSeqNum = str2num(rStr);
                if receivedSeqNum < lastReceivedSeqNum 
                    roundCount = roundCount + 1;
                end
                startIndex = receivedSeqNum + 1 + 10 * roundCount;
                disp(['startIndex set to: ', int2str(startIndex)]);
                disp(['progress: ', num2str(startIndex/length(sendArray))]);
                
                if lastReceivedSeqNum ~= receivedSeqNum
                    isSlide = 1; %�յ�����ű仯��˵�����ڻ�����
                    isTimeOut = 0;
                    lastReceivedSeqNum = receivedSeqNum;
                    break;
                else
                    isSlide = 0;
                end
            end
        end
    end
end
    
disp('finished.');
timeSpand = etime(clock, sendTime);
disp(['time: ', num2str(timeSpand)]);
disp(['average speed: ', num2str(length(sendArray)*57*8/timeSpand), ' bps']);
            
%������ϣ������ټ�
receivedACK = 0;
for i = 1:10 %����ʮ���ټ�����ʮ�λ�û�л�Ӧ���Լ��ر�
    if(receivedACK == 1)
        break;
    end
    txdata = bpsk_tx_func('BYE');
    txdata = round(txdata .* 2^14);
    txdata=repmat(txdata, 8,1);
    input{1} = real(txdata);
    input{2} = imag(txdata);
    writeTxData(s, input); %�����ټ���Ϣ  
    disp('BYE');
    pause(0.1);
    sendTime = clock;
    while(etime(clock, sendTime) < 10) %δ��ʱ��һֱ�����ظ���ACK
        output = readRxData(s);
        I = output{1};
        Q = output{2};
        Rx = I+1i*Q;
        [rStr, crcResult] = bpsk_rx_func(Rx);
        disp(['received:', rStr]);
        if crcResult == 1 && strcmp(rStr, 'ACK')
            receivedACK = 1; %�յ�ACK �رջỰ
            break;
        end
    end
end

disp('Quit. Bye!');

rssi1 = output{s.getOutChannel('RX1_RSSI')};
s.releaseImpl();





