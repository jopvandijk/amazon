 %% Modos
modo = 1; %eerst een keer op 0 runnen kennelijk
Np = 13; %Number of plots
title = cell(Np*2,1);
plotar = 3; %0: no plots, 1: averages by hour, 2: hourly plots with standard deviation, 3: stds, rmses
if exist('beenthere','var') == 1
    pausar = 0;
else
    close all
    pausar = 1;
end
enxame = 1;
salvar = 1;
tabelas = 1;
q=0; %whether to show quantiles
r=0; %whether to show std values
f=1; %whether to fixate ranges in ∆T and ∆rh
show23 = 0; %in the overview of dT2, drh2, dT3, drh3, show originals too. 15/27 outdated
%blacklist = [162,250,409,1886,202,450]; %1: 162,250,409,1886. Talvez 1454? ; 2: 202; 3: 450.
%% Preparação
switch modo
    case 0
        load('processedData.mat')
        savesup = ''; %save name supplement
    case 1
        load 'correctedData1.mat'
        savesup = '_cor1';
    case 2
        load('correctedData2.mat')
        savesup = '_cor2';
    case 3
        load('correctedData3.mat')
        savesup = '_cor3';
    otherwise
        error('Oeps')
end
z3 = ncread('/Users/jop/Drive/Werken/Master/Projeto/Dados/maomwrpM1/maomwrpM1.b1.20151129.000919.cdf','height');
if plotar > 0
    colors = get(gca,'ColorOrder');
end
set(0,'Units','Pixels');
screensize = get(0,'ScreenSize');
ss = screensize(3:4);
format
tela = [0 0];
times = {'0:00';'6:00';'12:00';'15:00';'18:00'};
timesplus = {'0:00';'6:00';'12:00';'15:00';'18:00';'dry';'wet'};

% Determine where your m-file's folder is.
folder = fileparts(which(mfilename));
% Add that folder plus all subfolders to the path.
addpath(genpath(folder));
alfa = 0.55; % Para plotear os rmse e std com tinta transparente.
plot12 = 1:5;
plot3 = [1,2,3,5]; % Para não plotear o horário da tarde. Porque não têm dados os suficientes.
numplot3 = length(plot3); % Para sim encher a tela na plotagem dos outros horários.
load blacklists
%% Filtros e índices
% Prefiltros
prefiltros12{1} = horas12>=23 | horas12<=1 & whitelist1bin == 1; %mn (meia-noite)
prefiltros12{2} = horas12>=5 & horas12<=8 & whitelist1bin == 1; %mg (madrugada)
prefiltros12{3} = horas12>=11 & horas12<=13 & whitelist1bin == 1; %md (meio-dia)
prefiltros12{4} = horas12>=14 & horas12<=16 & whitelist1bin == 1; %td (tarde)
prefiltros12{5} = horas12>=17 & horas12<=19 & whitelist1bin == 1; %nt (noite)
prefiltros12{6} = meses12>=5 & meses12<=10 & whitelist1bin == 1; %seca
prefiltros12{7} = meses12<=4 | meses12>=11 & whitelist1bin == 1; %chuvosa
prefiltros3{1} = horas3>=23 | horas3<=1 & whitelist3bin == 1; %mn
prefiltros3{2} = horas3>=5 & horas3<=8 & whitelist3bin == 1; %mg
prefiltros3{3} = horas3>=11 & horas3<=13 & whitelist3bin == 1; %md
prefiltros3{4} = horas3>=14 & horas3<=16 & whitelist3bin == 1; %td
prefiltros3{5} = horas3>=17 & horas3<=19 & whitelist3bin == 1; %nt
prefiltros3{6} = meses3>=5 & meses3<=10 & whitelist3bin == 1; %seca
prefiltros3{7} = meses3<=4 | meses3>=11 & whitelist3bin == 1; %chuvosa

% Filtros
filtros12{1} = find(prefiltros12{1}); %mn, índices
filtros12{2} = find(prefiltros12{2}); %mg, índices
filtros12{3} = find(prefiltros12{3}); %md, índices
filtros12{4} = find(prefiltros12{4}); %td, índices
filtros12{5} = find(prefiltros12{5}); %nt, índices
filtros12{6} = find(prefiltros12{6}); %seca, índices
filtros12{7} = find(prefiltros12{7}); %chuvosa, índices

filtros3{1} = find(prefiltros3{1}); %mn, índices
filtros3{2} = find(prefiltros3{2}); %mg, índices
filtros3{3} = find(prefiltros3{3}); %md, índices
filtros3{4} = find(prefiltros3{4}); %td, índices
filtros3{5} = find(prefiltros3{5}); %nt, índices
filtros3{6} = find(prefiltros3{6}); %seca, índices
filtros3{7} = find(prefiltros3{7}); %chuvosa, índices

chuvosa = [1:4,11:12];
seca = 5:10;

for i = 1:12
    for j = 1:5
        indice = 7+(i-1)*5+j; %jan (mn, mg, md, td, nt), feb (mn, ..,nt), (...), dez(mn, .., nt)
        filtros12{indice} = find(prefiltros12{j} & meses12==i);
        filtros3{indice} = find(prefiltros3{j} & meses3==i);
    end
end

filtros12{68} = find(whitelist1bin);
filtros3{68} = find(whitelist3bin);

% índices
meanz2 = nanmean(z2,2);
%Achar os índices de 2, 7 e 10 km por radiômetro e reanálise
for i2km2 = size(meanz2,1):-1:1
    if meanz2(i2km2)>2000
        break
    end
end
for i2km7 = size(meanz2,1):-1:1
    if meanz2(i2km7)>7000
        break
    end
end
for i2km10 = size(meanz2,1):-1:1
    if meanz2(i2km10)>10000
        break
    end
end
i3km2 = 15;
i3km7 = 35;
%% Análise estatística
N = length(filtros12);
%T
meanT1de2 = nan(137,N);
stdT1de2 = nan(137,N);
q1T1de2 = nan(137,N);
q3T1de2 = nan(137,N);
meanstdT1de2 = nan(137,N);
%rh
meanrh1de2 = nan(137,N);
stdrh1de2 = nan(137,N);
q1rh1de2 = nan(137,N);
q3rh1de2 = nan(137,N);
meanstdrh1de2 = nan(137,N);

%T2
meanT2 = nan(137,N);
stdT2 = nan(137,N);
rmseT2 = nan(137,N);
meanstdT2 = nan(137,N);
%rh2
meanrh2 = nan(137,N);
stdrh2 = nan(137,N);
rmserh2 = nan(137,N);
meanstdrh2 = nan(137,N);
%dT2
meandT2 = nan(137,N);
stddT2 = nan(137,N);
q1dT2 = nan(137,N);
q3dT2 = nan(137,N);
meanstddT2 = nan(137,N);
%drh2
meandrh2 = nan(137,N);
stddrh2 = nan(137,N);
q1drh2 = nan(137,N);
q3drh2 = nan(137,N);
meanstddrh2 = nan(137,N);

%T3
meanT1de3 = nan(47,N);
stdT1de3 = nan(47,N);
q1dT3 = nan(47,N);
q3dT3 = nan(47,N);
meanstdT1de3 = nan(47,N);
%rh3
meanrh1de3 = nan(47,N);
stdrh1de3 = nan(47,N);
q1drh3 = nan(47,N);
q3drh3 = nan(47,N);
meanstdrh1de3 = nan(47,N);

meanT3 = nan(47,N);
stdT3 = nan(47,N);
rmseT3 = nan(47,N);
meanstdT3 = nan(47,N);
meanrh3 = nan(47,N);
stdrh3 = nan(47,N);
rmserh3 = nan(47,N);
meanstdrh3 = nan(47,N);
meandT3 = nan(47,N);
stddT3 = nan(47,N);
meanstddT3 = nan(47,N);
meandrh3 = nan(47,N);
stddrh3 = nan(47,N);
meanstddrh3 = nan(47,N);

meanstdT2_010km = nan(1,N);
meanstdrh2_010km = nan(1,N);
meanstdT2_02km = nan(1,N);
meanstdrh2_02km = nan(1,N);
meanstdT2_27km = nan(1,N);
meanstdrh2_27km = nan(1,N);
meanstdT2_710km = nan(1,N);
meanstdrh2_710km = nan(1,N);
meanstdT3_010km = nan(1,N);
meanstdrh3_010km = nan(1,N);
meanstdT3_02km = nan(1,N);
meanstdrh3_02km = nan(1,N);
meanstdT3_27km = nan(1,N);
meanstdrh3_27km = nan(1,N);
meanstdT3_710km = nan(1,N);
meanstdrh3_710km = nan(1,N);

meanT2_010km = nan(1,N);
meanrh2_010km = nan(1,N);
meanT2_02km = nan(1,N);
meanrh2_02km = nan(1,N);
meanT2_27km = nan(1,N);
meanrh2_27km = nan(1,N);
meanT2_710km = nan(1,N);
meanrh2_710km = nan(1,N);
meanT3_010km = nan(1,N);
meanrh3_010km = nan(1,N);
meanT3_02km = nan(1,N);
meanrh3_02km = nan(1,N);
meanT3_27km = nan(1,N);
meanrh3_27km = nan(1,N);
meanT3_710km = nan(1,N);
meanrh3_710km = nan(1,N);

meandT2_010km = nan(1,N);
meandrh2_010km = nan(1,N);
meandT2_02km = nan(1,N);
meandrh2_02km = nan(1,N);
meandT2_27km = nan(1,N);
meandrh2_27km = nan(1,N);
meandT2_710km = nan(1,N);
meandrh2_710km = nan(1,N);
meandT3_010km = nan(1,N);
meandrh3_010km = nan(1,N);
meandT3_02km = nan(1,N);
meandrh3_02km = nan(1,N);
meandT3_27km = nan(1,N);
meandrh3_27km = nan(1,N);
meandT3_710km = nan(1,N);
meandrh3_710km = nan(1,N);

% Calculate errors
dT2 = T2 - T1de2;
drh2 = rh2 - rh1de2;

dT3 = T3 - T1de3;
drh3 = rh3 - rh1de3;

for i = 1:N % N = 5 times, 12 months --> 67
    meanT1de2(:,i) = nanmean(T1de2(:,filtros12{i}),2);
    stdT1de2(:,i) = nanstd(T1de2(:,filtros12{i}),0,2);
%     q1T1de2(:,i) = quantile(T1de2(:,filtros12{i})',0.25)';
%     q3T1de2(:,i) = quantile(T1de2(:,filtros12{i})',0.75)';
    meanstdT1de2(:,i) = nanmean(stdT1de2(:,i));
    meanrh1de2(:,i) = nanmean(rh1de2(:,filtros12{i}),2);
    stdrh1de2(:,i) = nanstd(rh1de2(:,filtros12{i}),0,2);
%     q1rh1de2(:,i) = quantile(rh1de2(:,filtros12{i})',0.25,2);
%     q3rh1de2(:,i) = quantile(rh1de2(:,filtros12{i})',0.75,2);
    meanstdrh1de2(:,i) = nanmean(stdrh1de2(:,i));
    
    meanT2(:,i) = nanmean(T2(:,filtros12{i}),2);
    stdT2(:,i) = nanstd(T2(:,filtros12{i}),0,2);
    rmseT2(:,i) = sqrt(nanmean((T2(:,filtros12{i})-T1de2(:,filtros12{i})).^2,2));
    meanstdT2(:,i) = nanmean(stdT2(:,i));
    meanrh2(:,i) = nanmean(rh2(:,filtros12{i}),2);
    stdrh2(:,i) = nanstd(rh2(:,filtros12{i}),0,2);
    rmserh2(:,i) = sqrt(nanmean((rh2(:,filtros12{i})-rh1de2(:,filtros12{i})).^2,2));
    meanstdrh2(:,i) = nanmean(stdrh2(:,i));
    meandT2(:,i) = nanmean(dT2(:,filtros12{i}),2);
    stddT2(:,i) = nanstd(dT2(:,filtros12{i}),0,2);
    q1dT2(:,i) = quantile(dT2(:,filtros12{i})',0.25,1)';
    q3dT2(:,i) = quantile(dT2(:,filtros12{i})',0.75)';
    meanstddT2(:,i) = nanmean(stddT2(:,i));
    meandrh2(:,i) = nanmean(drh2(:,filtros12{i}),2);
    stddrh2(:,i) = nanstd(drh2(:,filtros12{i}),0,2);
    q1drh2(:,i) = quantile(drh2(:,filtros12{i})',0.25)';
    q3drh2(:,i) = quantile(drh2(:,filtros12{i})',0.75)';
    meanstddrh2(:,i) = nanmean(stddrh2(:,i));
    
    meanT3(:,i) = nanmean(T3(:,filtros3{i}),2);
    stdT3(:,i) = nanstd(T3(:,filtros3{i}),0,2);
    rmseT3(:,i) = sqrt(nanmean((T3(:,filtros3{i})-T1de3(:,filtros3{i})).^2,2));
    meanstdT3(:,i) = nanmean(stdT3(:,i));
    meanrh3(:,i) = nanmean(rh3(:,filtros3{i}),2);
    stdrh3(:,i) = nanstd(rh3(:,filtros3{i}),0,2);
    rmserh3(:,i) = sqrt(nanmean((rh3(:,filtros3{i})-rh1de3(:,filtros3{i})).^2,2));
    meanstdrh3(:,i) = nanmean(stdrh3(:,i));
    meandT3(:,i) = nanmean(dT3(:,filtros3{i}),2);
    stddT3(:,i) = nanstd(dT3(:,filtros3{i}),0,2);
    q1dT3(:,i) = quantile(dT3(:,filtros3{i})',0.25)';
    q3dT3(:,i) = quantile(dT3(:,filtros3{i})',0.75)';
    meanstddT3(:,i) = nanmean(stddT3(:,i));
    meandrh3(:,i) = nanmean(drh3(:,filtros3{i}),2);
    stddrh3(:,i) = nanstd(drh3(:,filtros3{i}),0,2);
    q1drh3(:,i) = quantile(drh3(:,filtros3{i})',0.25)';
    q3drh3(:,i) = quantile(drh3(:,filtros3{i})',0.75)';
    meanstddrh3(:,i) = nanmean(stddrh3(:,i));
    
    meanstdT2_010km(i) = nanmean(stdT2(i2km10:end,i));
    meanstdrh2_010km(i) = nanmean(stdrh2(i2km10:end,i));
    meanstdT3_010km(i) = nanmean(stdT3(:,i));
    meanstdrh3_010km(i) = nanmean(stdrh3(:,i));
    meanstdT2_02km(i) = nanmean(stdT2(i2km2:end,i));
    meanstdrh2_02km(i) = nanmean(stdrh2(i2km2:end,i));
    meanstdT2_27km(i) = nanmean(stdT2(i2km7:i2km2-1,i));
    meanstdrh2_27km(i) = nanmean(stdrh2(i2km7:i2km2-1,i));
    meanstdT2_710km(i) = nanmean(stdT2(i2km10:i2km7-1,i));
    meanstdrh2_710km(i) = nanmean(stdrh2(i2km10:i2km7-1,i));
    meanstdT3_02km(i) = nanmean(stdT3(1:i3km2,i));
    meanstdrh3_02km(i) = nanmean(stdrh3(1:i3km2,i));
    meanstdT3_27km(i) = nanmean(stdT3(i3km2+1:i3km7,i));
    meanstdrh3_27km(i) = nanmean(stdrh3(i3km2+1:i3km7,i));
    meanstdT3_710km(i) = nanmean(stdT3(i3km7:end,i));
    meanstdrh3_710km(i) = nanmean(stdrh3(i3km7:end,i));
    
    meanT2_010km(i) = nanmean(meanT2(i2km10:end,i));
    meanrh2_010km(i) = nanmean(meanrh2(i2km10:end,i));
    meanT3_010km(i) = nanmean(meanT3(:,i));
    meanrh3_010km(i) = nanmean(meanrh3(:,i));
    meanT2_02km(i) = nanmean(meanT2(i2km2:end,i));
    meanrh2_02km(i) = nanmean(meanrh2(i2km2:end,i));
    meanT2_27km(i) = nanmean(meanT2(i2km7:i2km2-1,i));
    meanrh2_27km(i) = nanmean(meanrh2(i2km7:i2km2-1,i));
    meanT2_710km(i) = nanmean(meanT2(i2km10:i2km7-1,i));
    meanrh2_710km(i) = nanmean(meanrh2(i2km10:i2km7-1,i));
    meanT3_02km(i) = nanmean(meanT3(1:i3km2,i));
    meanrh3_02km(i) = nanmean(meanrh3(1:i3km2,i));
    meanT3_27km(i) = nanmean(meanT3(i3km2+1:i3km7,i));
    meanrh3_27km(i) = nanmean(meanrh3(i3km2+1:i3km7,i));
    meanT3_710km(i) = nanmean(meanT3(i3km7:end,i));
    meanrh3_710km(i) = nanmean(meanrh3(i3km7:end,i));
    
    meandT2_010km(i) = nanmean(meandT2(i2km10:end,i));
    meandrh2_010km(i) = nanmean(meandrh2(i2km10:end,i));
    meandT3_010km(i) = nanmean(meandT3(:,i));
    meandrh3_010km(i) = nanmean(meandrh3(:,i));
    meandT2_02km(i) = nanmean(meandT2(i2km2:end,i));
    meandrh2_02km(i) = nanmean(meandrh2(i2km2:end,i));
    meandT2_27km(i) = nanmean(meandT2(i2km7:i2km2-1,i));
    meandrh2_27km(i) = nanmean(meandrh2(i2km7:i2km2-1,i));
    meandT2_710km(i) = nanmean(meandT2(i2km10:i2km7-1,i));
    meandrh2_710km(i) = nanmean(meandrh2(i2km10:i2km7-1,i));
    meandT3_02km(i) = nanmean(meandT3(1:i3km2,i));
    meandrh3_02km(i) = nanmean(meandrh3(1:i3km2,i));
    meandT3_27km(i) = nanmean(meandT3(i3km2+1:i3km7,i));
    meandrh3_27km(i) = nanmean(meandrh3(i3km2+1:i3km7,i));
    meandT3_710km(i) = nanmean(meandT3(i3km7:end,i));
    meandrh3_710km(i) = nanmean(meandrh3(i3km7:end,i));
    
    %acabou, agora os desvios
    % for i = 1:12
    %     for j = 1:5
    %         indice = 7+(i-1)*5+j;
    %         filtros12{indice} = find(prefiltros12{j} & meses12==i);
    %         filtros3{indice} = find(prefiltros3{j} & meses3==i);
    %     end
    % end
    % meandT2(i) = (meandT2mg+meandT2md+meandT2nt+meandT2mn)/4;
    % meandrh2(i) = (meandrh2mg+meandrh2md+meandrh2nt+meandrh2mn)./4;
    % meandT3(i) = (meandT3mg+meandT3md+meandT3nt+meandT3mn)./4;
    % meandrh3(i) = (meandrh3mg+meandrh3md+meandrh3nt+meandrh3mn)./4;
    %
    % meanbiasT2 = nanmean(meandT2(i2km10:end));
    % meanbiasrh2 = nanmean(meandrh2(i2km10:end));
    % meanbiasT3 = nanmean(meandT3);
    % meanbiasrh3 = nanmean(meandrh3);
    
end
%% Apontar dados errados

check = abs(rh1de2 - meanrh1de2(:,68)) ./ stdrh1de2(:,68);
% bl10s1 = find(sum(check > 10)>0);
% disp(bl10s1)

% T1de2(:,filtros12{i}) stdT1de2
% rh2(:,filtros12{i}) stdrh2(70:end,ei)
% T2(:,filtros12{i}) stdT2(70:end,i)
% rh3(:,filtros3{plot3(i)}) stdrh3(2:end,plot3(i))
% return
%% Output
%for corrections = 1 %1: Ano inteiro. 2: Por estação. 3: Por mês
    %% Tabelas
    if tabelas == 1
        %         times = {'Midnight';'Morning';'Noon';'Afternoon';'Evening'};
        N12 = [sum(prefiltros12{1});sum(prefiltros12{2});sum(prefiltros12{3});sum(prefiltros12{4});sum(prefiltros12{5})];
        N3 = [sum(prefiltros3{1});sum(prefiltros3{2});sum(prefiltros3{3});sum(prefiltros3{4});sum(prefiltros3{5})];
        T2a02km = meanT2_02km(1:5)';
        T2a27km = meanT2_27km(1:5)';
        T2a710km = meanT2_710km(1:5)';
        %         T2a010km = meanT2_010km(1:5)';
        rh2a02km = meanrh2_02km(1:5)';
        rh2a27km = meanrh2_27km(1:5)';
        rh2a710km = meanrh2_710km(1:5)';
        %         rh2a010km = meanrh2_010km(1:5)';
        T3a02km = meanT3_02km(1:5)';
        T3a27km = meanT3_27km(1:5)';
        T3a710km = meanT3_710km(1:5)';
        %         T3a010km = meanT3_010km(1:5)';
        rh3a02km = meanrh3_02km(1:5)';
        rh3a27km = meanrh3_27km(1:5)';
        rh3a710km = meanrh3_710km(1:5)';
        %         rh3a010km = meanrh3_010km(1:5)';
        averages_T2 = table(times,round(T2a02km,2),round(T2a27km,2),round(T2a710km,2));
        averages_rh2 = table(times,round(rh2a02km,2),round(rh2a27km,2),round(rh2a710km,2));
        averages_T3 = table(times,round(T3a02km,2),round(T3a27km,2),round(T3a710km,2));
        averages_rh3 = table(times,round(rh3a02km,2),round(rh3a27km,2),round(rh3a710km,2));
        if salvar == 1
            table2latex(averages_rh2,['/Users/jop/Drive/Werken/Master/Projeto/Dados/Tabelas/averages_rh2' savesup])
            table2latex(averages_T2,['/Users/jop/Drive/Werken/Master/Projeto/Dados/Tabelas/averages_T2' savesup])
            table2latex(averages_T3,['/Users/jop/Drive/Werken/Master/Projeto/Dados/Tabelas/averages_T3' savesup])
            table2latex(averages_rh3,['/Users/jop/Drive/Werken/Master/Projeto/Dados/Tabelas/averages_rh3' savesup])
        end
        
        T2bias02 = round(meandT2_02km(1:5),2)';
        T2bias27 = round(meandT2_27km(1:5),2)';
        T2bias710 = round(meandT2_710km(1:5),2)';
        T2bias010 = round(meandT2_010km(1:5),2)';
        biases_T2 = table(times,T2bias02,T2bias27,T2bias710);
        if salvar == 1
            table2latex(biases_T2,['/Users/jop/Drive/Werken/Master/Projeto/Dados/Tabelas/biases_T2' savesup])
        end
        
        T2std02 = round(meanstdT2_02km(1:5),2)';
        T2std27 = round(meanstdT2_27km(1:5),2)';
        T2std710 = round(meanstdT2_710km(1:5),2)';
        T2std010 = round(meanstdT2_010km(1:5),2)';
        std_T2 = table(times,T2std02,T2std27,T2std710);
        if salvar == 1
            table2latex(std_T2,['/Users/jop/Drive/Werken/Master/Projeto/Dados/Tabelas/std_T2' savesup])
        end
        
        rh2bias02 = round(meandrh2_02km(1:5),2)';
        rh2bias27 = round(meandrh2_27km(1:5),2)';
        rh2bias710 = round(meandrh2_710km(1:5),2)';
        rh2bias010 = round(meandrh2_010km(1:5),2)';
        biases_rh2 = table(times,rh2bias02,rh2bias27,rh2bias710);
        if salvar == 1
            table2latex(biases_rh2,['/Users/jop/Drive/Werken/Master/Projeto/Dados/Tabelas/biases_rh2' savesup])
        end
        
        rh2std02 = round(meanstdrh2_02km(1:5),2)';
        rh2std27 = round(meanstdrh2_27km(1:5),2)';
        rh2std710 = round(meanstdrh2_710km(1:5),2)';
        rh2std010 = round(meanstdrh2_010km(1:5),2)';
        std_rh2 = table(times,rh2std02,rh2std27,rh2std710);
        if salvar == 1
            table2latex(std_rh2,['/Users/jop/Drive/Werken/Master/Projeto/Dados/Tabelas/std_rh2' savesup])
        end
        
        T3bias02 = round(meandT3_02km([1,2,3,5]),2)';
        T3bias27 = round(meandT3_27km([1,2,3,5]),2)';
        T3bias710 = round(meandT3_710km([1,2,3,5]),2)';
        T3bias010 = round(meandT3_010km([1,2,3,5]),2)';
        biases_T3 = table(times([1,2,3,5]),T3bias02,T3bias27,T3bias710);
        if salvar == 1
            table2latex(biases_T3,['/Users/jop/Drive/Werken/Master/Projeto/Dados/Tabelas/biases_T3' savesup])
        end

        T3std02 = round(meanstdT3_02km([1,2,3,5]),2)';
        T3std27 = round(meanstdT3_27km([1,2,3,5]),2)';
        T3std710 = round(meanstdT3_710km([1,2,3,5]),2)';
        T3std010 = round(meanstdT3_010km([1,2,3,5]),2)';
        std_T3 = table(times([1,2,3,5]),T3std02,T3std27,T3std710);
        if salvar == 1
            table2latex(std_T3,['/Users/jop/Drive/Werken/Master/Projeto/Dados/Tabelas/std_T3' savesup])
        end
        
        rh3bias02 = round(meandrh3_02km([1,2,3,5]),2)';
        rh3bias27 = round(meandrh3_27km([1,2,3,5]),2)';
        rh3bias710 = round(meandrh3_710km([1,2,3,5]),2)';
        rh3bias010 = round(meandrh3_010km([1,2,3,5]),2)';
        biases_rh3 = table(times([1,2,3,5]),rh3bias02,rh3bias27,rh3bias710);
        if salvar == 1
            table2latex(biases_rh3,['/Users/jop/Drive/Werken/Master/Projeto/Dados/Tabelas/biases_rh3' savesup])
        end
        
        rh3std02 = round(meanstdrh3_02km([1,2,3,5]),2)';
        rh3std27 = round(meanstdrh3_27km([1,2,3,5]),2)';
        rh3std710 = round(meanstdrh3_710km([1,2,3,5]),2)';
        rh3std010 = round(meanstdrh3_010km([1,2,3,5]),2)';
        std_rh3 = table(times([1,2,3,5]),rh3std02,rh3std27,rh3std710);
        if salvar == 1
            table2latex(std_rh3,['/Users/jop/Drive/Werken/Master/Projeto/Dados/Tabelas/std_rh3' savesup])
        end
        
        tabN = table(times,N12,N3);
        if salvar == 1 && 1 == 0 % Disabled because I edited the table for thesis.tex
            table2latex(tabN,['/Users/jop/Drive/Werken/Master/Projeto/Dados/Tabelas/tabN' savesup])
        end
    end
    %% Plots 
    %% Page 1: averages by hour
    if plotar == 1
        n=11;
        title{n} = 'T1';
        f11 = figure(n);
        set(f11,'Position',[1-tela(1)   410   400   400])
        clf
%         sgtitle('Radiosonde temperature averages by hour')
        xlabel('Temperature (°C)')
        ylabel('Altitude (m)')
        ylim([0 10000])
        hold on
        for i=[1,2,3,4,5]
            plot(meanT1de2(:,i),meanz2,'Color',colors(i,:),'DisplayName',times{i});
        end
        %     % xs = [meanT1de2mg(70:end)'-stdT1de2mg(70:end)' fliplr(meanT1de2mg(70:end)'+stdT1de2mg(70:end)')];
        %     % ys = [meanz2(70:end)' fliplr(meanz2(70:end)')];
        %     % patch(xs,ys,colors(i,:),'EdgeColor','none','DisplayName','±1 std')
        grid on
        alpha(0.1)
        legend
        annotation('textbox', [0.5, 0.825, 0.075, 0.08], 'String', "(a)",'FontSize',18,'BackgroundColor','white','HorizontalAlignment','center')
        
        n=12;
        title{n} = 'T2';
        f12 = figure(n);%T2
        set(f12,'Position',[300-tela(1)   410   400   400])
        clf
%         sgtitle('Reanalysis temperature time of day averages')
        %         subplot(1,2,1);
        xlabel('Temperature (°C)')
        ylabel('Altitude (m)')
        ylim([0 10000])
        %title('Mean temperature')
        hold on
        for i=1:5
            plot(meanT2(:,i),meanz2,'Color',colors(i,:),'DisplayName',times{i});
        end
        grid on
        legend
        annotation('textbox', [0.5, 0.825, 0.075, 0.08], 'String', "(b)",'FontSize',18,'BackgroundColor','white','HorizontalAlignment','center')

        n=13;
        title{n} = 'dT2';
        f13 = figure(n);%dT2
        set(f13,'Position',[600-tela(1) 410 400 400])
        clf
        %         subplot(1,2,2);
        ylim([0 10000])
        %title('Mean difference with sonde')
        xlabel('Difference in temperature (°C)')
        ylabel('Altitude (m)')
        hold on
        for i=1:5
            plot(meandT2(:,i),meanz2,'Color',colors(i,:),'DisplayName',times{i});
        end
        h = line([0 0], [0 10050],'linestyle',':','Color','k');
        h.Annotation.LegendInformation.IconDisplayStyle = 'off';
        grid on
        legend
        annotation('textbox', [0.4, 0.825, 0.075, 0.08], 'String', "(c)",'FontSize',18,'BackgroundColor','white','HorizontalAlignment','center')

        n=14;
        title{n} = 'T3';
        f14 = figure(n);%T3
        set(f14,'Position',[900-tela(1)   410   400   400])
        clf
%         sgtitle('Radiometer temperature time of day averages')
        %         subplot(1,2,1);
        xlabel('Temperature (°C)')
        ylabel('Altitude (m)')
        ylim([0 10000])
        if f == 1 
            xlim([-40 30])
        end
%         sgtitle('Mean temperature')
        hold on
        for i=[1,2,3,5]
            plot(meanT3(:,i),z3,'Color',colors(i,:),'DisplayName',times{i});
        end
        grid on
        legend
        annotation('textbox', [0.5, 0.825, 0.075, 0.08], 'String', "(b)",'FontSize',18,'BackgroundColor','white','HorizontalAlignment','center')

        n=15;
        title{n} = 'dT3';
        f15 = figure(n);%dT3
        set(f15,'Position',[1200-tela(1) 410 400 400])
        clf
        xlim([-3 0.5])
        ylim([0 10000])
%         sgtitle('Mean difference with sonde')
        xlabel('Difference in temperature (°C)')
        ylabel('Altitude (m)')
        hold on
        for i=[1,2,3,5]
            plot(meandT3(:,i),z3,'Color',colors(i,:),'DisplayName',times{i});
        end
        h = line([0 0], [0 10050],'linestyle',':','Color','k');
        h.Annotation.LegendInformation.IconDisplayStyle = 'off';
        grid on
        legend
        annotation('textbox', [0.5, 0.825, 0.075, 0.08], 'String', "(c)",'FontSize',18,'BackgroundColor','white','HorizontalAlignment','center')
        
        n=16;
        title{n} = 'rh1';
        f16 = figure(n);
        set(f16,'Position',[1-tela(1)   1+tela(2)   400   400])
        clf
        %sgtitle('Radiosonde relative humidity averages by hour')
        xlabel('Relative humidity')
        ylabel('Altitude (m)')
        ylim([0 10000])
        hold on
        for i=[1,2,3,4,5]
            plot(meanrh1de2(:,i),meanz2,'Color',colors(i,:),'DisplayName',times{i});
        end
        grid on
        alpha(0.1)
        legend
        annotation('textbox', [0.5, 0.825, 0.075, 0.08], 'String', "(d)",'FontSize',18,'BackgroundColor','white','HorizontalAlignment','center')
        
        n=17;
        title{n} = 'rh2';
        f17 = figure(n);%rh2
        set(f17,'Position',[300-tela(1)   1+tela(2)   400   400])
        clf
        %sgtitle('Reanalysis relative humidity time of day averages')
        %         subplot(1,2,1);
        xlabel('Relative humidity')
        ylabel('Altitude (m)')
        ylim([0 10000])
        xlim([0.3 1])
        %title('Mean relative humidity')
        hold on
        for i=1:5
            plot(meanrh2(:,i),meanz2,'Color',colors(i,:),'DisplayName',times{i});
        end
        grid on
        legend
        annotation('textbox', [0.5, 0.825, 0.075, 0.08], 'String', "(e)",'FontSize',18,'BackgroundColor','white','HorizontalAlignment','center')
        
        n=18;
        title{n} = 'drh2';
        f18 = figure(n);%drh2
        set(f18,'Position',[600-tela(1) 1+tela(2) 400 400])
        clf
        %         subplot(1,2,2);
        ylim([0 10000])
        %title('Mean difference with sonde')
        xlabel('Difference in relative humidity')
        ylabel('Altitude (m)')
        hold on
        for i=1:5
            plot(meandrh2(:,i),meanz2,'Color',colors(i,:),'DisplayName',times{i});
        end
        h = line([0 0], [0 10050],'linestyle',':','Color','k');
        h.Annotation.LegendInformation.IconDisplayStyle = 'off';
        grid on
        legend
        annotation('textbox', [0.5, 0.825, 0.075, 0.08], 'String', "(f)",'FontSize',18,'BackgroundColor','white','HorizontalAlignment','center')
        
        n=19;
        title{n} = 'rh3';
        f19 = figure(n);%rh3
        set(f19,'Position',[900-tela(1)   1+tela(2)   400   400])
        clf
        %sgtitle('Radiometer relative humidity time of day averages')
        ylim([0 10000])
        %title('Mean relative humidity')
        xlabel('Relative humidity')
        ylabel('Altitude (m)')
        hold on
        for i=[1,2,3,5]
            plot(meanrh3(:,i),z3,'Color',colors(i,:),'DisplayName',times{i});
        end
        grid on
        legend
        annotation('textbox', [0.5, 0.825, 0.075, 0.08], 'String', "(e)",'FontSize',18,'BackgroundColor','white','HorizontalAlignment','center')
        
        n=20;
        title{n} = 'drh3';
        f20 = figure(n);%drh3
        set(f20,'Position',[1200-tela(1)   1+tela(2)   400   400])
        clf
        xlim([-0.5 0.2])
        ylim([0 10000])
        %title('Mean difference with sonde')
        xlabel('Difference in relative humidity')
        ylabel('Altitude (m)')
        hold on
        for i=[1,2,3,5]
            plot(meandrh3(:,i),z3,'Color',colors(i,:),'DisplayName',times{i});
        end
        h = line([0 0], [0 10050],'linestyle',':','Color','k');
        h.Annotation.LegendInformation.IconDisplayStyle = 'off';
        grid on
        legend
        annotation('textbox', [0.5, 0.825, 0.075, 0.08], 'String', "(f)",'FontSize',18,'BackgroundColor','white','HorizontalAlignment','center')
        
        if pausar == 1
            pause(4)
            unix 'osascript /Users/jop/Drive/Organisatie/osascripts/Klein/rightspace.scpt'
        end
    end
    %% Page 2: hourly plots with standard deviation
    if plotar == 2
        n=21;
        title{n} = 'T1sd';
        f21 = figure(n); %T1: mn-nt
        set(f21,'Position',[1-tela(1)   410   500   400])
        clf
        %sgtitle('Radiosonde temperature by time of day')
        xlabel('Temperature (°C)')
        ylabel('Altitude (m)')
        for i = plot12
            subplot(1,5,i);
            if i == 1
                ylabel('Altitude (m)')
            end
            xlabel('T (°C)')
            if f == 1, xlim([-35 35]), end
            ylim([0 10000])
%             t = annotation('textbox','Position',[0.19+(i-1)*0.1630,0.875,0.059,0.044],'String',times(i),'BackgroundColor','white','HorizontalAlignment','center')
            hold on
            grid on
            %legend
            if (enxame==1), plot(T1de2(:,filtros12{i}),meanz2), end
            plot(meanT1de2(:,i),meanz2,'Color',colors(i,:),'DisplayName','0h');
            if q == 1
                plot(q1T1de2(:,i),meanz2,'Color',colors(i,:),'DisplayName','0h');
                plot(q3T1de2(:,i),meanz2,'Color',colors(i,:),'DisplayName','0h');
            end
            xs = [meanT1de2(70:end,i)'-stdT1de2(70:end,i)' fliplr(meanT1de2(70:end,i)'+stdT1de2(70:end,i)')];
            ys = [meanz2(70:end)' fliplr(meanz2(70:end)')];
            patch(xs,ys,colors(i,:),'EdgeColor','none','DisplayName','±1 std')
            alpha(alfa)
        end
        
        n=22;
        title{n} = 'dT2sd';
        f22 = figure(n); %T2: mn-nt, dT2: mn-nt
        set(f22,'Position',[500-tela(1)   410   500   400])
        clf
        xlabel('Temperature (°C)')
        ylabel('Altitude (m)')
        for i = plot12
            subplot(1+show23,5,i+show23*5);
            if i == 1
                ylabel('Altitude (m)')
            else
                set(gca,'Yticklabel',[])
            end
            xlabel('\DeltaT (°C)')
            ylim([0 10000])
            if f == 1, xlim([-4 2]), end
            h = line([0 0], [0 10050],'linestyle',':','Color','k');
            h.Annotation.LegendInformation.IconDisplayStyle = 'off';
            t = annotation('textbox','Position',[0.135+(i-1)*0.1632,0.875,0.059,0.044],'String',times(i),'BackgroundColor','white','HorizontalAlignment','center');
            hold on
            grid on
            %legend
            if (enxame==1), plot(dT2(:,filtros12{i}),meanz2), end
            plot(meandT2(:,i),meanz2,'Color',colors(i,:),'DisplayName','0h');
            if q == 1
                plot(q1dT2(:,i),meanz2,'Color',colors(i,:),'DisplayName','0h');
                plot(q3dT2(:,i),meanz2,'Color',colors(i,:),'DisplayName','0h');
            end
            xs = [meandT2(70:end,i)'-stdT2(70:end,i)' fliplr(meandT2(70:end,i)'+stdT2(70:end,i)')];
            ys = [meanz2(70:end)' fliplr(meanz2(70:end)')];
            patch(xs,ys,colors(i,:),'EdgeColor','none','DisplayName','±std')
            alpha(alfa)
        end
        
        n=23;
        title{n} = 'dT3sd';
        f23 = figure(n); %T3: mn-nt, dT3: mn-nt
        set(f23,'Position',[980-tela(1)   410   500   400])
        clf        
        xlabel('Temperature (°C)')
        ylabel('Altitude (m)')
        for i = 1:numplot3
            subplot(1+show23,numplot3,i+show23*numplot3);
            if i == 1
                ylabel('Altitude (m)')
            else
                set(gca,'Yticklabel',[])
            end
            xlabel('\DeltaT (°C)')
            ylim([0 10000])
            if f == 1, xlim([-5 2]), end
            h = line([0 0], [0 10050],'linestyle',':','Color','k');
            h.Annotation.LegendInformation.IconDisplayStyle = 'off';
            t = annotation('textbox','Position',[0.220+(i-1)*0.2068,0.875,0.059,0.044],'String',times(plot3(i)),'BackgroundColor','white','HorizontalAlignment','center');
            hold on
            grid on
            %legend
            if (enxame==1), plot(dT3(:,filtros3{plot3(i)}),z3), end
            plot(meandT3(:,plot3(i)),z3,'Color',colors(plot3(i),:),'DisplayName','0h');
            if q == 1
                plot(q1dT3(:,plot3(i)),z3,'Color',colors(plot3(i),:),'DisplayName','0h');
                plot(q3dT3(:,plot3(i)),z3,'Color',colors(plot3(i),:),'DisplayName','0h');
            end
            xs = [meandT3(2:end,plot3(i))'-stddT3(2:end,plot3(i))' fliplr(meandT3(2:end,plot3(i))'+stddT3(2:end,plot3(i))')];
            ys = [z3(2:end)' fliplr(z3(2:end)')];
            patch(xs,ys,colors(plot3(i),:),'EdgeColor','none','DisplayName','±std')
            alpha(alfa)
        end
        
        n=24;
        title{n} = 'rh1sd';
        f24 = figure(n); %rh1: mn-nt
        set(f24,'Position',[1-tela(1)   1+tela(2)   500   400])
        clf
        %sgtitle('Radiosonde relative humidity by time of day')
        for i = plot12
            subplot(1,5,i);
            if i == 1
                ylabel('Altitude (m)')
            end
            xlabel('RH')
            if f == 1, xlim([0 1]), end
            ylim([0 10000])
%             t = annotation('textbox','Position',[0.19+(i-1)*0.1630,0.875,0.059,0.044],'String',times(i),'BackgroundColor','white','HorizontalAlignment','center')
            hold on
            grid on
            %legend
            if (enxame==1), plot(rh1de2(:,filtros12{i}),meanz2), end
            plot(meanrh1de2(:,i),meanz2,'Color',colors(i,:),'DisplayName','0h');
            if q == 1
                plot(q1rh1de2(:,i),meanz2,'Color',colors(i,:),'DisplayName','0h');
                plot(q3rh1de2(:,i),meanz2,'Color',colors(i,:),'DisplayName','0h');
            end
            if r == 1
                plot(q1rh1de2(:,i),meanz2,'Color',colors(i,:),'DisplayName','0h');
                plot(q3rh1de2(:,i),meanz2,'Color',colors(i,:),'DisplayName','0h');
            end
            xs = [meanrh1de2(70:end,i)'-stdrh1de2(70:end,i)' fliplr(meanrh1de2(70:end,i)'+stdrh1de2(70:end,i)')];
            ys = [meanz2(70:end)' fliplr(meanz2(70:end)')];
            patch(xs,ys,colors(i,:),'EdgeColor','none','DisplayName','±1 std')
            alpha(alfa)
        end
        
        n=25;
        title{n} = 'drh2sd';
        f25 = figure(n); %rh2: mn-nt, drh2: mn-nt
        set(f25,'Position',[500-tela(1)   1+tela(2)   500   400])
        clf
        for i = plot12
            subplot(1+show23,5,i+5*show23);
            if i == 1
                ylabel('Altitude (m)')
            else
                set(gca,'Yticklabel',[])
            end
            xlabel('\DeltaRH')
            ylim([0 10000])
            if f == 1, xlim([-0.5 0.5]), end
            h = line([0 0], [0 10050],'linestyle',':','Color','k');
            h.Annotation.LegendInformation.IconDisplayStyle = 'off';
            t = annotation('textbox','Position',[0.135+(i-1)*0.1632,0.875,0.059,0.044],'String',times(i),'BackgroundColor','white','HorizontalAlignment','center');
            hold on
            grid on
            %legend
            if (enxame==1), plot(drh2(:,filtros12{i}),meanz2), end
            plot(meandrh2(:,i),meanz2,'Color',colors(i,:),'DisplayName','0h');
            if q == 1
                plot(q1drh2(:,i),meanz2,'Color',colors(i,:),'DisplayName','0h');
                plot(q3drh2(:,i),meanz2,'Color',colors(i,:),'DisplayName','0h');
            end
            if r == 1
                plot(meandrh2(:,i)-stdrh2(:,i),meanz2,'Color',colors(i,:),'DisplayName','0h');
                plot(meandrh2(:,i)+stdrh2(:,i),meanz2,'Color',colors(i,:),'DisplayName','0h');
            end
            xs = [meandrh2(70:end,i)'-stdrh2(70:end,i)' fliplr(meandrh2(70:end,i)'+stdrh2(70:end,i)')];
            ys = [meanz2(70:end)' fliplr(meanz2(70:end)')];
            patch(xs,ys,colors(i,:),'EdgeColor','none','DisplayName','±std')
            alpha(alfa)
        end
        
        n=26;
        title{n} = 'drh3sdX';
        f26 = figure(n); %rh3: mn-nt, drh3: mn-nt
        set(f26,'Position',[980-tela(1)   1+tela(2)   500   400])
        clf
        for i = 2%1:numplot3
            subplot(1+show23,numplot3,i+numplot3*show23);
            if i == 1
                ylabel('Altitude (m)')
            else
                set(gca,'Yticklabel',[])
            end
            xlabel('\DeltaRH')
            ylim([0 10000])
            if f == 1, xlim([-0.5 0.5]), end
            h = line([0 0], [0 10050],'linestyle',':','Color','k');
            h.Annotation.LegendInformation.IconDisplayStyle = 'off';
            t = annotation('textbox','Position',[0.215+(i-1)*0.2068,0.875,0.059,0.044],'String',times(plot3(i)),'BackgroundColor','white','HorizontalAlignment','center');
            hold on
            grid on
            if (enxame==1), plot(drh3(:,filtros3{plot3(i)}),z3), end
            plot(meandrh3(:,plot3(i)),z3,'Color',colors(plot3(i),:),'DisplayName','0h');
            if q == 1
                plot(q1drh3(:,plot3(i)),z3,'Color',colors(plot3(i),:),'DisplayName','0h');
                plot(q3drh3(:,plot3(i)),z3,'Color',colors(plot3(i),:),'DisplayName','0h');
            end
            xs = [meandrh3(2:end,plot3(i))'-stddrh3(2:end,plot3(i))' fliplr(meandrh3(2:end,plot3(i))'+stddrh3(2:end,plot3(i))')];
            ys = [z3(2:end)' fliplr(z3(2:end)')];
            patch(xs,ys,colors(plot3(i),:),'EdgeColor','none','DisplayName','±std')
            alpha(alfa)
%             legend(avg)
        end
        
        if pausar == 1
            pause(3)
            unix 'osascript /Users/jop/Drive/Organisatie/osascripts/Klein/rightspace.scpt'
        end   
    end
    %% Page 3: stds, rmses
    if plotar == 3
        n=31;
        title{n} = 'T2rmses';
        f31 = figure(100+n);
        hold on
        %f31 = figure('Name','dT2sds','NumberTitle','off');

        set(f31,'Position',[0 1/2 1/4 1/3].*[ss ss])
        if (modo == 0); clf; end
        xlabel('RMSE (˚C)')
        ylabel('Altitude (m)')
        xlim([0 2.5])
        ylim([0 10000])
        hold on
        grid on
        for i=plot12
            a = plot(rmseT2(1:end,i),meanz2,'Color',colors(i,:),'DisplayName',timesplus{i});
            if modo == 0
                a.LineStyle = '--';
                a.HandleVisibility = 'off';
            end
            if modo == 1
                a.LineStyle = '-';
            end
        end
        if (modo == 1)
            b = plot([-1 -1],'DisplayName',' ','Color','white');
            b = plot([-1 -1],'Color','black','DisplayName','init.','LineStyle','--');
            b = plot([-1 -1],'Color','black','DisplayName','corr.','LineStyle','-');
        end
        legend
        
        n=32;
        title{n} = 'T3rmses';
        f32 = figure(100+n);
        set(f32,'Position',[1/4 1/2 1/4 1/3].*[ss ss])
        if (modo == 0); clf; end
        xlabel('RMSE (˚C)')
        ylabel('Altitude (m)')
        xlim([0 3])
        ylim([0 10000])
        hold on
        grid on
        for i=[1,2,3,5]
            a = plot(rmseT3(1:end,i),z3,'Color',colors(i,:),'DisplayName',timesplus{i});
            if modo == 0
                a.LineStyle = '--';
                a.HandleVisibility = 'off';
            end
            if modo == 1
                a.LineStyle = '-';
            end
        end
        if (modo == 1)
            b = plot([-1 -1],'DisplayName',' ','Color','white');
            b = plot([-1 -1],'Color','black','DisplayName','init.','LineStyle','--');
            b = plot([-1 -1],'Color','black','DisplayName','corr.','LineStyle','-');
        end
        legend
        
        n=35;
        title{n} = 'rh2rmses';
        f35 = figure(100+n);
        set(f35,'Position',[0 0 1/4 1/3].*[ss ss])
        if (modo == 0); clf; end
        xlabel('RMSE')
        ylabel('Altitude (m)')
        xlim([0 0.35])
        ylim([0 10000])
        hold on
        grid on
        for i=1:5
            a = plot(rmserh2(1:end,i),meanz2,'Color',colors(i,:),'DisplayName',timesplus{i});
            if modo == 0
                a.LineStyle = '--';
                a.HandleVisibility = 'off';
            end
            if modo == 1
                a.LineStyle = '-';
            end
        end
        if (modo == 1)
            b = plot([-1 -1],'DisplayName',' ','Color','white');
            b = plot([-1 -1],'Color','black','DisplayName','init.','LineStyle','--');
            b = plot([-1 -1],'Color','black','DisplayName','corr.','LineStyle','-');
        end
        legend
        
        n=36;
        title{n} = 'rh3rmses';
        f36 = figure(100+n);
        set(f36,'Position',[1/4 0 1/4 1/3].*[ss ss])
        if (modo == 0); clf; end
        xlabel('RMSE')
        ylabel('Altitude (m)')
        xlim([0 0.4])
        ylim([0 10000])
        hold on
        grid on
        for i=[1,2,3,5]
            a = plot(rmserh3(1:end,i),z3,'Color',colors(i,:),'DisplayName',timesplus{i});
            if modo == 0
                a.LineStyle = '--';
                a.HandleVisibility = 'off';
            end
            if modo == 1
                a.LineStyle = '-';
            end
        end
        if (modo == 1)
            b = plot([-1 -1],'DisplayName',' ','Color','white');
            b = plot([-1 -1],'Color','black','DisplayName','init.','LineStyle','--');
            b = plot([-1 -1],'Color','black','DisplayName','corr.','LineStyle','-');
        end
        legend
    end
    %% Salvar correções e figuras
    % Salvar correções por tipo de correção
    if modo == 0
        % Correction 1: o perfil vertical
%         correction1.meanz2 = meanz2;
        correction1.T2 = -mean(meandT2(:,plot3),2);
        correction1.rh2 = -mean(meandrh2(:,plot3),2);
        correction1.T3 = -mean(meandT3(:,plot3),2);
        correction1.rh3 = -mean(meandrh3(:,plot3),2);
        
        % Correction 2: o perfil vertical por horário
%         correction2.meanz2 = meanz2;
        correction2.T2 = -meandT2(:,1:5);
        correction2.rh2 = -meandrh2(:,1:5);
        correction2.T3 = -meandT3(:,1:5);
        correction2.rh3 = -meandrh3(:,1:5);
        
        % Correction 3: o perfil vertical por horário e por mes
%         correction3.meanz2 = meanz2;
        correction3.T2 = -meandT2(:,8:67);
        correction3.rh2 = -meandrh2(:,8:67);
        correction3.T3 = -meandT3(:,8:67);
        correction3.rh3 = -meandrh3(:,8:67);
        
        save('correctionValues.mat','correction1','correction2','correction3','filtros12','filtros3')
    end
    % save('sondasdetarde.mat','sondasdetarde','sondasdetarde3')
    
    if salvar == 1 && plotar > 0
        fname = '/Users/jop/Drive/Werken/Master/Projeto/Dados/Figuras';
        if plotar == 1
            for loop = 11:20
                filename = ['figure' num2str(loop) '_' title{loop} savesup '.eps'];
                saveas(loop, fullfile(fname, filename), 'epsc');
            end
        end
        if plotar == 2
            for loop = 21:26
                filename = ['figure' num2str(loop) '_' title{loop} savesup '.eps'];
                saveas(loop, fullfile(fname, filename), 'epsc');
            end
        end
        if plotar == 3
            for loop = [31,32,35,36]
                filename = ['figure' num2str(loop) '_' title{loop} savesup '.eps'];
                saveas(100+loop, fullfile(fname, filename), 'epsc');
            end
        end
    end
%end
beenthere = 0;