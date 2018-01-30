
function mod_symbols = tx_modulate(bits_in, modulation)

full_len = length(bits_in);

% BPSK modulation
if ~isempty(findstr(modulation, 'BPSK'))
   % Angle [pi/4 -3*pi/4] corresponds to 
   % Gray code vector [0 1], respectively.
   table=exp(j*[0 -pi]);  % generates BPSK symbols
   table=table([1 0]+1); % Gray code mapping pattern for BPSK symbols
   inp=bits_in;
   mod_symbols=table(inp+1);  % maps transmitted bits into BPSK symbols
   
   % QPSK modulation
elseif ~isempty(findstr(modulation, 'QPSK'))
   % Angle [pi/4 3*pi/4 -3*pi/4 -pi/4] corresponds to 
   % Gray code vector [00 10 11 01], respectively.
   table=exp(j*[-3/4*pi 3/4*pi 1/4*pi -1/4*pi]);  % generates QPSK symbols
   table=table([0 1 3 2]+1); % Gray code mapping pattern for QPSK symbols
   inp=reshape(bits_in,2,full_len/2);
   mod_symbols=table([2 1]*inp+1);  % maps transmitted bits into QPSK symbols
   
   % 16-QAM modulation
elseif ~isempty(findstr(modulation, '16QAM'))
   % generates 16QAM symbols
   m=1;
   for k=-3:2:3
      for l=-3:2:3
         table(m) = (k+j*l)/sqrt(10); % power normalization
         m=m+1;
      end;
   end;
   table=table([0 1 3 2 4 5 7 6 12 13 15 14 8 9 11 10]+1); % Gray code mapping pattern for 8-PSK symbols
   inp=reshape(bits_in,4,full_len/4);
   mod_symbols=table([8 4 2 1]*inp+1);  % maps transmitted bits into 16QAM symbols
   
   % 64-QAM modulation
elseif ~isempty(findstr(modulation, '64QAM'))
   % generates 64QAM symbols
   m=1;
   for k=-7:2:7
      for l=-7:2:7
         table(m) = (k+j*l)/sqrt(42); % power normalization
         m=m+1;
      end;
   end;
   table=table([[ 0  1  3  2  7  6  4  5]...
         8+[ 0  1  3  2  7  6  4  5]... 
         24+[ 0  1  3  2  7  6  4  5]...
         16+[ 0  1  3  2  7  6  4  5]...
         56+[ 0  1  3  2  7  6  4  5]...
         48+[ 0  1  3  2  7  6  4  5]...
         32+[ 0  1  3  2  7  6  4  5]...
         40+[ 0  1  3  2  7  6  4  5]]+1);
   
   inp=reshape(bits_in,6,full_len/6);
   
   mod_symbols=table([32 16 8 4 2 1]*inp+1);  % maps transmitted bits into 64QAM symbol
else
   error('Unimplemented modulation');
end



