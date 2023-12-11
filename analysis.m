%% Information
% This script loads and analyses temperature (T) and relative humidity (rh) data
% Uncorrected data (0) as well as data corrected generally (1), seasonally (2) or hourly (3) can be analyzed

% Set modes 
correctionMode = 0;
plotNumber = 13;
title = cell(plotNumber*2, 1);
plottingMode = 2; % 0: no plots, 1: averages by hour, 2: hourly plots with standard deviation, 3: stds, rmses
if exist('beenthere', 'var') == 1
    pauseExecution = 0;
else
    close all
    pauseExecution = 1;
end
plotProfileEnsembles = 0;
saveOutput = 0;
makeTables = 0;
plotQuantiles = 0; 
plotStandardDeviations = 1;
axisLimits = 1;
show23 = 0; %in the overview of dT2, drh2, dT3, drh3, show originals too. 15/27 outdated
%blacklist = [162,250,409,1886,202,450]; %1: 162,250,409,1886. Talvez 1454? ; 2: 202; 3: 450.

%% Preparation
switch correctionMode
    case 0
        load('processedData.mat')
        savesup = '';
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
z3 = [0:100:1000, 1250:250:10000]';
if plottingMode > 0
    colors = get(gca, 'ColorOrder');
end
set(0,'Units', 'Pixels');
screensize = get(0, 'ScreenSize');
ss = screensize(3:4);
format("default")
screen = [0 0];
times = {'0:00'; '6:00'; '12:00'; '15:00'; '18:00'};
timesplus = {'0:00'; '6:00'; '12:00'; '15:00'; '18:00'; 'dry'; 'wet'};

% Add this file's folder to path
folder = fileparts(which(mfilename));
addpath(genpath(folder));

opacity = 0.55;
plot12 = 1:5;
plot3 = [1,2,3,5]; % To not plot the extra afternoon time, which has insufficient data
numplot3 = length(plot3); % Para sim encher a tela na plotagem dos outros horários.
load blacklists_bu.mat

%% Filters and indices
% Find valid profiles by time of day
prefilters12{1} = hours12 >= 23 | hours12 <= 1 & whitelist1bin == 1; %mn (midnight)
prefilters12{2} = hours12 >= 5  & hours12 <= 8 & whitelist1bin == 1; %mg (morning)
prefilters12{3} = hours12 >= 11 & hours12 <= 13 & whitelist1bin == 1; %md (midday)
prefilters12{4} = hours12 >= 14 & hours12 <= 16 & whitelist1bin == 1; %an (afternoon)
prefilters12{5} = hours12 >= 17 & hours12 <= 19 & whitelist1bin == 1; %nt (night)
prefilters12{6} = months12 >= 5 & months12 <= 10 & whitelist1bin == 1; %dry season
prefilters12{7} = months12 <= 4 | months12 >= 11 & whitelist1bin == 1; %wet season
whitelist3bin = ones(1, 1666);
prefilters3{1} = hours3 >= 23 | hours3 <= 1 & whitelist3bin == 1; %mn
prefilters3{2} = hours3 >= 5 & hours3 <= 8 & whitelist3bin == 1; %mg
prefilters3{3} = hours3 >= 11 & hours3 <= 13 & whitelist3bin == 1; %md
prefilters3{4} = hours3 >= 14 & hours3 <= 16 & whitelist3bin == 1; %an
prefilters3{5} = hours3 >= 17 & hours3 <= 19 & whitelist3bin == 1; %nt
prefilters3{6} = months3 >= 5 & months3 <= 10 & whitelist3bin == 1; %dry season
prefilters3{7} = months3 <= 4 | months3 >= 11 & whitelist3bin == 1; %wet season

% Determine filters
filters12{1} = find(prefilters12{1}); %mn, indices
filters12{2} = find(prefilters12{2}); %mg, indices
filters12{3} = find(prefilters12{3}); %md, indices
filters12{4} = find(prefilters12{4}); %td, indices
filters12{5} = find(prefilters12{5}); %nt, indices
filters12{6} = find(prefilters12{6}); %dry, indices
filters12{7} = find(prefilters12{7}); %wet, indices

filters3{1} = find(prefilters3{1}); %mn, indices
filters3{2} = find(prefilters3{2}); %mg, indices
filters3{3} = find(prefilters3{3}); %md, indices
filters3{4} = find(prefilters3{4}); %td, indices
filters3{5} = find(prefilters3{5}); %nt, indices
filters3{6} = find(prefilters3{6}); %dry season, indices
filters3{7} = find(prefilters3{7}); %wet season, indices

wet = [1:4, 11:12];
dry = 5:10;

for i = 1:12
    for j = 1:5
        index = 7 + (i-1) * 5 + j; %jan (mn, mg, md, an, nt), feb (mn, ..,nt), (...), dec (mn, .., nt)
        filters12{index} = find(prefilters12{j} & months12 == i);
        filters3{index} = find(prefilters3{j} & months3 == i);
    end
end

filters12{68} = find(whitelist1bin);
filters3{68} = find(whitelist3bin);

meanz2 = mean(z2, 2); %dit was eerst nanmean, blijft dit goed gaan?

% Find the 2, 7 and 10 km indices for radiometer and reanalysis
for i2km2 = size(meanz2, 1):-1:1
    if meanz2(i2km2) > 2000
        break
    end
end
for i2km7 = size(meanz2, 1):-1:1
    if meanz2(i2km7) > 7000
        break
    end
end
for i2km10 = size(meanz2, 1):-1:1
    if meanz2(i2km10) > 10000
        break
    end
end
i3km2 = 15;
i3km7 = 35;

%% Statistics
% Preallocate memory
N = length(filters12);
%T
meanT1de2 = nan(137, N);
stdT1de2 = nan(137, N);
q1T1de2 = nan(137, N);
q3T1de2 = nan(137, N);
meanstdT1de2 = nan(137, N);
%rh
meanrh1de2 = nan(137, N);
stdrh1de2 = nan(137, N);
q1rh1de2 = nan(137, N);
q3rh1de2 = nan(137, N);
meanstdrh1de2 = nan(137, N);

%T2
meanT2 = nan(137,N);
stdT2 = nan(137, N);
rmseT2 = nan(137, N);
meanstdT2 = nan(137, N);
%rh2
meanrh2 = nan(137, N);
stdrh2 = nan(137, N);
rmserh2 = nan(137, N);
meanstdrh2 = nan(137, N);
%dT2
meandT2 = nan(137, N);
stddT2 = nan(137, N);
q1dT2 = nan(137, N);
q3dT2 = nan(137, N);
meanstddT2 = nan(137, N);
%drh2
meandrh2 = nan(137, N);
stddrh2 = nan(137, N);
q1drh2 = nan(137, N);
q3drh2 = nan(137, N);
meanstddrh2 = nan(137, N);

%T3
meanT1de3 = nan(47, N);
stdT1de3 = nan(47, N);
q1dT3 = nan(47, N);
q3dT3 = nan(47, N);
meanstdT1de3 = nan(47, N);
%rh3
meanrh1de3 = nan(47, N);
stdrh1de3 = nan(47, N);
q1drh3 = nan(47, N);
q3drh3 = nan(47, N);
meanstdrh1de3 = nan(47, N);

meanT3 = nan(47, N);
stdT3 = nan(47, N);
rmseT3 = nan(47, N);
meanstdT3 = nan(47, N);
meanrh3 = nan(47, N);
stdrh3 = nan(47, N);
rmserh3 = nan(47, N);
meanstdrh3 = nan(47, N);
meandT3 = nan(47, N);
stddT3 = nan(47, N);
meanstddT3 = nan(47, N);
meandrh3 = nan(47, N);
stddrh3 = nan(47, N);
meanstddrh3 = nan(47, N);

meanstdT2_010km = nan(1, N);
meanstdrh2_010km = nan(1, N);
meanstdT2_02km = nan(1, N);
meanstdrh2_02km = nan(1, N);
meanstdT2_27km = nan(1, N);
meanstdrh2_27km = nan(1, N);
meanstdT2_710km = nan(1, N);
meanstdrh2_710km = nan(1, N);
meanstdT3_010km = nan(1, N);
meanstdrh3_010km = nan(1, N);
meanstdT3_02km = nan(1, N);
meanstdrh3_02km = nan(1, N);
meanstdT3_27km = nan(1, N);
meanstdrh3_27km = nan(1, N);
meanstdT3_710km = nan(1, N);
meanstdrh3_710km = nan(1, N);

meanT2_010km = nan(1, N);
meanrh2_010km = nan(1, N);
meanT2_02km = nan(1, N);
meanrh2_02km = nan(1, N);
meanT2_27km = nan(1, N);
meanrh2_27km = nan(1, N);
meanT2_710km = nan(1, N);
meanrh2_710km = nan(1, N);
meanT3_010km = nan(1, N);
meanrh3_010km = nan(1, N);
meanT3_02km = nan(1, N);
meanrh3_02km = nan(1, N);
meanT3_27km = nan(1, N);
meanrh3_27km = nan(1, N);
meanT3_710km = nan(1, N);
meanrh3_710km = nan(1, N);

meandT2_010km = nan(1, N);
meandrh2_010km = nan(1, N);
meandT2_02km = nan(1, N);
meandrh2_02km = nan(1, N);
meandT2_27km = nan(1, N);
meandrh2_27km = nan(1, N);
meandT2_710km = nan(1, N);
meandrh2_710km = nan(1, N);
meandT3_010km = nan(1, N);
meandrh3_010km = nan(1, N);
meandT3_02km = nan(1, N);
meandrh3_02km = nan(1, N);
meandT3_27km = nan(1, N);
meandrh3_27km = nan(1, N);
meandT3_710km = nan(1, N);
meandrh3_710km = nan(1, N);

% Calculate errors
dT2 = T2 - T1de2;
drh2 = rh2 - rh1de2;

dT3 = T3 - T1de3;
drh3 = rh3 - rh1de3;

for i = 1:N % N = 5 times, 12 months --> 67
    meanT1de2(:,i) = mean(T1de2(:, filters12{i}), 2, 'omitnan');
    stdT1de2(:,i) = std(T1de2(:, filters12{i}), 0, 2, 'omitnan');
%     q1T1de2(:,i) = quantile(T1de2(:,filtros12{i})',0.25)';
%     q3T1de2(:,i) = quantile(T1de2(:,filtros12{i})',0.75)';
    meanstdT1de2(:,i) = mean(stdT1de2(:,i), 'omitnan');
    meanrh1de2(:,i) = mean(rh1de2(:,filters12{i}),2, 'omitnan');
    stdrh1de2(:,i) = std(rh1de2(:,filters12{i}),0,2, 'omitnan');
%     q1rh1de2(:,i) = quantile(rh1de2(:,filtros12{i})',0.25,2);
%     q3rh1de2(:,i) = quantile(rh1de2(:,filtros12{i})',0.75,2);
    meanstdrh1de2(:,i) = mean(stdrh1de2(:,i), 'omitnan');
    
    meanT2(:,i) = mean(T2(:,filters12{i}),2, 'omitnan');
    stdT2(:,i) = std(T2(:,filters12{i}),0,2, 'omitnan');
    rmseT2(:,i) = sqrt(mean((T2(:,filters12{i})-T1de2(:,filters12{i})).^2,2, 'omitnan'));
    meanstdT2(:,i) = mean(stdT2(:,i), 'omitnan');
    meanrh2(:,i) = mean(rh2(:,filters12{i}),2, 'omitnan');
    stdrh2(:,i) = std(rh2(:,filters12{i}),0,2, 'omitnan');
    rmserh2(:,i) = sqrt(mean((rh2(:,filters12{i})-rh1de2(:,filters12{i})).^2,2, 'omitnan'));
    meanstdrh2(:,i) = mean(stdrh2(:,i), 'omitnan');
    meandT2(:,i) = mean(dT2(:,filters12{i}),2, 'omitnan');
    stddT2(:,i) = std(dT2(:,filters12{i}),0,2, 'omitnan');
    q1dT2(:,i) = quantile(dT2(:,filters12{i})', 0.25, 1)';
    q3dT2(:,i) = quantile(dT2(:,filters12{i})', 0.75)';
    meanstddT2(:,i) = mean(stddT2(:,i), 'omitnan');
    meandrh2(:,i) = mean(drh2(:,filters12{i}),2, 'omitnan');
    stddrh2(:,i) = std(drh2(:,filters12{i}),0,2, 'omitnan');
    q1drh2(:,i) = quantile(drh2(:,filters12{i})', 0.25)';
    q3drh2(:,i) = quantile(drh2(:,filters12{i})', 0.75)';
    meanstddrh2(:,i) = mean(stddrh2(:,i), 'omitnan');
    
    meanT3(:,i) = mean(T3(:,filters3{i}),2, 'omitnan');
    stdT3(:,i) = std(T3(:,filters3{i}),0,2, 'omitnan');
    rmseT3(:,i) = sqrt(mean((T3(:,filters3{i})-T1de3(:,filters3{i})).^2,2, 'omitnan'));
    meanstdT3(:,i) = mean(stdT3(:,i), 'omitnan');
    meanrh3(:,i) = mean(rh3(:,filters3{i}),2, 'omitnan');
    stdrh3(:,i) = std(rh3(:,filters3{i}),0,2, 'omitnan');
    rmserh3(:,i) = sqrt(mean((rh3(:,filters3{i})-rh1de3(:,filters3{i})).^2,2, 'omitnan'));
    meanstdrh3(:,i) = mean(stdrh3(:,i), 'omitnan');
    meandT3(:,i) = mean(dT3(:,filters3{i}),2, 'omitnan');
    stddT3(:,i) = std(dT3(:,filters3{i}),0,2, 'omitnan');
    q1dT3(:,i) = quantile(dT3(:,filters3{i})', 0.25)';
    q3dT3(:,i) = quantile(dT3(:,filters3{i})', 0.75)';
    meanstddT3(:,i) = mean(stddT3(:,i), 'omitnan');
    meandrh3(:,i) = mean(drh3(:,filters3{i}),2, 'omitnan');
    stddrh3(:,i) = std(drh3(:,filters3{i}),0,2, 'omitnan');
    q1drh3(:,i) = quantile(drh3(:,filters3{i})', 0.25)';
    q3drh3(:,i) = quantile(drh3(:,filters3{i})', 0.75)';
    meanstddrh3(:,i) = mean(stddrh3(:,i), 'omitnan');
    
    meanstdT2_010km(i) = mean(stdT2(i2km10:end,i));
    meanstdrh2_010km(i) = mean(stdrh2(i2km10:end,i));
    meanstdT3_010km(i) = mean(stdT3(:,i));
    meanstdrh3_010km(i) = mean(stdrh3(:,i));
    meanstdT2_02km(i) = mean(stdT2(i2km2:end,i));
    meanstdrh2_02km(i) = mean(stdrh2(i2km2:end,i));
    meanstdT2_27km(i) = mean(stdT2(i2km7:i2km2-1,i));
    meanstdrh2_27km(i) = mean(stdrh2(i2km7:i2km2-1,i));
    meanstdT2_710km(i) = mean(stdT2(i2km10:i2km7-1,i));
    meanstdrh2_710km(i) = mean(stdrh2(i2km10:i2km7-1,i));
    meanstdT3_02km(i) = mean(stdT3(1:i3km2,i));
    meanstdrh3_02km(i) = mean(stdrh3(1:i3km2,i));
    meanstdT3_27km(i) = mean(stdT3(i3km2+1:i3km7,i));
    meanstdrh3_27km(i) = mean(stdrh3(i3km2+1:i3km7,i));
    meanstdT3_710km(i) = mean(stdT3(i3km7:end,i));
    meanstdrh3_710km(i) = mean(stdrh3(i3km7:end,i));
    
    meanT2_010km(i) = mean(meanT2(i2km10:end,i),'omitnan');
    meanrh2_010km(i) = mean(meanrh2(i2km10:end,i),'omitnan');
    meanT3_010km(i) = mean(meanT3(:,i),'omitnan');
    meanrh3_010km(i) = mean(meanrh3(:,i),'omitnan');
    meanT2_02km(i) = mean(meanT2(i2km2:end,i),'omitnan');
    meanrh2_02km(i) = mean(meanrh2(i2km2:end,i),'omitnan');
    meanT2_27km(i) = mean(meanT2(i2km7:i2km2-1,i),'omitnan');
    meanrh2_27km(i) = mean(meanrh2(i2km7:i2km2-1,i),'omitnan');
    meanT2_710km(i) = mean(meanT2(i2km10:i2km7-1,i),'omitnan');
    meanrh2_710km(i) = mean(meanrh2(i2km10:i2km7-1,i),'omitnan');
    meanT3_02km(i) = mean(meanT3(1:i3km2,i),'omitnan');
    meanrh3_02km(i) = mean(meanrh3(1:i3km2,i),'omitnan');
    meanT3_27km(i) = mean(meanT3(i3km2+1:i3km7,i),'omitnan');
    meanrh3_27km(i) = mean(meanrh3(i3km2+1:i3km7,i),'omitnan');
    meanT3_710km(i) = mean(meanT3(i3km7:end,i),'omitnan');
    meanrh3_710km(i) = mean(meanrh3(i3km7:end,i),'omitnan');
    
    meandT2_010km(i) = mean(meandT2(i2km10:end,i),'omitnan');
    meandrh2_010km(i) = mean(meandrh2(i2km10:end,i),'omitnan');
    meandT3_010km(i) = mean(meandT3(:,i),'omitnan');
    meandrh3_010km(i) = mean(meandrh3(:,i),'omitnan');
    meandT2_02km(i) = mean(meandT2(i2km2:end,i),'omitnan');
    meandrh2_02km(i) = mean(meandrh2(i2km2:end,i),'omitnan');
    meandT2_27km(i) = mean(meandT2(i2km7:i2km2-1,i),'omitnan');
    meandrh2_27km(i) = mean(meandrh2(i2km7:i2km2-1,i),'omitnan');
    meandT2_710km(i) = mean(meandT2(i2km10:i2km7-1,i),'omitnan');
    meandrh2_710km(i) = mean(meandrh2(i2km10:i2km7-1,i),'omitnan');
    meandT3_02km(i) = mean(meandT3(1:i3km2,i),'omitnan');
    meandrh3_02km(i) = mean(meandrh3(1:i3km2,i),'omitnan');
    meandT3_27km(i) = mean(meandT3(i3km2+1:i3km7,i),'omitnan');
    meandrh3_27km(i) = mean(meandrh3(i3km2+1:i3km7,i),'omitnan');
    meandT3_710km(i) = mean(meandT3(i3km7:end,i),'omitnan');
    meandrh3_710km(i) = mean(meandrh3(i3km7:end,i),'omitnan');    
end
% Find outliers
check = abs(rh1de2 - meanrh1de2(:,68)) ./ stdrh1de2(:,68);
% bl10s1 = find(sum(check > 10)>0);
% disp(bl10s1)

% T1de2(:,filtros12{i}) stdT1de2
% rh2(:,filtros12{i}) stdrh2(70:end,ei)
% T2(:,filtros12{i}) stdT2(70:end,i)
% rh3(:,filtros3{plot3(i)}) stdrh3(2:end,plot3(i))
% return
%% Output
    %% Tables
    if makeTables == 1
        %         times = {'Midnight';'Morning';'Noon';'Afternoon';'Evening'};
        N12 = [sum(prefilters12{1});sum(prefilters12{2});sum(prefilters12{3});sum(prefilters12{4});sum(prefilters12{5})];
        N3 = [sum(prefilters3{1});sum(prefilters3{2});sum(prefilters3{3});sum(prefilters3{4});sum(prefilters3{5})];
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
        if saveOutput == 1
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
        if saveOutput == 1
            table2latex(biases_T2,['/Users/jop/Drive/Werken/Master/Projeto/Dados/Tabelas/biases_T2' savesup])
        end
        
        T2std02 = round(meanstdT2_02km(1:5), 2)';
        T2std27 = round(meanstdT2_27km(1:5), 2)';
        T2std710 = round(meanstdT2_710km(1:5), 2)';
        T2std010 = round(meanstdT2_010km(1:5), 2)';
        std_T2 = table(times, T2std02, T2std27, T2std710);
        if saveOutput == 1
            table2latex(std_T2, ['/Users/jop/Drive/Werken/Master/Projeto/Dados/Tabelas/std_T2' savesup])
        end
        
        rh2bias02 = round(meandrh2_02km(1:5),2)';
        rh2bias27 = round(meandrh2_27km(1:5),2)';
        rh2bias710 = round(meandrh2_710km(1:5),2)';
        rh2bias010 = round(meandrh2_010km(1:5),2)';
        biases_rh2 = table(times,rh2bias02,rh2bias27,rh2bias710);
        if saveOutput == 1
            table2latex(biases_rh2,['/Users/jop/Drive/Werken/Master/Projeto/Dados/Tabelas/biases_rh2' savesup])
        end
        
        rh2std02 = round(meanstdrh2_02km(1:5),2)';
        rh2std27 = round(meanstdrh2_27km(1:5),2)';
        rh2std710 = round(meanstdrh2_710km(1:5),2)';
        rh2std010 = round(meanstdrh2_010km(1:5),2)';
        std_rh2 = table(times,rh2std02,rh2std27,rh2std710);
        if saveOutput == 1
            table2latex(std_rh2,['/Users/jop/Drive/Werken/Master/Projeto/Dados/Tabelas/std_rh2' savesup])
        end
        
        T3bias02 = round(meandT3_02km([1,2,3,5]),2)';
        T3bias27 = round(meandT3_27km([1,2,3,5]),2)';
        T3bias710 = round(meandT3_710km([1,2,3,5]),2)';
        T3bias010 = round(meandT3_010km([1,2,3,5]),2)';
        biases_T3 = table(times([1,2,3,5]),T3bias02,T3bias27,T3bias710);
        if saveOutput == 1
            table2latex(biases_T3,['/Users/jop/Drive/Werken/Master/Projeto/Dados/Tabelas/biases_T3' savesup])
        end

        T3std02 = round(meanstdT3_02km([1,2,3,5]),2)';
        T3std27 = round(meanstdT3_27km([1,2,3,5]),2)';
        T3std710 = round(meanstdT3_710km([1,2,3,5]),2)';
        T3std010 = round(meanstdT3_010km([1,2,3,5]),2)';
        std_T3 = table(times([1,2,3,5]),T3std02,T3std27,T3std710);
        if saveOutput == 1
            table2latex(std_T3,['/Users/jop/Drive/Werken/Master/Projeto/Dados/Tabelas/std_T3' savesup])
        end
        
        rh3bias02 = round(meandrh3_02km([1,2,3,5]),2)';
        rh3bias27 = round(meandrh3_27km([1,2,3,5]),2)';
        rh3bias710 = round(meandrh3_710km([1,2,3,5]),2)';
        rh3bias010 = round(meandrh3_010km([1,2,3,5]),2)';
        biases_rh3 = table(times([1,2,3,5]),rh3bias02,rh3bias27,rh3bias710);
        if saveOutput == 1
            table2latex(biases_rh3,['/Users/jop/Drive/Werken/Master/Projeto/Dados/Tabelas/biases_rh3' savesup])
        end
        
        rh3std02 = round(meanstdrh3_02km([1,2,3,5]),2)';
        rh3std27 = round(meanstdrh3_27km([1,2,3,5]),2)';
        rh3std710 = round(meanstdrh3_710km([1,2,3,5]),2)';
        rh3std010 = round(meanstdrh3_010km([1,2,3,5]),2)';
        std_rh3 = table(times([1,2,3,5]),rh3std02,rh3std27,rh3std710);
        if saveOutput == 1
            table2latex(std_rh3,['/Users/jop/Drive/Werken/Master/Projeto/Dados/Tabelas/std_rh3' savesup])
        end
        
        tabN = table(times,N12,N3);
        tabN2 = table(times,N12,N12);
        tabN3 = table(times,N12,N3);
        if saveOutput == 1 %&& 1 == 0 % Disabled because I edited the table for thesis.tex
            %table2latex(tabN,['/Users/jop/Drive/Werken/Master/Projeto/Dados/Tabelas/tabN' savesup])
            table2latex(tabN2,['/Users/jop/Drive/Werken/Master/Projeto/Dados/Tabelas/tabN2' savesup])
            table2latex(tabN3,['/Users/jop/Drive/Werken/Master/Projeto/Dados/Tabelas/tabN3' savesup])
        end
    end
    %% Plots 
        %% Page 1: averages by hour
    if plottingMode == 1
        n = 11;
        title{n} = 'T1';
        f11 = figure(n);
        set(f11,'Position',[1-screen(1)   410   400   400])
        clf
%         sgtitle('Radiosonde temperature averages by hour')
        xlabel('Temperature (°C)')
        ylabel('Altitude (m)')
        ylim([0 10000])
        hold on
        for i=[1,2,3,4,5]
            plot(meanT1de2(:,i),meanz2,'Color',colors(i,:),'DisplayName',times{i});
            pause
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
        set(f12,'Position',[300-screen(1)   410   400   400])
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
        set(f13,'Position',[600-screen(1) 410 400 400])
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
        set(f14,'Position',[900-screen(1)   410   400   400])
        clf
%         sgtitle('Radiometer temperature time of day averages')
        %         subplot(1,2,1);
        xlabel('Temperature (°C)')
        ylabel('Altitude (m)')
        ylim([0 10000])
        if axisLimits == 1 
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
        set(f15,'Position',[1200-screen(1) 410 400 400])
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
        set(f16,'Position',[1-screen(1)   1+screen(2)   400   400])
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
        set(f17,'Position',[300-screen(1)   1+screen(2)   400   400])
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
        set(f18,'Position',[600-screen(1) 1+screen(2) 400 400])
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
        set(f19,'Position',[900-screen(1)   1+screen(2)   400   400])
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
        set(f20,'Position',[1200-screen(1)   1+screen(2)   400   400])
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
        
        if pauseExecution == 1
            pause(4)
            unix 'osascript /Users/jop/Drive/Organisatie/osascripts/Klein/rightspace.scpt'
        end
    end
        %% Page 2: hourly plots with standard deviation
    if plottingMode == 2
        n=21;
        title{n} = 'T1sd';
        f21 = figure(n); %T1: mn-nt
        set(f21,'Position',[1-screen(1)   410   500   400])
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
            if axisLimits == 1, xlim([-35 35]), end
            ylim([0 10000])
%             t = annotation('textbox','Position',[0.19+(i-1)*0.1630,0.875,0.059,0.044],'String',times(i),'BackgroundColor','white','HorizontalAlignment','center')
            hold on
            grid on
            if (plotProfileEnsembles==1), plot(T1de2(:,filters12{i}),meanz2), end
            plot(meanT1de2(:,i),meanz2,'Color',colors(i,:),'DisplayName','0h');
            if plotQuantiles == 1
                plot(q1T1de2(:,i),meanz2,'Color',colors(i,:),'DisplayName','0h');
                plot(q3T1de2(:,i),meanz2,'Color',colors(i,:),'DisplayName','0h');
            end
            xs = [meanT1de2(70:end,i)'-stdT1de2(70:end,i)' fliplr(meanT1de2(70:end,i)'+stdT1de2(70:end,i)')];
            ys = [meanz2(70:end)' fliplr(meanz2(70:end)')];
            patch(xs,ys,colors(i,:),'EdgeColor','none','DisplayName','±1 std')
            alpha(opacity)
        end
        
        n=22;
        title{n} = 'dT2sd';
        f22 = figure(n); %T2: mn-nt, dT2: mn-nt
        set(f22,'Position',[500-screen(1)   410   500   400])
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
            if axisLimits == 1, xlim([-4 2]), end
            h = line([0 0], [0 10050],'linestyle',':','Color','k');
            h.Annotation.LegendInformation.IconDisplayStyle = 'off';
            t = annotation('textbox','Position',[0.135+(i-1)*0.1632,0.875,0.059,0.044],'String',times(i),'BackgroundColor','white','HorizontalAlignment','center');
            hold on
            grid on
            %legend
            if (plotProfileEnsembles==1), plot(dT2(:,filters12{i}),meanz2), end
            plot(meandT2(:,i),meanz2,'Color',colors(i,:),'DisplayName','0h');
            if plotQuantiles == 1
                plot(q1dT2(:,i),meanz2,'Color',colors(i,:),'DisplayName','0h');
                plot(q3dT2(:,i),meanz2,'Color',colors(i,:),'DisplayName','0h');
            end
            xs = [meandT2(70:end,i)'-stdT2(70:end,i)' fliplr(meandT2(70:end,i)'+stdT2(70:end,i)')];
            ys = [meanz2(70:end)' fliplr(meanz2(70:end)')];
            patch(xs,ys,colors(i,:),'EdgeColor','none','DisplayName','±std')
            alpha(opacity)
        end
        
        n=23;
        title{n} = 'dT3sd';
        f23 = figure(n); %T3: mn-nt, dT3: mn-nt
        set(f23,'Position',[980-screen(1)   410   500   400])
        clf        
        xlabel('Temperature (°C)')
        ylabel('Altitude (m)')
        for i = 1:numplot3
            subplot(1 + show23, numplot3, i + show23 * numplot3);
            if i == 1
                ylabel('Altitude (m)')
            else
                set(gca,'Yticklabel',[])
            end
            xlabel('\DeltaT (°C)')
            ylim([0 10000])
            if axisLimits == 1, xlim([-5 2]), end
            h = line([0 0], [0 10050],'linestyle',':','Color','k');
            h.Annotation.LegendInformation.IconDisplayStyle = 'off';
            t = annotation('textbox','Position',[0.220+(i-1)*0.2068,0.875,0.059,0.044],'String',times(plot3(i)),'BackgroundColor','white','HorizontalAlignment','center');
            hold on
            grid on
            %legend
            if (plotProfileEnsembles==1), plot(dT3(:,filters3{plot3(i)}),z3), end
            plot(meandT3(:,plot3(i)),z3,'Color',colors(plot3(i),:),'DisplayName','0h');
            if plotQuantiles == 1
                plot(q1dT3(:,plot3(i)),z3,'Color',colors(plot3(i),:),'DisplayName','0h');
                plot(q3dT3(:,plot3(i)),z3,'Color',colors(plot3(i),:),'DisplayName','0h');
            end
            xs = [meandT3(2:end,plot3(i))'-stddT3(2:end,plot3(i))' fliplr(meandT3(2:end,plot3(i))'+stddT3(2:end,plot3(i))')];
            ys = [z3(2:end)' fliplr(z3(2:end)')];
            patch(xs,ys,colors(plot3(i),:),'EdgeColor','none','DisplayName','±std')
            alpha(opacity)
        end
        
        n=24;
        title{n} = 'rh1sd';
        f24 = figure(n); %rh1: mn-nt
        set(f24,'Position',[1-screen(1)   1+screen(2)   500   400])
        clf
        %sgtitle('Radiosonde relative humidity by time of day')
        for i = plot12
            subplot(1,5,i);
            if i == 1
                ylabel('Altitude (m)')
            end
            xlabel('RH')
            if axisLimits == 1, xlim([0 1]), end
            ylim([0 10000])
%             t = annotation('textbox','Position',[0.19+(i-1)*0.1630,0.875,0.059,0.044],'String',times(i),'BackgroundColor','white','HorizontalAlignment','center')
            hold on
            grid on
            %legend
            if (plotProfileEnsembles==1), plot(rh1de2(:,filters12{i}),meanz2), end
            plot(meanrh1de2(:,i),meanz2,'Color',colors(i,:),'DisplayName','0h');
            if plotQuantiles == 1
                plot(q1rh1de2(:,i),meanz2,'Color',colors(i,:),'DisplayName','0h');
                plot(q3rh1de2(:,i),meanz2,'Color',colors(i,:),'DisplayName','0h');
            end
            if plotStandardDeviations == 1
                plot(q1rh1de2(:,i),meanz2,'Color',colors(i,:),'DisplayName','0h');
                plot(q3rh1de2(:,i),meanz2,'Color',colors(i,:),'DisplayName','0h');
            end
            xs = [meanrh1de2(70:end,i)'-stdrh1de2(70:end,i)' fliplr(meanrh1de2(70:end,i)'+stdrh1de2(70:end,i)')];
            ys = [meanz2(70:end)' fliplr(meanz2(70:end)')];
            patch(xs,ys,colors(i,:),'EdgeColor','none','DisplayName','±1 std')
            alpha(opacity)
        end
        
        n=25;
        title{n} = 'drh2sd';
        f25 = figure(n); %rh2: mn-nt, drh2: mn-nt
        set(f25,'Position',[500-screen(1)   1+screen(2)   500   400])
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
            if axisLimits == 1, xlim([-0.5 0.5]), end
            h = line([0 0], [0 10050],'linestyle',':','Color','k');
            h.Annotation.LegendInformation.IconDisplayStyle = 'off';
            t = annotation('textbox','Position',[0.135+(i-1)*0.1632,0.875,0.059,0.044],'String',times(i),'BackgroundColor','white','HorizontalAlignment','center');
            hold on
            grid on
            %legend
            if (plotProfileEnsembles==1), plot(drh2(:,filters12{i}),meanz2), end
            plot(meandrh2(:,i),meanz2,'Color',colors(i,:),'DisplayName','0h');
            if plotQuantiles == 1
                plot(q1drh2(:,i),meanz2,'Color',colors(i,:),'DisplayName','0h');
                plot(q3drh2(:,i),meanz2,'Color',colors(i,:),'DisplayName','0h');
            end
            if plotStandardDeviations == 1
                plot(meandrh2(:,i)-stdrh2(:,i),meanz2,'Color',colors(i,:),'DisplayName','0h');
                plot(meandrh2(:,i)+stdrh2(:,i),meanz2,'Color',colors(i,:),'DisplayName','0h');
            end
            xs = [meandrh2(70:end,i)'-stdrh2(70:end,i)' fliplr(meandrh2(70:end,i)'+stdrh2(70:end,i)')];
            ys = [meanz2(70:end)' fliplr(meanz2(70:end)')];
            patch(xs,ys,colors(i,:),'EdgeColor','none','DisplayName','±std')
            alpha(opacity)
        end
        
        n=26;
        title{n} = 'drh3sdX';
        f26 = figure(n); %rh3: mn-nt, drh3: mn-nt
        set(f26,'Position',[980-screen(1)   1+screen(2)   500   400])
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
            if axisLimits == 1, xlim([-0.5 0.5]), end
            h = line([0 0], [0 10050],'linestyle',':','Color','k');
            h.Annotation.LegendInformation.IconDisplayStyle = 'off';
            t = annotation('textbox','Position',[0.215+(i-1)*0.2068,0.875,0.059,0.044],'String',times(plot3(i)),'BackgroundColor','white','HorizontalAlignment','center');
            hold on
            grid on
            if (plotProfileEnsembles==1), plot(drh3(:,filters3{plot3(i)}),z3), end
            plot(meandrh3(:,plot3(i)),z3,'Color',colors(plot3(i),:),'DisplayName','0h');
            if plotQuantiles == 1
                plot(q1drh3(:,plot3(i)),z3,'Color',colors(plot3(i),:),'DisplayName','0h');
                plot(q3drh3(:,plot3(i)),z3,'Color',colors(plot3(i),:),'DisplayName','0h');
            end
            xs = [meandrh3(2:end,plot3(i))'-stddrh3(2:end,plot3(i))' fliplr(meandrh3(2:end,plot3(i))'+stddrh3(2:end,plot3(i))')];
            ys = [z3(2:end)' fliplr(z3(2:end)')];
            patch(xs,ys,colors(plot3(i),:),'EdgeColor','none','DisplayName','±std')
            alpha(opacity)
%             legend(avg)
        end
        
        if pauseExecution == 1
            pause(3)
            unix 'osascript /Users/jop/Drive/Organisatie/osascripts/Klein/rightspace.scpt'
        end   
    end
        %% Page 3: stds, rmses
    if plottingMode == 3
        n=31;
        title{n} = 'T2rmses';
        f31 = figure(100+n);
        hold on
        %f31 = figure('Name','dT2sds','NumberTitle','off');

        set(f31,'Position',[0 1/2 1/4 1/3].*[ss ss])
        if (correctionMode == 0); clf; end
        xlabel('RMSE (˚C)')
        ylabel('Altitude (m)')
        xlim([0 2.5])
        ylim([0 10000])
        hold on
        grid on
        for i=plot12
            a = plot(rmseT2(1:end,i),meanz2,'Color',colors(i,:),'DisplayName',timesplus{i});
            if correctionMode == 0
                a.LineStyle = '--';
                a.HandleVisibility = 'off';
            end
            if correctionMode == 1
                a.LineStyle = '-';
            end
        end
        if (correctionMode == 1)
%             b = plot([-1 -1],'DisplayName',' ','Color','white');
%             b = plot([-1 -1],'Color','black','DisplayName','init.','LineStyle','--');
            b = plot([-1 -1],'Color','black','DisplayName','corr.','LineStyle','-');
        end
        legend
        
        n=32;
        title{n} = 'T3rmses';
        f32 = figure(100+n);
        set(f32,'Position', [1/4 1/2 1/4 1/3] .* [ss ss])
        if (correctionMode == 0); clf; end
        xlabel('RMSE (˚C)')
        ylabel('Altitude (m)')
        xlim([0 3])
        ylim([0 10000])
        hold on
        grid on
        for i=[1,2,3,5]
            a = plot(rmseT3(1:end,i),z3,'Color',colors(i,:),'DisplayName',timesplus{i});
            if correctionMode == 0
                a.LineStyle = '--';
                a.HandleVisibility = 'off';
            end
            if correctionMode == 1
                a.LineStyle = '-';
            end
        end
        if (correctionMode == 1)
%             b = plot([-1 -1],'DisplayName',' ','Color','white');
%             b = plot([-1 -1],'Color','black','DisplayName','init.','LineStyle','--');
            b = plot([-1 -1],'Color','black','DisplayName','corr.','LineStyle','-');
        end
        legend
        
        n=35;
        title{n} = 'rh2rmses';
        f35 = figure(100+n);
        set(f35,'Position',[0 0 1/4 1/3].*[ss ss])
        if (correctionMode == 0); clf; end
        xlabel('RMSE')
        ylabel('Altitude (m)')
        xlim([0 0.35])
        ylim([0 10000])
        hold on
        grid on
        for i=1:5
            a = plot(rmserh2(1:end,i),meanz2,'Color',colors(i,:),'DisplayName',timesplus{i});
            if correctionMode == 0
                a.LineStyle = '--';
                a.HandleVisibility = 'off';
            end
            if correctionMode == 1
                a.LineStyle = '-';
            end
        end
        if (correctionMode == 1)
%             b = plot([-1 -1],'DisplayName',' ','Color','white');
%             b = plot([-1 -1],'Color','black','DisplayName','init.','LineStyle','--');
            b = plot([-1 -1],'Color','black','DisplayName','corr.','LineStyle','-');
        end
        legend
        
        n=36;
        title{n} = 'rh3rmses';
        f36 = figure(100+n);
        set(f36,'Position',[1/4 0 1/4 1/3].*[ss ss])
        if (correctionMode == 0); clf; end
        xlabel('RMSE')
        ylabel('Altitude (m)')
        xlim([0 0.4])
        ylim([0 10000])
        hold on
        grid on
        for i=[1,2,3,5]
            a = plot(rmserh3(1:end,i),z3,'Color',colors(i,:),'DisplayName',timesplus{i});
            if correctionMode == 0
                a.LineStyle = '--';
                a.HandleVisibility = 'off';
            end
            if correctionMode == 1
                a.LineStyle = '-';
            end
        end
        if (correctionMode == 1)
%             b = plot([-1 -1],'DisplayName',' ','Color','white');
%             b = plot([-1 -1],'Color','black','DisplayName','init.','LineStyle','--');
            b = plot([-1 -1],'Color','black','DisplayName','corr.','LineStyle','-');
        end
        legend
    end
    %% Save corrections and figures
    % Save correction by type
    if correctionMode == 0
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
        
        save('correctionValues.mat', 'correction1', 'correction2', 'correction3', 'filters12', 'filters3')
    end
    
    if saveOutput == 1 && plottingMode > 0
        fname = '/Users/jop/Drive/Werken/Master/Projeto/Dados/Figuras';
        if plottingMode == 1
            for loop = 11:20
                filename = ['figure' num2str(loop) '_' title{loop} savesup '.eps'];
                saveas(loop, fullfile(fname, filename), 'epsc');
            end
        end
        if plottingMode == 2
            for loop = 21:26
                filename = ['figure' num2str(loop) '_' title{loop} savesup '.eps'];
                saveas(loop, fullfile(fname, filename), 'epsc');
            end
        end
        if plottingMode == 3
            for loop = [31,32,35,36]
                filename = ['figure' num2str(loop) '_' title{loop} savesup '.eps'];
                saveas(100+loop, fullfile(fname, filename), 'epsc');
            end
        end
    end
%end
beenthere = 0;