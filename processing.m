    %% Modos
tic
calcularblacklist = 1; %r.49
firsttime=1; % If first time, filenames will be saved
calcular = 1;
%% Informação
% numeração: 1. radiossonda. 2. reanálise. 3. radiômetro
% 1. quatro sondes/files por dia por dois anos. cada 30s(?) um snapshot.
% ±quantos por sonda então?
% 2. um file por mes por 51 meses com cada hora um conjunto de dados. 137 níveis.
% 3. um file por dia por 416 dias com um conjunto de dados por minuto. 47 níveis.
% datas disponíveis: 1. 17/12/2013 - 30/11/2015. 2. 4/10/2013 - 1/12/2017. 3. 09/10/2014 - 29/11/2015.
% Tem 2912 sondas. A primeira com radiômetro é 1244.
% Intense operational period: 2014 fev-março e set-out.
%% Preparação
clc
format longG
meiahora=30./1440.;
K = 273.15;
%% Nomes, blacklist e horários
for organize = 1
    %% Blacklist
    % O seguinte dá as 2912 sondas, com cada file um dos 4 horários diários
    if firsttime == 1
        nomes1 = dirpath('/Users/jop/Drive/Werken/Master/Projeto/Dados/maosondewnpnM1','maosondewnpnM1.b1.*');
        nomes2 = dirpath('/Users/jop/Drive/Werken/Master/Projeto/Dados/maoecmwfvarX11','maoecmwfvarX11.c1.*');
        nomes3 = dirpath('/Users/jop/Drive/Werken/Master/Projeto/Dados/maomwrpM1','maomwrpM1.b1.*');
        nome1 = char(nomes1(1));
        nome2 = char(nomes2(1));
        nome3 = char(nomes3(1));
        save('nomes.mat','nomes1','nomes2','nomes3','nome1','nome2','nome3')
    else
        load('nomes.mat')
    end
    toc
    % Os seguintes dados não chegam até 10km:
%    blalt = [42,116,121,126,139,180,186,231,238,263,266,275,305,307,326,327,363,364,368,369,404,427,438,474,480,604,608,639,734,829,830,858,887,904,912,941,993,1006,1007,1087,1132,1151,1182,1183,1206,1207,1218,1354,1364,1389,1393,1447,1470,1472,1517,1533,1564,1579,1594,1598,1599,1620,1623,1682,1692,1703,1704,1705,1710,1728,1737,1810,1823,1840,1867,1872,1873,1903,1904,1912,1949,1950,2048,2087,2123,2151,2155,2172,2175,2180,2182,2186,2191,2196,2199,2223,2244,2250,2269,2422,2511,2512,2540,2628,2659,2735,2767,2830,2838];
%    blrh = [232,364,1401,1532];
    % blrhdemais = [608,627,638,662,589, 633, 634,1467, 1641, 1647];
    % exemplos com rh_rs >?1: 608, 627, 638, 662
    % exemplos com rh_ra >?1: 589, 633, 634
    % exemplos com rh_rm >?1: 1467, 1641, 1647
    
    % bldata = [307,604,1087,1470,1598,1692,1704,1737,2172,2175,2191,2196,2269,2512,2659,2838]; %uma pressão só, então todos em blsonde tbm
    % blaltnovo = [82,83,229,230,239,240,249,250,276,355,356,366,367,455,456,469,470,519,520,525,526,543,544,603,607,645,646,647,648,718]; %27 dezembro achei esses dados com altitude até muito. Rebaixei os dados originais e sumiu esse problema.
    % exemplos sem radiômetro: 1288, 1292, 1296, 1302, 1304, 1594, 1630, 1682,
    
%     blmanual

    if calcularblacklist == 1
        whitelist = 1:length(nomes1);
        %     whiteblack = ones(1,length(nomes1));
        %     save('blacklists.mat',blalt1,blalt3)
        
        % Ik maak aparte blacklists per reden van verwijderen en per databron (1,2,3).
        blcorrupt1 = []; % Corrupte radiosondes met maar 1 datapunt. 23 stuks
        blwet1 = []; % Corrupte radiosondes met een stijgende luchtvochtigheid. ±?
        blsummask3 = []; % Voor deze radiosondes zijn alle radiometerdata corrupt. ±46
        blachou3 = []; % Voor deze radiosondes zijn radiometerdata beschikbaar. ±1240, mutually exclusive with the above
        blalt1 = []; % Radiosondes die de 10 km niet bereiken. Waarom niet?
        blrh1 = []; % Radiosondes met rh > 1. 0
        blrh2 = []; % Reanalyses met rh > 1. 0
        blrh3 = []; % Radiometers met rh > 1. ±1062 Hoe kan dit?
        %blachou3, blrh3, blsummask3 seem mutually exclusive
    else
        load('blacklists.mat')
        whiteblack = ones(1,length(nomes1)); % binaire versie van de blacklist
        whiteblack(blcorrupt1)=0;
        whiteblack(blalt1)=0;
        whiteblack(blrh1)=0;
        whiteblack(blrh2)=0;
        whiteblack(blrh3)=0;
        whitelist = nan(1,sum(whiteblack));
        j = 1;
        for i = 1:length(whiteblack)
            if whiteblack(i) == 1
                whitelist(j) = i;
                j = j + 1;
            end
        end
    end
    j=1;
    
    %% Pegar os horários para radiossonda, reanálise, e radiômetro
    if calcular == 1 %nessa parte, vamos colocar os horários
        horarios1 = nan(size(nomes1'));
        horarios1b = horarios1;
        for i = whitelist
            filepath1=char(nomes1(i));
            [tmpdir, nome1, tmpext] = fileparts(filepath1);
            z1 = ncread(filepath1,'alt');
            t1 = ncread(filepath1,'time');
            %     if (z1(end)<10.e3) % Assim gerei blsonde.
            %         blacklist(end+1)=i;
            %         continue
            %     end
            tmp=strsplit(nome1, '.');
            horarios1(i) = datenum([tmp{3} tmp{4}],'yyyymmddHHMMSS');
            j=find(z1>10.e3,1); % Confere que a sonda chega até 10 km.
            if isempty(j);j=find(z1==max(z1));end
            horarios1b(i)=floor(horarios1(i))+t1(j)/86400.;
        end
        horarios2 = nan(size(nomes2,2),744);
        for i = 1:length(nomes2)
            filepath2=char(nomes2(i));
            [tmpdir, nome2, tmpext] = fileparts(filepath2);
            tmp=strsplit(nome2, '.');
            year = str2double(tmp{3}(1:4));
            month = str2double(tmp{3}(5:6));
            day = str2double(tmp{3}(7:8));
            offsets = ncread(filepath2,'time_offset');
            horarios2(i,1:length(offsets))=datenum(year,month,day) + offsets/86400.;
        end
        % horarios3 = zeros(size(nomes3,2),1430);
        horarios3full = zeros(size(nomes3));
        for i = 1:length(nomes3)
            filepath3 = char(nomes3(i));
            [tmpdir, nome3, tmpext] = fileparts(filepath3);
            tmp=strsplit(nome3, '.');
            year = str2double(tmp{3}(1:4));
            month = str2double(tmp{3}(5:6));
            day = str2double(tmp{3}(7:8));
            % offsets = ncread(filepath3,'time_offset');
            datenum(year,month,day);
            horarios3full(i) = datenum(year,month,day);
        end
        save('horarios.mat','horarios1','horarios1b','horarios2','horarios3full')
    else
        load('horarios.mat','horarios1','horarios1b','horarios2','horarios3full')
    end  
end
%% Contar dados e preparar matrizes
i12 = 0;
i3 = 0;
if calcular == 1
    for loop = whitelist % Contar dados por horário.
        horario1 = horarios1(loop);
        horario1b = horarios1b(loop);
        i12=i12+1;
        achou = 0;
        for i = length(horarios3full):-1:1 % Achar o horário de radiômetro certo.
            if horarios3full(i)<horario1
                nome3 = char(nomes3(i));
                horario3 = horarios3full(i);
                achou = 1;
                break
            end
        end
        if achou == 1 % Só se tiver um horário adequado eu conto.
            offsets = ncread(nome3,'time_offset');
            t3 = horario3 + offsets/86400.;
            mask = t3 > horario1 & t3 < horario1b;
            summask = sum(mask);
            if summask > 0
                i3 = i3 + 1;
            end
        end
    end
    if i12 ~=2912 || i3 ~=1626
        X = sprintf('Oops! i12 is %d and is not equal to 2912 or i3, %d, is not equal to 1626.',i12,i3);
        disp(X)
        return
    end
end
n12=2912;n3=1626;

% Prealocar memória para as matrizes da radiosonda, a reanálise, e o radiômetro.
horarios12 = nan(1,n12);
horarios12b = nan(1,n12);
meses12 = nan(1,n12);
horas12 = nan(1,n12);
horarios3 = nan(1,n3);
meses3 = nan(1,n3);
horas3 = nan(1,n3);

summask3 = nan(1,n12);      %will indicate the sum of legit radiometer data for each radiosonde
indices1raw = nan(1,n12);
indices3de1 = nan(1,n12);   %will map the radiosonde data for each radiosonde if it has an appropriate one.

% z1t = nan(137,n12);
q1de2t=nan(137,n12);
P1de2t=nan(137,n12);
rh1de2t=nan(137,n12);
T1de2t=nan(137,n12);

P2t=nan(137,n12);
q2t=nan(137,n12);
z2t=nan(137,n12);
rh2t=nan(137,n12);
T2t=nan(137,n12);
drh2t=nan(137,n12);
dT2t=nan(137,n12);

q3t=nan(47,n3);
P3t=nan(47,n3);
rh3t=nan(47,n3);
T3t=nan(47,n3);
drh3=nan(47,n3);
dT3=nan(47,n3);

q1de3t=nan(47,n3);
rh1de3t=nan(47,n3);
T1de3t=nan(47,n3);

i12 = 0;
i3 = 0;
%% Loop para processar os dados
for loop = whitelist(1:end)
    disp(loop)
    %% 1. Radiosonde
    % Preparação
    i12 = i12 + 1;
    indices1raw(i12) = loop;
    nome1 = char(nomes1(loop));
    fieldname = ['sonde' nome1([79:86,88:91])];
    disp(fieldname)
    horario1 = horarios1(loop);
    horario1b = horarios1b(loop);
    hora = datevec(horario1);
    meses12(i12) = hora(2);
    horas12(i12) = hora(4);
    
    horarios12(i12) = horario1;
    horarios12b(i12) = horario1b;
    
    % Pegar os dados
    z1 = ncread(nome1,'alt'); % Altitude above sea level in m
%     z1t(:,loop) = z1;
    T1 = ncread(nome1,'tdry'); % Dry bulb temperatures in C
    P1 = ncread(nome1,'pres'); % Pressures in hPa, 2661 values going upwards from 1.0038e3 hPa to 0.0212e3 hPa
    rh1 = ncread(nome1,'rh'); % Relative humidity in %
    
    % Alterar os dados um pouco para poder contar os dados que vão no blacklist.
    if calcularblacklist == 1
        if length(P1)==1
            P1(2)=1000;
            z1(2)=z1(1)-1; % Diferente para não ser excluida depois, menos para poder tirar depois (±l.276)
            T1(2)=25;
            rh1(2)=90;
            blcorrupt1=[blcorrupt1 loop];
        end
    end
    
    % Vou tirar pontos que são idênticos, para não gerar erros depois na interpolação
    lastpressure = P1(1);
    lastheight = z1(1);
    current = 2;
    while current <= length(P1)
        currentpressure = P1(current);
        currentheight = z1(current);
        if currentpressure == lastpressure || currentheight == lastheight
            P1 = P1([1:current-1,current+1:end]);
            rh1 = rh1([1:current-1,current+1:end]);
            T1 = T1([1:current-1,current+1:end]);
            z1 = z1([1:current-1,current+1:end]);
        else
            current = current +1;
        end
        lastpressure = currentpressure;
        lastheight = currentheight;
    end
    
    % Determinamos quais dados não vamos poder usar.
    mask99 = (rh1<-9998) | (T1<-9998) |  (P1<-9998) | (z1<-9998);
    z1(mask99)=nan;
    T1(mask99)=nan;
    P1(mask99)=nan;
    rh1(mask99)=nan;
    
    % Determine specific humidity from relative humidity
    T1f = T1 + K;
    temp = 54.842763 - 6763.22 ./ T1f - 4.210 .* log(T1f) + 0.000367 .* T1f + tanh( 0.0415 * (T1f - 218.8) ) .* (53.878 - 1331.22 ./ T1f - 9.44523 .* log(T1f) + 0.014025 .* T1f);
    es = exp(temp); % saturation water vapor pressure
    e = rh1./100 .* es;
    Pd = P1*100 - e;
    c = 18.0152/28.9644; % M_v/M_d
    q1 = (e.*c)./(e.*c+Pd);
    rh1=rh1./100.;

    % Determinar quais dados são corruptos com rh>1.
    if calcularblacklist == 1
        if max(rh1)>1;max(rh1),blrh1=[blrh1 loop];end %#ok<AGROW>
    	if rh1(1)>1;blwet1=[blwet1 loop];end %#ok<AGROW>
        if z1(end)<10.e3; blalt1 = [blalt1 loop];end %#ok<AGROW>
%        if z1(end)>z1(1) && z1(end)<10.e3; blalt1 = [blalt1 loop];end;end %#ok<AGROW> % Alternativa para contar os fracos só  
    end
    %% 2. Reanálise
    % Vou achar o primeiro horário da ERA maior que a sonda para pegar o arquivo desse mes.
    % Eu guardo j e o horário
    breek = 0;
    for i = 1:size(horarios2,1)
        for j = 1:size(horarios2,2)
            if horarios2(i,j)>horario1
                nome2 = char(nomes2(i));
                horario2 = horarios2(i,j);
                breek = 1;
                break
            end
        end
        if breek ==1
            break
        end
    end
    
    % Agora pego os dados desse arquivo.
    P2full = ncread(nome2,'p'); % Reanalysis pressures in Pa
    P2 = 0.01*P2full(1,:,j); % Pressão na hora j do mes, in hPa
    P2t(:,i12) = P2;
    T2full = ncread(nome2,'T')-273.15;
    T2t(:,i12) = T2full(1,:,j)'; % Transposei para todos os dados ficarem em 137x1.
    q2full = ncread(nome2,'q');
    q2 = q2full(1,:,j);
    q2t(:,i12) = q2;
    rh2full = ncread(nome2,'R');
    rh2 = rh2full(1,:,j)'; % Transposei para todos os dados ficarem em 137x1.
    rh2t(:,i12) = rh2;
    if calcularblacklist == 1;if max(rh2t)>1;blrh2=[blrh2 loop];end;end %#ok<AGROW>
    
    % Prevent an error when counting the blacklists.
    if calcularblacklist == 1
        if isnan(P1(2))
            P1(2)=1000;
            z1(2)=100;
            T1(2)=25;
            rh1(2)=90;
            mask99(2)=0;
            blcorrupt1=[blcorrupt1 loop];
        end
    end
    
    % Gravar dados
    z2 = interp1(log(P1(~mask99)),z1(~mask99),log(P2), 'linear', 'extrap');
    z2t(:,i12) = z2;
    
    q1de2t(:,i12) = interp1(P1(~mask99),q1(~mask99),P2)';
    rh1de2t(:,i12) = interp1(P1(~mask99),rh1(~mask99),P2)';
    P1de2t(:,i12) = interp1(P1(~mask99),P1(~mask99),P2)';
    T1de2t(:,i12) = interp1(P1(~mask99),T1(~mask99),P2)';

    %     z1 = z1t;
    P1de2 = P1de2t;
    T1de2 = T1de2t;
    rh1de2 = rh1de2t;
    q1de2 = q1de2t;
    
    z2 = z2t;
    P2 = P2t;
    T2 = T2t;
    rh2 = rh2t;
    q2 = q2t;
    
    %% 3. Radiômetro
    % Começando por trás, pegamos o primeiro arquivo de radiômetro com horário menor que a sonda.
    achou = 0;
    for i = length(horarios3full):-1:1
        if horarios3full(i)<horario1
            nome3 = char(nomes3(i));
            horario3 = horarios3full(i);
            achou = 1;
            break
        end
    end
    if achou == 1 % Só se tiver um horário adequado pegamos os dados do radiômetro também.
        z3 = ncread(nome3,'height');
        offsets = ncread(nome3,'time_offset');
        t3 = horario3 + offsets/86400.;
        % Eu pego os horários que são entre partida da sonda e chegada a 10km.
        mask = t3 > horario1 & t3 < horario1b;
        summask = sum(mask);
        disp(summask)
        if summask > 0
            summask3(i12) = summask;
            i3 = i3 + 1;
            horarios3(i3)=horario1;
            meses3(i3) = hora(2);
            horas3(i3) = hora(4);
            indices3de1(loop) = i3;
            
            P3full = ncread(nome3,'pressure');
            P3rel = P3full(:,mask);
            qc_P3 = ncread(nome3,'qc_pressure');
            qc_P3rel = qc_P3(:,mask);
            
            T3full = ncread(nome3,'temperature')-274.15;
            T3rel=T3full(:,mask);
            qc_T3 = ncread(nome3,'qc_temperature');
            qc_T3rel = qc_T3(:,mask);
            
            rh3full = ncread(nome3,'relativeHumidity')/100;
            rh3rel = rh3full(:,mask);
            if calcularblacklist == 1
                if max(max(rh3rel))>1;blrh3=[blrh3 loop];end%#ok<AGROW>
            end 
            qc_rh3 = ncread(nome3,'qc_relativeHumidity');
            qc_rh3rel = qc_rh3(:,mask);
            
            w3full = ncread(nome3,'waterVaporMixingRatio');
            q3full = w3full ./ (1 + w3full);
            q3rel = q3full(:,mask);
            qc_q3 = ncread(nome3,'qc_waterVaporMixingRatio');
            qc_q3rel = qc_q3(:,mask);
            
            % qc_mask une todos os qc num perfil temporal.
            qc_mask_rel = (qc_P3rel<1) & (qc_T3rel<1) & (qc_rh3rel<1) & (qc_rh3rel<1); % Uma matriz de todos os qc
            qc_mask_rel = all(qc_mask_rel,1); % Uma linha que resume a matriz em cima
            
            %             cb = ncread(nome3,'cloudBaseHeight')';
            %             cbrel = cb(mask);
            %             qc_cb = ncread(nome3,'qc_cloudBaseHeight')';
            %             qc_cbrel = qc_cb(mask);
            %             cb = mean(cbrel(logical(not(qc_cbrel))),2);
            
            P3t(:,i3) = mean(P3rel(:,qc_mask_rel),2);
            T3t(:,i3) = mean(T3rel(:,qc_mask_rel),2);
            rh3t(:,i3) = mean(rh3rel(:,qc_mask_rel),2);
            q3t(:,i3) = mean(q3rel(:,qc_mask_rel),2);
            
            q1de3t(:,i3) = interp1(z1(~mask99),q1(~mask99),z3);
            rh1de3t(:,i3) = interp1(z1(~mask99),rh1(~mask99),z3);
            T1de3t(:,i3) = interp1(z1(~mask99),T1(~mask99),z3);
            P3 = P3t;
            T3 = T3t;
            rh3 = rh3t;
            q3 = q3t;
            q1de3 = q1de3t;
            T1de3 = T1de3t;
            rh1de3 = rh1de3t;
            %ik sla nu nptrad en qc_mask_rel niet meer op
        else
            if summask == 0
                disp('Line 416. summask == 0')
            end
            summask3(i12) = 0;
            blsummask3 = [blsummask3 loop]; %#ok<AGROW>
            indices3de1(i12) = nan;
        end
    else
        if calcularblacklist==1
            blachou3 = [blachou3 loop]; %#ok<AGROW>
        end
        indices3de1(i12) = nan;
    end
end
%% bl adicionais
% Tirar os dados errados de T1; todos são < 15 C a 400 metros
bltirarT1 = find(T1de2(end-10,:)<20);
% Tirar os dados errados de rh1; todos são 0.01 C a 300 metros
bltirarrh1 = find(rh1de2(end-8,:)<0.1);
blfriodemais1 = find(T1de2(end-31:end,:)<0);
% bltirarrh1 = 
%% Salvar dados
whitelist1bin = ones(1,n12);
whitelist1bin(blcorrupt1) = 0;
whitelist1bin(blwet1) = 0;
whitelist1bin(bltirarT1) = 0;
whitelist1bin(bltirarrh1) = 0;
whitelist1 = find(whitelist1bin==1);

whitelist3bin = zeros(1,n3);
whitelist3bin(indices3de1(find(summask3>0))) = 1;
whitelist3bin(indices3de1(blrh3)) = 0;
whitelist3 = find(whitelist3bin == 1);

if calcularblacklist == 1
    save('blacklists.mat','whitelist1','whitelist1bin','whitelist3','whitelist3bin','blwet1','bltirarT1','bltirarrh1','blsummask3','blachou3','blcorrupt1','blalt1','blrh1','blrh2','blrh3')
end
save('processedData.mat', ...
'horarios12','horarios12b','horarios3','meses12','meses3','horas12','horas3',...
'nomes1','nomes2','nomes3','i12','i3','indices3de1','indices1raw',...
'z1','z2','rh1de2','P1de2','T1de2','P2','q2','q1de2','T2','rh2','P3','T3','rh3','q3','q1de3','rh1de3','T1de3','z3')
toc