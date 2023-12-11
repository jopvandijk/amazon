%function processing()
%% Information
% This script selects radiosonde (1), reanalysis (2), and radiometer (3)
% data and bundles them in arrays. The selected parameters are temperature
% (T), humidity (rh), height (z) and pressure (P)

% Set modes
calculateBlacklist = 1;
determineTimes = 1;
countData = 1;
backup = 0;
clc
format longG
tic

for organize = 1
    %% Files
    % Define the filepaths to the netCDF files
    if backup == 0
        filepaths1 = dirpath('/Users/jop/Drive/Werken/Master/Projeto/Dados/maosondewnpnM1','maosondewnpnM1.b1.*');
        filepaths2 = dirpath('/Users/jop/Drive/Werken/Master/Projeto/Dados/maoecmwfvarX11','maoecmwfvarX11.c1.*');
        filepaths3 = dirpath('/Users/jop/Drive/Werken/Master/Projeto/Dados/maomwrpM1','maomwrpM1.b1.*');
    else
        filepaths1 = dirpath('/Users/jop/Drive/Werken/Master/Projeto/Backup dos dados/maosondewnpnM1','maosondewnpnM1.b1.*');
        filepaths2 = dirpath('/Users/jop/Drive/Werken/Master/Projeto/Backup dos dados/maoecmwfvarX11','maoecmwfvarX11.c1.*');
        filepaths3 = dirpath('/Users/jop/Drive/Werken/Master/Projeto/Backup dos dados/maomwrpM1','maomwrpM1.b1.*');
    end
    filepath1 = char(filepaths1(1));
    file2 = char(filepaths2(1));
    file3 = char(filepaths3(1));
    %% Blacklists
    % Prepare blacklists for different criteria, or load predefined blacklists
    if calculateBlacklist == 1
        whitelist = 1:length(filepaths1);

        blCorrupt1 = zeros(1,2912);  % Corrupt radiosondes with only 1 data point: 23 sondes
        blalt1 = ones(1,2912);      % Radiosondes that don't reach 10 km
        blWet1 = zeros(1,2912);      % Corrupt radiosondes with rising humidity: ±?
        blNoWindow3 = zeros(1,2912);  % Radiosondes without valid corresponding radiometer data: ±46
        blMissing3 = zeros(1,2912);    % Radiosondes with valid corresponding radiometer data: ±1240 (mutually exclusive with the above)
        blrh3 = ones(1,2912);       % Radiometers met rh > 1. ±1062 Hoe kan dit?
    else
        load blacklists.mat
        whiteblack = ones(1,length(filepaths1)); % binaire versie van de blacklist
        whiteblack = whiteblack .* blCorrupt1 .* blalt1 .* blrh3;
        whitelist = find(whiteblack==1);
    end
    
    %% Time
    % Determine times for radiosonde, reanalysis, and radiometer, or load preloaded times
    if determineTimes == 1
        % Extract radiosonde release and reach time from file name
        releaseTimes = nan(size(filepaths1));
        reachPoints = nan(size(filepaths1));
        reachTimes = nan(size(filepaths1));
        for i = 1401%whitelist
            filepath1 = char(filepaths1(i));
            [tmpdir, filename1, tmpext] = fileparts(filepath1);
            tmp=strsplit(filename1, '.');
            releaseTimes(i) = datenum([tmp{3} tmp{4}], 'yyyymmddHHMMSS');

            z1 = ncread(filepath1, 'alt')
            j = find(z1 > 1e4, 1)
            if ~isempty(j)
                reachPoints(i) = j
                radiosondeTime = ncread(filepath1, 'time')
                reachTimes(i) = floor(releaseTimes(i)) + radiosondeTime(j)/86400.
            else
                if length(z1)>1
                    blalt1(i) = 0;
                else
                    blCorrupt1(i) = 1;
                end
            end
        end

        % Extract reanalysis time from file name
        reanalysisTimes = nan(size(filepaths2, 2), 744);
        for i = 1:length(filepaths2)
            filepath2 = char(filepaths2(i));
            [tmpdir, file2, tmpext] = fileparts(filepath2);
            tmp = strsplit(file2, '.');
            year = str2double(tmp{3}(1:4));
            month = str2double(tmp{3}(5:6));
            day = str2double(tmp{3}(7:8));
            offsets = ncread(filepath2, 'time_offset');
            reanalysisTimes(i,1:length(offsets)) = datenum(year, month, day) + offsets/86400.;
        end

        % Extract radiometer time from file name
        radiometerTimes = zeros(size(filepaths3));
        for i = 1:length(filepaths3)
            filepath3 = char(filepaths3(i));
            [tmpdir, file3, tmpext] = fileparts(filepath3);
            tmp=strsplit(file3, '.');
            year = str2double(tmp{3}(1:4));
            month = str2double(tmp{3}(5:6));
            day = str2double(tmp{3}(7:8));
            datenum(year, month, day);
            radiometerTimes(i) = datenum(year, month, day);
        end
        save('times.mat','releaseTimes','reachPoints','reachTimes','reanalysisTimes','radiometerTimes')
    else
        load('times.mat','releaseTimes','reachPoints','reachTimes','reanalysisTimes','radiometerTimes')
    end
    toc

    %% Count data
    % Count whitelisted data for the radiosonde and reanalysis
    if countData == 1
        i12 = 0;
        i3 = 0;
        blub = 0;
        failedRadiometers = 0;
        for loop = whitelist
            releaseTime = releaseTimes(loop);
            reachTime = reachTimes(loop);
            i12 = i12 + 1;
            found = 0;
            % Find the right radiometer file
            for i = length(radiometerTimes):-1:1
                if radiometerTimes(i) < releaseTime
                    file3 = char(filepaths3(i));
                    radiometerTime = radiometerTimes(i);
                    found = 1;
                    break
                end
            end
            % Count if data is
            if found == 1
                offsets = ncread(file3, 'time_offset');
                t3 = radiometerTime + offsets/86400.;
                window = t3 > releaseTime & t3 < reachTime;
                summask = sum(window);
                if summask > 0
                    i3 = i3 + 1;
                else
                    failedRadiometers = failedRadiometers + 1;
                end
            else
                blub = blub + 1;
            end
        end
        save('dataCount.mat', 'i12', 'i3')
    else
        load('dataCount.mat', 'i12', 'i3') % Note to self: dit geeft 1582 maar was dus eerder 1626.
    end

    blub;
    failedRadiometers;
    
    % Set timers for code optimization
    radiosonde = 0;
    specificHumidityCalculation = 0;
    humidityBlacklistDetermination = 0;
    reanalysis = 0;
    reanalysisInterpolation = 0;
    radiometer = 0;
    matchRadiometerFile = 0;
    radiometerInterpolation = 0;

    %% Memory preallocation
    % Time data
    times12 = nan(1, i12);
    months12 = nan(1, i12);
    hours12 = nan(1, i12);
    times3 = nan(1, i3);
    months3 = nan(1, i3);
    hours3 = nan(1, i3);
    
    validRadiometerDatapoints = nan(1, i12);
    radiometerIndices = nan(1, i12);

    % Reanalysis parameters
    P2 = nan(56, i12);
    q2 = nan(56, i12);
    z2 = nan(56, i12);
    rh2 = nan(56, i12);
    T2 = nan(56, i12);

    q1in2 = nan(56, i12);
    P1in2 = nan(56, i12);
    rh1in2 = nan(56, i12);
    T1in2 = nan(56, i12);

    % Radiometer parameters
    q3 = nan(47, i3);
    P3 = nan(47, i3);
    rh3 = nan(47, i3);
    T3 = nan(47, i3);

    q1in3 = nan(47, i3);
    rh1in3 = nan(47, i3);
    T1in3 = nan(47, i3);

    i12 = 0;
    i3 = 0;
end

%% Processing
z3 = [0:100:1000, 1250:250:10000]';
for loop = 1401%whitelist(1:end)
    disp(loop)
    if (isnan(reachPoints(loop)))
        continue
    end
    %% 1. Radiosonde
    % The radiosonde source data is organized in one file per sonde
    % Four sondes were released each day for the entire measuring period
    lil = toc;
    % Prepare
    i12 = i12 + 1;
    filepath1 = char(filepaths1(loop));
    fieldname = ['sonde' filepath1([79:86,88:91])];
    releaseTime = releaseTimes(loop);
    hour12 = datevec(releaseTime);
    months12(i12) = hour12(2);
    hours12(i12) = hour12(4);
    
    times12(i12) = releaseTime;
    
    % Read data from netCDF files
    z1 = ncread(filepath1, 'alt',1,reachPoints(loop));   % Altitude above sea level in m
    T1 = ncread(filepath1, 'tdry',1,reachPoints(loop));  % Dry bulb temperatures in C
    P1 = ncread(filepath1, 'pres',1,reachPoints(loop));  % Pressures in hPa, 2661 values going upwards from 1.0038e3 hPa to 0.0212e3 hPa
    rh1 = ncread(filepath1, 'rh',1,reachPoints(loop));   % Relative humidity, dimensionless
    return
    % Prevent an error when counting the blacklists
%     if calculateBlacklist == 1
%         if length(P1) == 1
%             P1(2) = 1000;
%             z1(2) = z1(1) - 1; % Diferente para não ser excluida depois, menos para poder tirar depois (±l.272)
%             T1(2) = 25;
%             rh1(2) = 90;
%             blcorrupt1(loop) = 0;
%         end
%     end
    
    % Remove identical data points (or interpolation gives error)
    lastpressure = P1(1);
    lastheight = z1(1);
    current = 2;
    while current <= length(P1)
        currentPressure = P1(current);
        currentHeight = z1(current);
        if currentPressure == lastpressure || currentHeight == lastheight
            P1 = P1([1:current-1, current+1:end]);
            rh1 = rh1([1:current-1, current+1:end]);
            T1 = T1([1:current-1, current+1:end]);
            z1 = z1([1:current-1, current+1:end]);
        else
            current = current + 1;
        end
        lastpressure = currentPressure;
        lastheight = currentHeight;
    end
    
    % Determine which data we can't use
    mask99 = (rh1 <- 9998) | (T1 <- 9998) | (P1 <- 9998) | (z1 <- 9998);
    return
    z1(mask99) = nan;
    T1(mask99) = nan;
    P1(mask99) = nan;
    rh1(mask99) = nan;
    
    % Determine specific humidity from relative humidity (0.6 s)
    T1f = T1 + 273.15;
    temp = 54.842763 - 6763.22 ./ T1f - 4.210 .* log(T1f) + 0.000367 .* T1f + tanh( 0.0415 * (T1f - 218.8) ) .* (53.878 - 1331.22 ./ T1f - 9.44523 .* log(T1f) + 0.014025 .* T1f);
    es = exp(temp); % saturation water vapor pressure
    e = rh1 .* 0.01 .* es;
    Pd = P1 .* 100 - e;
    c = 18.0152 / 28.9644; % M_v/M_d
    q1 = (e.*c) ./ (e.*c + Pd);
    rh1 = rh1 ./ 100.;

    % Determine which sondes report too high relative humidity
    if calculateBlacklist == 1
    	if rh1(1) > 1; blWet1(loop) = 1; end
        if max(rh1) > 1; max(rh1), blrh1(loop) = 0; end
        if z1(end) < 10.e3; blalt1(loop) = 0; end % to exclude add: && z1(end)>z1(1)
    end

    radiosonde = radiosonde + toc - lil;

    %% 2. Reanalysis
    % The reanalysis source data is organized in one file per month with an array of data every hour

    lil = toc;
    % Find corresponding reanalysis file
    stop = 0;
    for i = 1:size(reanalysisTimes, 1)
        for j = 1:size(reanalysisTimes, 2)
            if reanalysisTimes(i,j) > releaseTime
                file2 = char(filepaths2(i));
                stop = 1;
                break
            end
        end
        if stop == 1
            break
        end
    end
    
    % Read data at hour j from reanalysis file
    P2i = 0.01 * ncread(file2, 'p', [1 82 j], [1 56 1]); % Reanalysis pressures in hPa at hour j
    P2(:,i12) = P2i;
    T2i = ncread(file2, 'T', [1 82 j], [1 56 1]) - 273.15;
    T2(:,i12) = T2i;
    q2i = ncread(file2, 'q', [1 82 j], [1 56 1]);
    q2(:,i12) = q2i;
    rh2i = ncread(file2, 'R', [1 82 j], [1 56 1]);
    rh2(:,i12) = rh2i;
    
    if calculateBlacklist == 1; if max(rh2) > 1; blrh2(loop) = 0; end; end
    
    % Prevent an error when counting the blacklists
%     if calculateBlacklist == 1
%         if isnan(P1(2))
%             P1(2) = 1000;
%             z1(2) = 100;
%             T1(2) = 25;
%             rh1(2) = 90;
%             mask99(2) = 0;
%             blcorrupt1(loop) = 0;
%         end
%     end
    
    % Interpolate reanalysis pressure to height
    lol = toc;
    z2i = interp1(log(P1(~mask99)),z1(~mask99),log(P2i), 'linear', 'extrap');
    z2(:,i12) = z2i;
    
    % Interpolate radiosonde data to reanalysis grid (14.4 s)
    q1in2(:,i12) = interp1(P1(~mask99), q1(~mask99), P2i)';
    rh1in2(:,i12) = interp1(P1(~mask99), rh1(~mask99), P2i)';
    P1in2(:,i12) = interp1(P1(~mask99), P1(~mask99), P2i)';
    T1in2(:,i12) = interp1(P1(~mask99), T1(~mask99), P2i)';
    reanalysisInterpolation = reanalysisInterpolation + toc - lol;

    reanalysis = reanalysis + toc - lil;

    %% 3. Radiometer
    % The radiometer source data is organized in one file per day, with one
    % array of data every minute.
    
    lil = toc;
    % Find matching radiometer data file or continue
    lal = toc;
    found = 0;
    for i = length(radiometerTimes):-1:1
        if radiometerTimes(i) < releaseTime
            file3 = char(filepaths3(i));
            radiometerTime = radiometerTimes(i);
            found = 1;
            break
        end
    end
    if found == 0
        if calculateBlacklist == 1
            blMissing3(loop) = 1;
        end
        radiometerIndices(i12) = nan;
        continue
    end
    matchRadiometerFile = matchRadiometerFile + toc - lal;

    % Find window of radiometer measurements within radiosonde flight or continue
    offsets = ncread(file3, 'time_offset');
    t3 = radiometerTime + offsets .* 0.000011574074074074; %offsets seconden naar dagen, (multiplication trumps division)
    window = t3 > releaseTime & t3 < reachTime;
    summask = sum(window);
    if summask == 0
        disp('Summask == 0 (line 367)')
        validRadiometerDatapoints(i12) = 0;
        blNoWindow3(loop) = 1;
        radiometerIndices(i12) = nan;
        continue
    end

    % Save radiometer index, times
    disp(summask)
    validRadiometerDatapoints(i12) = summask;
    i3 = i3 + 1;
    radiometerIndices(loop) = i3;
    times3(i3) = releaseTime;
    months3(i3) = hour12(2);
    hours3(i3) = hour12(4);

    % Load data and quality checks
    P3full = ncread(file3, 'pressure');
    P3rel = P3full(:, window);
    qc_P3 = ncread(file3, 'qc_pressure');
    qc_P3rel = qc_P3(:, window);

    T3full = ncread(file3, 'temperature') - 273.15;
    T3rel = T3full(:, window);
    qc_T3 = ncread(file3, 'qc_temperature');
    qc_T3rel = qc_T3(:, window);

    rh3full = ncread(file3, 'relativeHumidity') .* 0.01;
    rh3rel = rh3full(:, window);
    if calculateBlacklist == 1
        if max(max(rh3rel)) > 1; blrh3(loop) = 0; end
    end
    qc_rh3 = ncread(file3, 'qc_relativeHumidity');
    qc_rh3rel = qc_rh3(:, window);

    w3full = ncread(file3, 'waterVaporMixingRatio');
    q3full = w3full ./ (1 + w3full);
    q3rel = q3full(:, window);
    qc_q3 = ncread(file3, 'qc_waterVaporMixingRatio');
    qc_q3rel = qc_q3(:, window);

    % Unite quality checks
    qc_mask_rel = (qc_P3rel<1) & (qc_T3rel< 1) & (qc_rh3rel < 1) & (qc_rh3rel < 1);
    size(qc_mask_rel)
    %pause
    qc_mask_rel = all(qc_mask_rel,1);

    P3(:,i3) = mean(P3rel(:,qc_mask_rel),2);
    T3(:,i3) = mean(T3rel(:,qc_mask_rel),2);
    rh3(:,i3) = mean(rh3rel(:,qc_mask_rel),2);
    q3(:,i3) = mean(q3rel(:,qc_mask_rel),2);

    % Interpolate radiosonde data to radiometer grid
    lol = toc;
    q1in3(:,i3) = interp1(z1(~mask99),q1(~mask99),z3);
    rh1in3(:,i3) = interp1(z1(~mask99),rh1(~mask99),z3);
    T1in3(:,i3) = interp1(z1(~mask99),T1(~mask99),z3);
    radiometerInterpolation = radiometerInterpolation + toc - lol;

    radiometer = radiometer + toc - lil;
end
%% Save data
% Determine additional blacklists and save

% Tirar os dados errados de T1; todos são < 15 C a 400 metros
bltirarT1bin = find(T1in2(end-10,:) < 20);
bltirarT1 = ones(1,2912);
bltirarT1(bltirarT1bin) = 0;
% Tirar os dados errados de rh1; todos são 0.01 C a 300 metros
bltirarrh1bin = find(rh1in2(end-8,:) < 0.1);
bltirarrh1 = ones(1,2912);
bltirarrh1(bltirarrh1bin) = 0;
blfriodemais1 = find(T1in2(end-31:end,:) < 0);

if calculateBlacklist == 1
    save('blacklists.mat', ...
        'whitelist1','whitelist1bin','whitelist3bin',...
        'blCorrupt1','blalt1','blWet1','bltirarT1','bltirarrh1',...
        'blNoWindow3','blMissing3','blrh3')
end

whitelist1bin = blCorrupt1 .* blWet1 .* bltirarT1 .* bltirarrh1;
whitelist1 = find(whitelist1bin==1);

%whitelist3bin = false(1,n12);
%whitelist3bin(summask3>0) = 1;
whitelist3bin = ones(1,1666);
toc

save('processedData.mat', ...
'times12','times3','months12','months3','hours12','hours3',...
'filepaths1','filepaths2','filepaths3','i12','i3','radiometerIndices',...
'z1','z2','rh2','rh1in2','P2','P1in2','T2','T1in2','T3','T1in3','rh3','rh1in3','P3','z3')
toc

%end