%% Correction 1: the vertical profile
clc
load('processedData.mat') %from processing r.458
load('correctionValues.mat') %from analysis r.930
T2 = T2 + correction1.T2;
rh2 = rh2 + correction1.rh2;
T3 = T3 + correction1.T3;
rh3 = rh3 + correction1.rh3;
save('correctedData1.mat', ...
'times12','horarios12b','times3','months12','months3','hours12','hours3',...
'files1','files2','files3','i12','i3','indices3de2','indices1raw',...
'z1','z2','rh1de2','P1de2','T1de2','P2','q2','q1de2','T2','rh2','P3','T3','rh3','q3','q1de3','rh1de3','T1de3','z3')
% prefiltros12{5} = horas12>=17 & horas12<=19 & whitelist1bin == 1; %nt
% prefiltros12{6} = meses12>=5 & meses12<=10 & whitelist1bin == 1; %seca
% filtros12{5} = find(prefiltros12{5}); %nt, índices
% filtros12{6} = find(prefiltros12{6}); %seca, índices

% for loop = 1:length(correctionValues1)
%     variable = char(correctionValues1(loop));
%     if isfield(data.(nome),variable)
%         correctedData1.(nome).(variable);
%         correction1.(variable);
%         correctedData1.(nome).(variable)=correctedData1.(nome).(variable)+correction1.(variable);
%     end
% end
%interpolate z2, rh2, T2?

%% Correction 2: vertical profile by time of day
load('processedData.mat') %from processing r.458
load('correctionValues.mat') %from analysis r.930
for i=1:5
    T2(:,filtros12{i}) = T2(:,filtros12{i}) + correction2.T2(:,i);
    rh2(:,filtros12{i}) = rh2(:,filtros12{i}) + correction2.rh2(:,i);
    T3(:,filtros3{i}) = T3(:,filtros3{i}) + correction2.T3(:,i);
    rh3(:,filtros3{i}) = rh3(:,filtros3{i}) + correction2.rh3(:,i);
end
save('correctedData2.mat', ...
'times12','horarios12b','times3','months12','months3','hours12','hours3',...
'files1','files2','files3','i12','i3','indices3de2','indices1raw',...
'z1','z2','rh1de2','P1de2','T1de2','P2','q2','q1de2','T2','rh2','P3','T3','rh3','q3','q1de3','rh1de3','T1de3','z3')

% correctionValues2 = fieldnames(correction2);
% correctedData2 = data;
% for loop1 = 1:length(sondas)
%     nome = char(sondas(loop1));
%     datevector = datevec(data.(nome).horario);
%     month = datevector(2);
%     hour = datevector(4);
%     if isinlist(23:24,hour),momento=1;end
%     if isinlist(5:10,hour),momento=2;end
%     if isinlist(11:13,hour),momento=3;end
%     if isinlist(14:16,hour),momento=4;end
%     if isinlist(17:22,hour),momento=5;end
%     
%     for loop2 = 1:length(correctionValues2)
%         variable = char(correctionValues2(loop2));
%         if isfield(data.(nome),variable)
%             correctedData2.(nome).(variable);
%             correction2.(variable)(:,momento);
%             correctedData2.(nome).(variable)=data.(nome).(variable)+correction2.(variable)(:,momento);
%         end
%     end
% end
% %interpolate z2, rh2, T2?

%% Correction 3: vertical profile by time of day per month
load('processedData.mat') %from processing r.458
load('correctionValues.mat') %from analysis r.930
for i=8:67
    T2(:,filtros12{i}) = T2(:,filtros12{i}) + correction3.T2(:,i-7);
    rh2(:,filtros12{i}) = rh2(:,filtros12{i}) + correction3.rh2(:,i-7);
    T3(:,filtros3{i}) = T3(:,filtros3{i}) + correction3.T3(:,i-7);
    rh3(:,filtros3{i}) = rh3(:,filtros3{i}) + correction3.rh3(:,i-7);
end
save('correctedData3.mat', ...
'times12','horarios12b','times3','months12','months3','hours12','hours3',...
'files1','files2','files3','i12','i3','indices3de2','indices1raw',...
'z1','z2','rh1de2','P1de2','T1de2','P2','q2','q1de2','T2','rh2','P3','T3','rh3','q3','q1de3','rh1de3','T1de3','z3')

% T2 = T2 + correction3.T2;
% rh2 = rh2 + correction3.rh2;
% T3 = T3 + correction3.T3;
% rh3 = rh3 + correction3.rh3;
% save('correctedData3.mat', ...
% 'horarios12','horarios12b','horarios3','meses12','meses3','horas12','horas3',...
% 'nomes1','nomes2','nomes3','i12','i3','indices3de2','indices1raw',...
% 'z1','z2','rh1de2','P1de2','T1de2','P2','q2','q1de2','T2','rh2','P3','T3','rh3','q3','q1de3','rh1de3','T1de3','z3')

% correctionValues3 = fieldnames(correction3);
% correctedData3 = data;
% for loop1 = 1:length(sondas)
%     nome = char(sondas(loop1));
%     datevector = datevec(data.(nome).horario);
%     month = datevector(2);
%     hour = datevector(4);
%     if isinlist(23:24,hour),momento=1;end
%     if isinlist(5:10,hour),momento=2;end
%     if isinlist(11:13,hour),momento=3;end
%     if isinlist(14:16,hour),momento=4;end
%     if isinlist(17:22,hour),momento=5;end
%     for loop2 = 1:length(correctionValues3)
%         variable = char(correctionValues3(loop2));
%         if isfield(data.(nome),variable)
%             correctedData3.(nome).(variable)=data.(nome).(variable)+correction3.(variable)(:,(month-1)*5+momento);
%         end
%     end
% end
% %interpolate z2, rh2, T2?

