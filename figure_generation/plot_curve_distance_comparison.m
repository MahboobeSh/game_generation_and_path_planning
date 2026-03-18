function plot_curve_distance_comparison(set_number, pairs_number, base_folder, target_spacing)
%PLOT_CURVE_DISTANCE_COMPARISON Plots segment-wise distance analysis and game visualization
%
%   This function creates TWO figures:
%   
%   Figure 1: BEFORE Equalization + Game Environment (1x2 layout)
%     Subplot 1: Distance Between Curve Points (BEFORE Equalization)
%       - Shows distance between consecutive points
%       - Each segment colored differently for identification
%       - Statistics: Mean, Std, Min, Max distances
%     Subplot 2: Game Environment with Colored Segments
%       - Obstacles, start/end points
%       - Curve segments in SAME colors as Subplot 1
%
%   Figure 2: Detailed Distance Analysis (2x2 layout)
%     Subplot 1: Distance BEFORE Equalization (repeated for reference)
%     Subplot 2: Distance AFTER Equalization (segment-wise)
%     Subplot 3: Distance with Target Spacing (segment-wise)
%     Subplot 4: Overall Curve Comparison (all three methods)
%
%   Steps:
%   1. Loads a game set and generates Bezier curves
%   2. Calculates distances (before, after, with target spacing)
%   3. Creates Figure 1 with BEFORE analysis and game visualization
%   4. Creates Figure 2 with comprehensive 4-subplot analysis
%
%   Usage:
%   plot_curve_distance_comparison(set_number, pairs_number)
%   plot_curve_distance_comparison(set_number, pairs_number, base_folder)
%   plot_curve_distance_comparison(set_number, pairs_number, base_folder, target_spacing)
%
%   Inputs:
%   - set_number: The game set number to load
%   - pairs_number: Number of obstacle pairs (2, 3, 4, or 5)
%   - base_folder: (Optional) Base folder path
%   - target_spacing: (Optional) Target spacing in cm for equalization (default: 0.5 cm)
%
%   Examples:
%   plot_curve_distance_comparison(0, 2)                    % Use default 0.5 cm
%   plot_curve_distance_comparison(0, 2, pwd, 0.25)         % Use 0.25 cm spacing
%   plot_curve_distance_comparison(41, 3, pwd, 0.25)        % Analyze set 41

if nargin < 3
    base_folder = pwd;
end

if nargin < 4
    target_spacing = 0.5;  % Default to 0.5 cm
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
% GENERATE CURVES WITH TARGET SPACING (AFTER EQUALIZATION)
% ============================================================================
fprintf('Generating curves with %.2f cm spacing (AFTER equalization)...\n', target_spacing);

% Use generate_equalized_bezier_curve function for consistent curve generation
[composite_curve_05cm_no_duplicates, segment_info_05cm] = generate_equalized_bezier_curve(curve_segment_points, target_spacing);

% Extract segment information
segment_lengths = segment_info_05cm.lengths;
num_samples_list_05cm = segment_info_05cm.num_samples;
segment_curves_05cm = segment_info_05cm.curves;

fprintf('  Segment lengths and sample counts:\n');
for i = 1:num_segments
    fprintf('    Segment %d: length = %.4f cm, samples = %d\n', i, segment_lengths(i), num_samples_list_05cm(i));
end

% Create composite curve WITH duplicates for consistency with previous code
% (This is needed for some plotting/analysis that expects duplicate boundary points)
composite_curve_05cm = [];
segment_start_indices_05cm = zeros(num_segments, 1);
current_index_05cm = 1;

for i = 1:num_segments
    segment_curve = segment_curves_05cm{i};
    segment_start_indices_05cm(i) = current_index_05cm;
    composite_curve_05cm = [composite_curve_05cm; segment_curve];
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
% FIGURE 1: BEFORE EQUALIZATION + GAME ENVIRONMENT
% ============================================================================
fprintf('Creating Figure 1: BEFORE equalization and game environment...\n');

% Get obstacle and game data
if isfield(data, 'obstacle') && isfield(data, 'obstacle_radious')
    obstacles = data.obstacle;
    obstacle_radii = data.obstacle_radious;
else
    obstacles = [];
    obstacle_radii = [];
end

if isfield(data, 'X_s') && isfield(data, 'X_e')
    X_s = data.X_s;
    X_e = data.X_e;
else
    X_s = [];
    X_e = [];
end

if isfield(data, 'x_range') && isfield(data, 'y_range')
    x_range = data.x_range;
    y_range = data.y_range;
else
    x_range = 30;
    y_range = 40;
end

% Create figure with two subplots (1x2 layout)
figure('Position', [100, 100, 1600, 600]);

% Define colors for segments
colors = lines(num_segments);

% ============================================================================
% SUBPLOT 1: Distance BEFORE Equalization
% ============================================================================
subplot(1, 2, 1);
hold on;
grid on;

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
hold off;

% ============================================================================
% SUBPLOT 2: Game Environment with Colored Segments
% ============================================================================
subplot(1, 2, 2);
hold on;
grid on;

% Plot obstacles with black fill
color_black = [0, 0, 0];
if ~isempty(obstacles)
    for i = 1:size(obstacles, 1)
        viscircles(obstacles(i, :), obstacle_radii(i), 'EdgeColor', 'k', 'Color', color_black, 'LineWidth', 1.5);
    end
end

% Plot start and end points
if ~isempty(X_s)
    plot(X_s(1), X_s(2), 'ko', 'MarkerSize', 10, 'MarkerFaceColor', 'g', 'LineWidth', 2, 'HandleVisibility', 'off');
    text(X_s(1), X_s(2), ' Start', 'FontSize', 10, 'FontWeight', 'bold', 'Color', 'k', ...
        'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left');
end

if ~isempty(X_e)
    plot(X_e(1), X_e(2), 'ko', 'MarkerSize', 10, 'MarkerFaceColor', 'r', 'LineWidth', 2, 'HandleVisibility', 'off');
    text(X_e(1), X_e(2), ' End', 'FontSize', 10, 'FontWeight', 'bold', 'Color', 'k', ...
        'VerticalAlignment', 'top', 'HorizontalAlignment', 'right');
end

% Plot each segment of the curve with its corresponding color
for i = 1:num_segments
    segment_curve = segment_curves_before{i};
    plot(segment_curve(:, 1), segment_curve(:, 2), '-', 'Color', colors(i, :), ...
        'LineWidth', 2.5, 'DisplayName', sprintf('Segment %d', i));
end

xlim([0, x_range]);
ylim([0, y_range]);
xlabel('X (cm)', 'FontSize', 12);
ylabel('Y (cm)', 'FontSize', 12);
title('Game Environment with Curve Segments', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 10);
axis equal;
hold off;

% Add overall title for Figure 1
sgtitle(sprintf('Distance Analysis and Game Visualization - Set %d (%d pairs)', set_number, pairs_number), ...
    'FontSize', 16, 'FontWeight', 'bold');

% Store these for later calculations
mean_dist_after = mean(distances_after);
std_dist_after = std(distances_after);
min_dist_after = min(distances_after);
max_dist_after = max(distances_after);
mean_dist_05cm = mean(distances_05cm);
std_dist_05cm = std(distances_05cm);
min_dist_05cm = min(distances_05cm);
max_dist_05cm = max(distances_05cm);

% ============================================================================
% FIGURE 2: FOUR ORIGINAL SUBPLOTS (2x2 LAYOUT)
% ============================================================================
fprintf('Creating Figure 2: Four subplot analysis...\n');

% Calculate distances for composite curves
distances_composite_before_no_dup = sqrt(sum(diff(composite_curve_before_no_duplicates, 1, 1).^2, 2));
distances_composite_after_no_dup = sqrt(sum(diff(composite_curve_after_no_duplicates, 1, 1).^2, 2));
distances_composite_05cm_no_dup = sqrt(sum(diff(composite_curve_05cm_no_duplicates, 1, 1).^2, 2));

% Create figure with 2x2 subplots
figure('Position', [150, 150, 1600, 1000]);

% ============================================================================
% SUBPLOT 1: Distance BEFORE Equalization (Repeated for reference)
% ============================================================================
subplot(2, 2, 1);
hold on;
grid on;

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
title('BEFORE Equalization', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'southeast');
ylim([0, max(distances_before) * 1.1]);

text(0.02, 0.02, sprintf('Mean: %.4f cm\nStd: %.4f cm\nMin: %.4f cm\nMax: %.4f cm', ...
    mean_dist_before, std_dist_before, min_dist_before, max_dist_before), ...
    'Units', 'normalized', 'VerticalAlignment', 'bottom', 'FontSize', 10, ...
    'BackgroundColor', 'white', 'EdgeColor', 'black');
hold off;

% ============================================================================
% SUBPLOT 2: Distance After Equalization
% ============================================================================
subplot(2, 2, 2);
hold on;
grid on;

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

text(0.02, 0.02, sprintf('Mean: %.4f cm\nStd: %.4f cm\nMin: %.4f cm\nMax: %.4f cm', ...
    mean_dist_after, std_dist_after, min_dist_after, max_dist_after), ...
    'Units', 'normalized', 'VerticalAlignment', 'bottom', 'FontSize', 10, ...
    'BackgroundColor', 'white', 'EdgeColor', 'black');
hold off;

% ============================================================================
% SUBPLOT 3: Distance with Target Spacing
% ============================================================================
subplot(2, 2, 3);
hold on;
grid on;

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
title(sprintf('%.2f cm Target Spacing (Equalized)', target_spacing), 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'southeast');
ylim([0, max(distances_05cm) * 1.1]);

text(0.02, 0.02, sprintf('Mean: %.4f cm\nStd: %.4f cm\nMin: %.4f cm\nMax: %.4f cm\nTarget: %.2f cm', ...
    mean_dist_05cm, std_dist_05cm, min_dist_05cm, max_dist_05cm, target_spacing), ...
    'Units', 'normalized', 'VerticalAlignment', 'bottom', 'FontSize', 10, ...
    'BackgroundColor', 'white', 'EdgeColor', 'black');
hold off;

% ============================================================================
% SUBPLOT 4: Overall Curve Comparison
% ============================================================================
subplot(2, 2, 4);
hold on;
grid on;

plot(1:length(distances_composite_before_no_dup), distances_composite_before_no_dup, '-', 'Color', [0.8, 0.2, 0.2], ...
    'LineWidth', 1.5, 'DisplayName', 'Before Equalization');
plot(1:length(distances_composite_after_no_dup), distances_composite_after_no_dup, '-', 'Color', [0.2, 0.6, 0.8], ...
    'LineWidth', 1.5, 'DisplayName', 'After Equalization');
plot(1:length(distances_composite_05cm_no_dup), distances_composite_05cm_no_dup, '-', 'Color', [0.2, 0.8, 0.4], ...
    'LineWidth', 1.5, 'DisplayName', sprintf('%.2f cm Spacing', target_spacing));

xlabel('Point Index (Overall Curve)', 'FontSize', 12);
ylabel('Distance Between Consecutive Points (cm)', 'FontSize', 12);
title('Overall Curve: Distance Comparison', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'southeast');

all_max_distances = [max(distances_composite_before_no_dup), max(distances_composite_after_no_dup), max(distances_composite_05cm_no_dup)];
ylim([0, max(all_max_distances) * 1.1]);
hold off;

% Add overall title for Figure 2
sgtitle(sprintf('Detailed Distance Analysis - Set %d (%d pairs)', set_number, pairs_number), ...
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

fprintf('\n%.2f CM TARGET SPACING (Equalized):\n', target_spacing);
fprintf('  Mean distance: %.6f cm\n', mean_dist_05cm);
fprintf('  Std deviation: %.6f cm\n', std_dist_05cm);
fprintf('  Min distance:  %.6f cm\n', min_dist_05cm);
fprintf('  Max distance:  %.6f cm\n', max_dist_05cm);
fprintf('  Coefficient of variation: %.4f%%\n', (std_dist_05cm/mean_dist_05cm)*100);
fprintf('  Deviation from target (%.2f cm): %.4f cm\n', target_spacing, abs(mean_dist_05cm - target_spacing));

fprintf('\nImprovement (Original vs Equalized):\n');
fprintf('  Std reduction: %.2f%%\n', ((std_dist_before - std_dist_after) / std_dist_before) * 100);
fprintf('  CV reduction:  %.2f%%\n', (((std_dist_before/mean_dist_before) - (std_dist_after/mean_dist_after)) / (std_dist_before/mean_dist_before)) * 100);

fprintf('\nImprovement (Original vs %.2f cm target spacing - Equalized curve):\n', target_spacing);
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
% OPTIONAL: Save figures
% ============================================================================
% Ask user if they want to save the figures
user_response = input('Do you want to save the figures? (y/n): ', 's');

if strcmpi(user_response, 'y') || strcmpi(user_response, 'yes')
    % Save in current folder
    % Figure 1: BEFORE equalization + Game environment
    output_filename_1 = sprintf('before_and_game_set_%d_%dpairs.png', set_number, pairs_number);
    output_path_1 = fullfile(pwd, output_filename_1);
    
    % Figure 2: Detailed analysis with 4 subplots
    output_filename_2 = sprintf('detailed_analysis_set_%d_%dpairs.png', set_number, pairs_number);
    output_path_2 = fullfile(pwd, output_filename_2);
    
    % Save both figures
    % Get all figure handles
    figs = findobj('Type', 'figure');
    if length(figs) >= 2
        % Save Figure 1 (BEFORE + game environment)
        figure(figs(end));
        print(output_path_1, '-dpng', '-r300');
        fprintf('Figure 1 (BEFORE + Game) saved to: %s\n', output_path_1);
        
        % Save Figure 2 (Detailed analysis)
        figure(figs(end-1));
        print(output_path_2, '-dpng', '-r300');
        fprintf('Figure 2 (Detailed analysis) saved to: %s\n', output_path_2);
    end
else
    fprintf('Figures not saved.\n');
end

end

