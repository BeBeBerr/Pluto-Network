

function [soft_bits,evm] = rx_bpsk_demod(rx_symbols)
evm_real=zeros(1,length(rx_symbols));
evm_image=imag(rx_symbols);
soft_bits = real(rx_symbols); 
for i=1:length(rx_symbols)
    if(soft_bits(i)>0)
        evm_real(i)=soft_bits(i)-1;
        soft_bits(i)=1;
    else
        evm_real(i)=soft_bits(i)-(-1);
        soft_bits(i)=0;
    end    
end
evm=(evm_real.^2+evm_image.^2).^0.5;
evm=sum(evm)/length(evm);


