%% ===================================================================
%  Repeatability Analysis of Bead Position Across Cycles
%  Loads cycle1.txt ... cycle12.txt, cleans data, smooths, aligns via
%  cross-correlation, resamples onto a common time grid, and computes
%  repeatability statistics
%  ===================================================================

clear; clc; close all;

numCycles  = 12;
windowSize = 3;     % moving average window (adjust based on noise level)
rawData    = cell(numCycles, 1);

%% ---- Step 1: Load all files, convert units (m -> mm), remove NaNs ----
for i = 1:numCycles
    filename = sprintf('cycle%d.txt', i);
    data = readmatrix(filename, 'NumHeaderLines', 1, 'Delimiter', '\t');
    
    % Remove any row containing NaN in t, x, or y
    nanRows = any(isnan(data), 2);
    if any(nanRows)
        fprintf('Cycle %d: removed %d row(s) with NaN values\n', i, sum(nanRows));
    end
    data = data(~nanRows, :);
    
    t = data(:,1);
    x = data(:,2) * 1000;  % m to mm
    y = data(:,3) * 1000;  % m to mm
    
    rawData{i} = [t, x, y];
end

%% ---- Step 2: Apply moving average smoothing (reduces hand-marking jitter) ----
smoothData = cell(numCycles, 1);
for i = 1:numCycles
    t = rawData{i}(:,1);
    x_smooth = movmean(rawData{i}(:,2), windowSize);
    y_smooth = movmean(rawData{i}(:,3), windowSize);
    smoothData{i} = [t, x_smooth, y_smooth];
end

%% ---- Step 3: Sanity check plot - raw vs smoothed (Cycle 1 only) ----
figure;
plot(rawData{1}(:,1), rawData{1}(:,2), 'k:', 'DisplayName', 'Raw X');
hold on;
plot(smoothData{1}(:,1), smoothData{1}(:,2), 'r-', 'LineWidth', 1.5, 'DisplayName', 'Smoothed X');
xlabel('Time (s)');
ylabel('X Position (mm)');
title('Cycle 1: Raw vs Smoothed X Position (Sanity Check)');
legend('show');
grid on;
hold off;

%% ---- Step 4: Estimate average time step (for delay-to-time conversion) ----
allDts = [];
for i = 1:numCycles
    allDts = [allDts; diff(smoothData{i}(:,1))];
end
avgDt = mean(allDts);
fprintf('\nEstimated average time step: %.4f s\n', avgDt);

%% ---- Step 5 (REVISED): Align all cycles by peak position ----
fprintf('\n--- Alignment shifts relative to Cycle 1 (peak-based) ---\n');

% Find peak time for reference cycle (Cycle 1)
[~, refPeakIdx] = max(smoothData{1}(:,2));
refPeakTime = smoothData{1}(refPeakIdx, 1);

alignedData = cell(numCycles, 1);

for i = 1:numCycles
    [~, peakIdx] = max(smoothData{i}(:,2));
    peakTime = smoothData{i}(peakIdx, 1);
    
    timeShift = peakTime - refPeakTime;
    
    fprintf('Cycle %d: peak at t=%.3f s, shifted by %.3f s\n', i, peakTime, timeShift);
    
    shiftedTime = smoothData{i}(:,1) - timeShift;
    alignedData{i} = [shiftedTime, smoothData{i}(:,2), smoothData{i}(:,3)];
end
%% ---- Step 6: Normalize all aligned cycles so the earliest point = 0 ----
globalMinT = inf;
for i = 1:numCycles
    thisMin = min(alignedData{i}(:,1));
    if thisMin < globalMinT
        globalMinT = thisMin;
    end
end
for i = 1:numCycles
    alignedData{i}(:,1) = alignedData{i}(:,1) - globalMinT;
end

%% ---- Step 7: Determine common time grid (overlapping region only) ----
startTimes = zeros(numCycles,1);
endTimes   = zeros(numCycles,1);
for i = 1:numCycles
    startTimes(i) = alignedData{i}(1,1);
    endTimes(i)   = alignedData{i}(end,1);
end

commonStart = max(startTimes);
commonEnd   = min(endTimes);

if commonEnd <= commonStart
    error('No overlapping time region across cycles after alignment. Check your data/alignment.');
end

commonTime  = commonStart:avgDt:commonEnd;

fprintf('\nCommon time grid: %.3f s to %.3f s (%d points)\n', ...
    commonStart, commonEnd, length(commonTime));

%% ---- Step 8: Interpolate each cycle onto the common time grid ----
x_resampled = zeros(length(commonTime), numCycles);
y_resampled = zeros(length(commonTime), numCycles);

for i = 1:numCycles
    t_i = alignedData{i}(:,1);
    x_i = alignedData{i}(:,2);
    y_i = alignedData{i}(:,3);
    
    x_resampled(:,i) = interp1(t_i, x_i, commonTime, 'linear');
    y_resampled(:,i) = interp1(t_i, y_i, commonTime, 'linear');
end

%% ---- Step 9: Compute repeatability statistics across cycles ----
meanX = mean(x_resampled, 2);
stdX  = std(x_resampled, 0, 2);
meanY = mean(y_resampled, 2);
stdY  = std(y_resampled, 0, 2);

overallStdX = mean(stdX);
overallStdY = mean(stdY);

fprintf('\n--- Overall Repeatability ---\n');
fprintf('Average SD across time (X): %.4f mm\n', overallStdX);
fprintf('Average SD across time (Y): %.4f mm\n', overallStdY);
%% ---- Step 9b: Find overall X and Y range across all cycles ----
allX = [];
allY = [];
for i = 1:numCycles
    allX = [allX; alignedData{i}(:,2)];
    allY = [allY; alignedData{i}(:,3)];
end

xMin = min(allX);
xMax = max(allX);
yMin = min(allY);
yMax = max(allY);

xRange = xMax - xMin;
yRange = yMax - yMin;

fprintf('\n--- Overall Range Across All Cycles ---\n');
fprintf('X range: %.3f mm (min: %.3f, max: %.3f)\n', xRange, xMin, xMax);
fprintf('Y range: %.3f mm (min: %.3f, max: %.3f)\n', yRange, yMin, yMax);

%% ---- Step 9c: Calculate repeatability as percentage of range ----
xRepeatabilityPercent = (overallStdX / xRange) * 100;
yRepeatabilityPercent = (overallStdY / yRange) * 100;

fprintf('\n--- Repeatability as %% of Range ---\n');
fprintf('X repeatability: %.4f mm (%.2f%% of range)\n', overallStdX, xRepeatabilityPercent);
fprintf('Y repeatability: %.4f mm (%.2f%% of range)\n', overallStdY, yRepeatabilityPercent);
%% ---- Step 10: Plot all aligned trajectories (X vs time) ----
figure;

hold on;
colors = lines(numCycles);
for i = 1:numCycles
    plot(alignedData{i}(:,1), alignedData{i}(:,2), 'Color', colors(i,:), ...
        'DisplayName', sprintf('Cycle %d', i));
end
xlabel('Aligned Time (s)');
ylabel('X Position (mm)');
title('Aligned X Position Across Cycles');
legend('show');
grid on;
hold off;
saveas(gcf, 'aligned_cycles.png');
%% ---- Step 11: Plot mean ± SD band (X) ----
figure;

hold on;
plot(commonTime, meanX, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Mean X');
fill([commonTime, fliplr(commonTime)], ...
     [meanX' + stdX', fliplr(meanX' - stdX')], ...
     'b', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', '±1 SD');
xlabel('Time (s)');
ylabel('X Position (mm)');
title('Repeatability Band: X Position (Mean ± SD)');
legend('show');
grid on;
hold off;
saveas(gcf, 'SD_X_position.png');
%% ---- Step 12: Plot mean ± SD band (Y) ----
figure;

hold on;
plot(commonTime, meanY, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Mean Y');
fill([commonTime, fliplr(commonTime)], ...
     [meanY' + stdY', fliplr(meanY' - stdY')], ...
     'r', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', '±1 SD');
xlabel('Time (s)');
ylabel('Y Position (mm)');
title('Repeatability Band: Y Position (Mean ± SD)');
legend('show');
grid on;
hold off;
saveas(gcf, 'SD_Y_position.png');
%% ---- Step 13: Plot spatial trajectories (X-Y path) for visual comparison ----
figure;

hold on;
for i = 1:numCycles
    plot(alignedData{i}(:,2), alignedData{i}(:,3), 'Color', colors(i,:), ...
        'DisplayName', sprintf('Cycle %d', i));
end
xlabel('X Position (mm)');
ylabel('Y Position (mm)');
title('Spatial Trajectories Across Cycles (Aligned)');
legend('show');
axis equal;
grid on;
hold off;
saveas(gcf, 'traj.png');