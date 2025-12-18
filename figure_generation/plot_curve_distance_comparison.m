function plot_curve_distance_comparison(set_number, pairs_number, base_folder)
%PLOT_CURVE_DISTANCE_COMPARISON Plots distance between curve points before and after equalization
%
%   This function:
%   1. Loads a game set and generates Bezier curves
%   2. Calculates and plots distances between consecutive curve points (BEFORE equalization)
%   3. Applies bezier_equidistant to each segment
%   4. Calculates and plots distances between consecutive curve points (AFTER equalization)
%
%   Usage:
%   plot_curve_distance_comparison(set_number, pairs_number)
%   plot_curve_distance_comparison(set_number, pairs_number, base_folder)
%
%   Inputs:
%   - set_number: The game set number to load
%   - pairs_number: Number of obstacle pairs (2, 3, 4, or 5)
%   - base_folder: (Optional) Base folder path

if nargin < 3
    base_folder = pwd;
end

% Add current folder to path to access helper functions
addpath(pwd);

% Load the game data
pairs_folder = fullfile(base_folder, sprintf('%dpairs', pairs_number), 'fit');
set_name = sprintf('set_%d_%dpairs.mat', set_number, pairs_number);
fullFileName = fullfile(pairs_folder, set_name);

if ~exist(fullFileName, 'file')
    error('File not found: %s', fullFileName);
end

fprintf('Loading game set: %s\n', fullFileName);
data = load(fullFileName);

% Extract necessary data
if ~isfield(data, 'variables_matrix') || ~isfield(data, 'Start_points') || ~isfield(data, 'End_points')
    error('Required fields (variables_matrix, Start_points, End_points) not found in data file');
end

variables_matrix = data.variables_matrix;
Start_points = data.Start_points;
End_points = data.End_points;
num_segments = size(Start_points, 1);

% Determine n_d and n_phi from variables_matrix structure
n_cols = size(variables_matrix, 2);
if n_cols == 5
    n_d = 2;
    n_phi = 1;
else
    n_d = 3;
    n_phi = 2;
end

% Get num_samples_list
if isfield(data, 'num_samples_list')
    num_samples_list = data.num_samples_list;
else
    num_samples_list = 25 * ones(num_segments, 1);
end

% Get curve from data file (prefer 'curve' over 'path')
if isfield(data, 'curve') && ~isempty(data.curve)
    curve_from_data = data.curve;
    curve_label = 'From Data (curve)';
elseif isfield(data, 'path') && ~isempty(data.path)
    curve_from_data = data.path;
    curve_label = 'From Data (path)';
else
    curve_from_data = [];
    curve_label = '';
    fprintf('Warning: No curve or path field found in data file\n');
end

% Calculate curve segment points
curve_segment_points = calculate_curve_segment_points(variables_matrix, Start_points, End_points, num_segments, n_d, n_phi);

% ============================================================================
% GENERATE CURVES BEFORE EQUALIZATION
% ============================================================================
fprintf('Generating curves (BEFORE equalization)...\n');
composite_curve_before = [];
composite_curve_before_no_duplicates = [];  % Composite curve without duplicate boundary points
segment_curves_before = cell(num_segments, 1);
segment_start_indices = zeros(num_segments, 1);
current_index = 1;

for i = 1:num_segments
    segment_control_points = curve_segment_points(:, :, i);
    segment_curve = bezier_curve(segment_control_points, num_samples_list(i));
    segment_curves_before{i} = segment_curve;
    segment_start_indices(i) = current_index;
    
    % For composite curve with duplicates (original behavior)
    composite_curve_before = [composite_curve_before; segment_curve];
    
    % For composite curve without duplicates: remove last point of each segment
    % (except last segment) since it's the same as first point of next segment
    if i < num_segments
        composite_curve_before_no_duplicates = [composite_curve_before_no_duplicates; segment_curve(1:end-1, :)];
    else
        composite_curve_before_no_duplicates = [composite_curve_before_no_duplicates; segment_curve];
    end
    
    current_index = current_index + size(segment_curve, 1);
end

% Calculate distances between consecutive points (BEFORE)
distances_before = [];
segment_distances_before = cell(num_segments, 1);

for i = 1:num_segments
    segment_curve = segment_curves_before{i};
    segment_dists = sqrt(sum(diff(segment_curve, 1, 1).^2, 2));
    segment_distances_before{i} = segment_dists;
    distances_before = [distances_before; segment_dists];
end

% ============================================================================
% GENERATE CURVES AFTER EQUALIZATION
% ============================================================================
fprintf('Generating curves (AFTER equalization)...\n');
composite_curve_after = [];
composite_curve_after_no_duplicates = [];  % Composite curve without duplicate boundary points
segment_curves_after = cell(num_segments, 1);
segment_start_indices_after = zeros(num_segments, 1);
current_index_after = 1;

for i = 1:num_segments
    segment_control_points = curve_segment_points(:, :, i);
    % Apply equidistant equalization
    segment_curve = bezier_equidistant(segment_control_points, num_samples_list(i));
    segment_curves_after{i} = segment_curve;
    segment_start_indices_after(i) = current_index_after;
    
    % For composite curve with duplicates (original behavior)
    composite_curve_after = [composite_curve_after; segment_curve];
    
    % For composite curve without duplicates: remove last point of each segment
    % (except last segment) since it's the same as first point of next segment
    if i < num_segments
        composite_curve_after_no_duplicates = [composite_curve_after_no_duplicates; segment_curve(1:end-1, :)];
    else
        composite_curve_after_no_duplicates = [composite_curve_after_no_duplicates; segment_curve];
    end
    
    current_index_after = current_index_after + size(segment_curve, 1);
end

% Calculate distances between consecutive points (AFTER)
distances_after = [];
segment_distances_after = cell(num_segments, 1);

for i = 1:num_segments
    segment_curve = segment_curves_after{i};
    segment_dists = sqrt(sum(diff(segment_curve, 1, 1).^2, 2));
    segment_distances_after{i} = segment_dists;
    distances_after = [distances_after; segment_dists];
end

% ============================================================================
% GENERATE CURVES WITH 0.5 CM SPACING (AFTER EQUALIZATION)
% ============================================================================
fprintf('Generating curves with 0.5 cm spacing (AFTER equalization)...\n');

% First, calculate segment lengths to determine number of samples
segment_lengths = zeros(num_segments, 1);
for i = 1:num_segments
    % Use high-resolution curve to measure true arc length
    segment_control_points = curve_segment_points(:, :, i);
    temp_curve = bezier_equidistant(segment_control_points, 1000);  % High-res for accurate length
    segment_lengths(i) = sum(sqrt(sum(diff(temp_curve, 1, 1).^2, 2)));
end

% Calculate number of samples for each segment
% For num_samples points, there are (num_samples - 1) gaps
% If we want spacing = target_spacing, then: segment_length = (num_samples - 1) * target_spacing
% Therefore: num_samples = (segment_length / target_spacing) + 1
target_spacing = 0.5;  % cm
num_samples_list_05cm = round(segment_lengths / target_spacing) + 1;
% Ensure at least 2 points per segment
num_samples_list_05cm = max(num_samples_list_05cm, 2);

fprintf('  Segment lengths and sample counts:\n');
for i = 1:num_segments
    fprintf('    Segment %d: length = %.4f cm, samples = %d\n', i, segment_lengths(i), num_samples_list_05cm(i));
end

% Generate EQUALIZED curves with 0.5 cm spacing sample count
fprintf('  Generating equalized curves with 0.5 cm sample count...\n');
composite_curve_05cm = [];
composite_curve_05cm_no_duplicates = [];  % Composite curve without duplicate boundary points
segment_curves_05cm = cell(num_segments, 1);
segment_start_indices_05cm = zeros(num_segments, 1);
current_index_05cm = 1;

for i = 1:num_segments
    segment_control_points = curve_segment_points(:, :, i);
    % Apply equidistant equalization with calculated number of samples
    segment_curve = bezier_equidistant(segment_control_points, num_samples_list_05cm(i));
    segment_curves_05cm{i} = segment_curve;
    segment_start_indices_05cm(i) = current_index_05cm;
    
    % For composite curve with duplicates (original behavior)
    composite_curve_05cm = [composite_curve_05cm; segment_curve];
    
    % For composite curve without duplicates: remove last point of each segment
    % (except last segment) since it's the same as first point of next segment
    if i < num_segments
        composite_curve_05cm_no_duplicates = [composite_curve_05cm_no_duplicates; segment_curve(1:end-1, :)];
    else
        composite_curve_05cm_no_duplicates = [composite_curve_05cm_no_duplicates; segment_curve];
    end
    
    current_index_05cm = current_index_05cm + size(segment_curve, 1);
end

% Calculate distances between consecutive points (0.5 cm spacing - EQUALIZED)
distances_05cm = [];
segment_distances_05cm = cell(num_segments, 1);

for i = 1:num_segments
    segment_curve = segment_curves_05cm{i};
    segment_dists = sqrt(sum(diff(segment_curve, 1, 1).^2, 2));
    segment_distances_05cm{i} = segment_dists;
    distances_05cm = [distances_05cm; segment_dists];
end

% ============================================================================
% PLOT COMPARISON
% ============================================================================
fprintf('Creating comparison plots...\n');

% Create figure with four subplots (2x2 layout)
figure('Position', [100, 100, 1600, 1000]);

% Subplot 1: Distance plot (BEFORE) - Segment-wise
subplot(2, 2, 1);
hold on;
grid on;

% Plot distances for each segment with different colors
colors = lines(num_segments);
point_indices_before = 1:length(distances_before);

current_idx = 1;
for i = 1:num_segments
    seg_dists = segment_distances_before{i};
    seg_indices = current_idx:(current_idx + length(seg_dists) - 1);
    plot(seg_indices, seg_dists, 'o-', 'Color', colors(i, :), 'LineWidth', 1.5, ...
        'MarkerSize', 4, 'DisplayName', sprintf('Segment %d', i));
    current_idx = current_idx + length(seg_dists);
end

xlabel('Point Index', 'FontSize', 12);
ylabel('Distance Between Consecutive Points (cm)', 'FontSize', 12);
title('BEFORE Equalization: Distance Between Curve Points', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'southeast');
ylim([0, max(distances_before) * 1.1]);

% Add statistics text (bottom-left)
mean_dist_before = mean(distances_before);
std_dist_before = std(distances_before);
min_dist_before = min(distances_before);
max_dist_before = max(distances_before);
text(0.02, 0.02, sprintf('Mean: %.4f cm\nStd: %.4f cm\nMin: %.4f cm\nMax: %.4f cm', ...
    mean_dist_before, std_dist_before, min_dist_before, max_dist_before), ...
    'Units', 'normalized', 'VerticalAlignment', 'bottom', 'FontSize', 10, ...
    'BackgroundColor', 'white', 'EdgeColor', 'black');

% Subplot 2: Distance plot (AFTER) - Segment-wise
subplot(2, 2, 2);
hold on;
grid on;

% Plot distances for each segment with different colors
point_indices_after = 1:length(distances_after);

current_idx = 1;
for i = 1:num_segments
    seg_dists = segment_distances_after{i};
    seg_indices = current_idx:(current_idx + length(seg_dists) - 1);
    plot(seg_indices, seg_dists, 'o-', 'Color', colors(i, :), 'LineWidth', 1.5, ...
        'MarkerSize', 4, 'DisplayName', sprintf('Segment %d', i));
    current_idx = current_idx + length(seg_dists);
end

xlabel('Point Index', 'FontSize', 12);
ylabel('Distance Between Consecutive Points (cm)', 'FontSize', 12);
title('AFTER Equalization: Distance Between Curve Points', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'southeast');
ylim([0, max(distances_after) * 1.1]);

% Add statistics text (bottom-left)
mean_dist_after = mean(distances_after);
std_dist_after = std(distances_after);
min_dist_after = min(distances_after);
max_dist_after = max(distances_after);
text(0.02, 0.02, sprintf('Mean: %.4f cm\nStd: %.4f cm\nMin: %.4f cm\nMax: %.4f cm', ...
    mean_dist_after, std_dist_after, min_dist_after, max_dist_after), ...
    'Units', 'normalized', 'VerticalAlignment', 'bottom', 'FontSize', 10, ...
    'BackgroundColor', 'white', 'EdgeColor', 'black');

% Subplot 3: Distance plot (0.5 cm spacing - EQUALIZED) - Segment-wise
subplot(2, 2, 3);
hold on;
grid on;

% Plot distances for each segment with different colors
point_indices_05cm = 1:length(distances_05cm);

current_idx = 1;
for i = 1:num_segments
    seg_dists = segment_distances_05cm{i};
    seg_indices = current_idx:(current_idx + length(seg_dists) - 1);
    plot(seg_indices, seg_dists, 'o-', 'Color', colors(i, :), 'LineWidth', 1.5, ...
        'MarkerSize', 4, 'DisplayName', sprintf('Segment %d', i));
    current_idx = current_idx + length(seg_dists);
end

xlabel('Point Index', 'FontSize', 12);
ylabel('Distance Between Consecutive Points (cm)', 'FontSize', 12);
title('0.5 cm Sample Count (Equalized)', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'southeast');
ylim([0, max(distances_05cm) * 1.1]);

% Add statistics text (bottom-left)
mean_dist_05cm = mean(distances_05cm);
std_dist_05cm = std(distances_05cm);
min_dist_05cm = min(distances_05cm);
max_dist_05cm = max(distances_05cm);
text(0.02, 0.02, sprintf('Mean: %.4f cm\nStd: %.4f cm\nMin: %.4f cm\nMax: %.4f cm\nTarget: 0.5 cm', ...
    mean_dist_05cm, std_dist_05cm, min_dist_05cm, max_dist_05cm), ...
    'Units', 'normalized', 'VerticalAlignment', 'bottom', 'FontSize', 10, ...
    'BackgroundColor', 'white', 'EdgeColor', 'black');

% Calculate distances for curve from data file (if available)
distances_from_data = [];
if ~isempty(curve_from_data)
    distances_from_data = sqrt(sum(diff(curve_from_data, 1, 1).^2, 2));
end

% Calculate distances for composite curves (including duplicate points at boundaries)
% This will show zero distances at segment boundaries, same as the data curve
distances_composite_before = sqrt(sum(diff(composite_curve_before, 1, 1).^2, 2));
distances_composite_after = sqrt(sum(diff(composite_curve_after, 1, 1).^2, 2));
distances_composite_05cm = sqrt(sum(diff(composite_curve_05cm, 1, 1).^2, 2));

% Calculate distances for composite curves WITHOUT duplicate points at boundaries
% This avoids zero distances by removing duplicate boundary points
distances_composite_before_no_dup = sqrt(sum(diff(composite_curve_before_no_duplicates, 1, 1).^2, 2));
distances_composite_after_no_dup = sqrt(sum(diff(composite_curve_after_no_duplicates, 1, 1).^2, 2));
distances_composite_05cm_no_dup = sqrt(sum(diff(composite_curve_05cm_no_duplicates, 1, 1).^2, 2));

% Subplot 4: Overall curve (all segments combined, WITHOUT duplicate boundaries)
subplot(2, 2, 4);
hold on;
grid on;

% Plot composite curve distances WITHOUT duplicate points at boundaries
% This avoids zero distances by removing duplicate boundary points
plot(1:length(distances_composite_before_no_dup), distances_composite_before_no_dup, '-', 'Color', [0.8, 0.2, 0.2], ...
    'LineWidth', 1.5, 'DisplayName', 'Before Equalization');
plot(1:length(distances_composite_after_no_dup), distances_composite_after_no_dup, '-', 'Color', [0.2, 0.6, 0.8], ...
    'LineWidth', 1.5, 'DisplayName', 'After Equalization');
plot(1:length(distances_composite_05cm_no_dup), distances_composite_05cm_no_dup, '-', 'Color', [0.2, 0.8, 0.4], ...
    'LineWidth', 1.5, 'DisplayName', '0.5 cm Sample Count');

xlabel('Point Index (Overall Curve)', 'FontSize', 12);
ylabel('Distance Between Consecutive Points (cm)', 'FontSize', 12);
title('Overall Curve: Distance Comparison', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'southeast');

% Set y-axis limits to include all curves
all_max_distances = [max(distances_composite_before_no_dup), max(distances_composite_after_no_dup), max(distances_composite_05cm_no_dup)];
ylim([0, max(all_max_distances) * 1.1]);

% Add statistics text for overall curves (bottom-left, without duplicate boundaries)
stats_text = sprintf('Before (No Dup): Mean=%.4f, Std=%.4f\nAfter (No Dup): Mean=%.4f, Std=%.4f\n0.5cm (No Dup): Mean=%.4f, Std=%.4f', ...
    mean(distances_composite_before_no_dup), std(distances_composite_before_no_dup), ...
    mean(distances_composite_after_no_dup), std(distances_composite_after_no_dup), ...
    mean(distances_composite_05cm_no_dup), std(distances_composite_05cm_no_dup));
% text(0.02, 0.02, stats_text, ...
%     'Units', 'normalized', 'VerticalAlignment', 'bottom', 'FontSize', 10, ...
%     'BackgroundColor', 'white', 'EdgeColor', 'black');

% Add overall title
sgtitle(sprintf('Curve Point Distance Comparison - Set %d (%d pairs)', set_number, pairs_number), ...
    'FontSize', 16, 'FontWeight', 'bold');

% ============================================================================
% PRINT STATISTICS
% ============================================================================
fprintf('\n=== DISTANCE STATISTICS ===\n');
fprintf('BEFORE Equalization:\n');
fprintf('  Mean distance: %.6f cm\n', mean_dist_before);
fprintf('  Std deviation: %.6f cm\n', std_dist_before);
fprintf('  Min distance:  %.6f cm\n', min_dist_before);
fprintf('  Max distance:  %.6f cm\n', max_dist_before);
fprintf('  Coefficient of variation: %.4f%%\n', (std_dist_before/mean_dist_before)*100);

fprintf('\nAFTER Equalization:\n');
fprintf('  Mean distance: %.6f cm\n', mean_dist_after);
fprintf('  Std deviation: %.6f cm\n', std_dist_after);
fprintf('  Min distance:  %.6f cm\n', min_dist_after);
fprintf('  Max distance:  %.6f cm\n', max_dist_after);
fprintf('  Coefficient of variation: %.4f%%\n', (std_dist_after/mean_dist_after)*100);

fprintf('\n0.5 CM SAMPLE COUNT (Equalized):\n');
fprintf('  Mean distance: %.6f cm\n', mean_dist_05cm);
fprintf('  Std deviation: %.6f cm\n', std_dist_05cm);
fprintf('  Min distance:  %.6f cm\n', min_dist_05cm);
fprintf('  Max distance:  %.6f cm\n', max_dist_05cm);
fprintf('  Coefficient of variation: %.4f%%\n', (std_dist_05cm/mean_dist_05cm)*100);
fprintf('  Deviation from target (0.5 cm): %.4f cm\n', abs(mean_dist_05cm - target_spacing));

fprintf('\nImprovement (Original vs Equalized):\n');
fprintf('  Std reduction: %.2f%%\n', ((std_dist_before - std_dist_after) / std_dist_before) * 100);
fprintf('  CV reduction:  %.2f%%\n', (((std_dist_before/mean_dist_before) - (std_dist_after/mean_dist_after)) / (std_dist_before/mean_dist_before)) * 100);

fprintf('\nImprovement (Original vs 0.5 cm sample count - Equalized curve):\n');
fprintf('  Std reduction: %.2f%%\n', ((std_dist_before - std_dist_05cm) / std_dist_before) * 100);
fprintf('  CV reduction:  %.2f%%\n', (((std_dist_before/mean_dist_before) - (std_dist_05cm/mean_dist_05cm)) / (std_dist_before/mean_dist_before)) * 100);


% ============================================================================
% OPTIONAL: Save figure
% ============================================================================
% Uncomment to save the figure
% output_folder = fullfile(base_folder, sprintf('%dpairs', pairs_number), 'fit');
% if ~exist(output_folder, 'dir')
%     mkdir(output_folder);
% end
% output_filename = sprintf('curve_distance_comparison_set_%d_%dpairs.png', set_number, pairs_number);
% output_path = fullfile(output_folder, output_filename);
% print(output_path, '-dpng', '-r300');
% fprintf('\nFigure saved to: %s\n', output_path);

fprintf('\nDone!\n');

% ============================================================================
% OPTIONAL: Save figure
% ============================================================================
% Ask user if they want to save the figure
user_response = input('Do you want to save the figure? (y/n): ', 's');

if strcmpi(user_response, 'y') || strcmpi(user_response, 'yes')
    % Save in current folder
    output_filename = sprintf('curve_distance_comparison_set_%d_%dpairs.png', set_number, pairs_number);
    output_path = fullfile(pwd, output_filename);
    
    % Save figure
    print(gcf, output_path, '-dpng', '-r300');
    fprintf('Figure saved to: %s\n', output_path);
else
    fprintf('Figure not saved.\n');
end

end

