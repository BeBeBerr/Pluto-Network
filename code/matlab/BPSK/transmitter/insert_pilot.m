function out_signal = insert_pilot(mod_symbols)

Nr=64;

Ns=length(mod_symbols)/Nr;

temp=reshape(mod_symbols,Ns,Nr);
pilot=repmat(ones(1,4),Ns,1);
pilot=[1 -1 1 -1 -1 1 -1 1];
pilot=repmat(pilot,Ns,1);
last=[pilot temp];
last=last.';
bo=last(:).';
% if len_mod ~= 0
%     remain=mod_symbols(end-len_mod+1:end); 
%     out_signal=[bo remain];
% else
    out_signal=bo;
% end

end