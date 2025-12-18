% RUN_GAME_VISUALIZATION - Simple script to visualize games with metrics
%
% TWO MODES:
%   Mode 1: Visualize ONE specific game
%   Mode 2: Visualize ALL games in a pair folder (3pairs, 4pairs, or 5pairs)
%
% Just edit the configuration below and run this script!

clear; close all; clc;

%% ========== CONFIGURATION (EDIT THIS) ==========

% Base folder containing your games
base_folder = '/home/mahboobe/Desktop/game_generation_and_path_planning/new_games/final_games';

% ────── SELECT MODE ──────
% Mode 1: Single game
% Mode 2: All games in a pair folder
mode = 2;  % Change to 1 or 2

% ────── MODE 1: Single Game ──────
set_number = 44;        % Specific set number
number_of_pairs = 5;    % 3, 4, or 5

% ────── MODE 2: All Games in Folder ──────
pairs_to_visualize = 4;  % 3, 4, or 5 - will show ALL games in this folder

% ────── SAVE OPTIONS ──────
save_figure = true;
pause_between_games = 1;  % Seconds to pause between games (Mode 2 only)

%% ========== RUN VISUALIZATION ==========

fprintf('=== GAME VISUALIZATION WITH METRICS ===\n\n');

if mode == 1
    %% MODE 1: Single Game
    game_file = sprintf('set_%d_%dpairs.mat', set_number, number_of_pairs);
    game_path = fullfile(base_folder, sprintf('%dpairs/fit', number_of_pairs), game_file);
    
    % Create output folder for this pair count
    output_folder = fullfile(base_folder, 'visualizations', sprintf('%dpairs', number_of_pairs));
    
    fprintf('Visualizing: %s\n', game_file);
    
    if ~exist(game_path, 'file')
        error('File not found: %s\nPlease check the set number and pairs.', game_path);
    end
    
    try
        create_game_visualization(game_path, save_figure, output_folder);
        fprintf('✓ Done\n\n');
        if save_figure
            fprintf('Saved to: %s\n', output_folder);
        end
    catch ME
        fprintf('✗ Error: %s\n\n', ME.message);
        rethrow(ME);
    end
    
elseif mode == 2
    %% MODE 2: All Games in Pair Folder
    fit_folder = fullfile(base_folder, sprintf('%dpairs/fit', pairs_to_visualize));
    
    % Create output folder for this pair count
    output_folder = fullfile(base_folder, 'visualizations', sprintf('%dpairs', pairs_to_visualize));
    
    if ~exist(fit_folder, 'dir')
        error('Folder not found: %s', fit_folder);
    end
    
    % Get all .mat files
    mat_files = dir(fullfile(fit_folder, '*.mat'));
    
    if isempty(mat_files)
        error('No .mat files found in %s', fit_folder);
    end
    
    fprintf('Found %d games in %dpairs/fit folder\n', length(mat_files), pairs_to_visualize);
    fprintf('Output folder: %s\n\n', output_folder);
    
    % Process each game
    for i = 1:length(mat_files)
        game_file = mat_files(i).name;
        game_path = fullfile(fit_folder, game_file);
        
        fprintf('[%d/%d] Visualizing: %s\n', i, length(mat_files), game_file);
        
        try
            create_game_visualization(game_path, save_figure, output_folder);
            fprintf('      ✓ Done\n\n');
            
            % Pause between games (except last one)
            if i < length(mat_files) && pause_between_games > 0
                pause(pause_between_games);
                if ~save_figure
                    close(gcf);  % Close figure if not saving
                end
            end
        catch ME
            fprintf('      ✗ Error: %s\n\n', ME.message);
        end
    end
    
    fprintf('=== VISUALIZATION COMPLETE ===\n');
    fprintf('Processed %d games from %dpairs/fit\n', length(mat_files), pairs_to_visualize);
    if save_figure
        fprintf('Figures saved to: %s\n', output_folder);
    end
    
else
    error('Invalid mode. Set mode to 1 (single game) or 2 (all games in folder)');
end

%% ========== VISUALIZATION FUNCTION ==========

function create_game_visualization(game_path, save_fig, output_dir)
    % Load game data
    data = load(game_path);
    [~, game_name, ~] = fileparts(game_path);
    
    % Extract basic info
    obstacles = data.obstacle;
    obstacle_radii = data.obstacle_radious(:);
    X_s = data.X_s;
    X_e = data.X_e;
    
    if isfield(data, 'number_of_pairs')
        num_pairs = data.number_of_pairs;
    else
        num_pairs = size(obstacles, 1) / 2;
    end
    
    % Get path
    if isfield(data, 'curve_equalized') && ~isempty(data.curve_equalized)
        path = data.curve_equalized;
        path_type = 'Equalized Curve';
    elseif isfield(data, 'curve') && ~isempty(data.curve)
        path = data.curve;
        path_type = 'Bezier Curve';
    elseif isfield(data, 'path') && ~isempty(data.path)
        path = data.path;
        path_type = 'A* Path';
    else
        error('No path found');
    end
    
    if isfield(data, 'x_range')
        x_range = data.x_range;
        y_range = data.y_range;
    else
        x_range = 30; y_range = 40;
    end
    
    % Calculate metrics
    path_length = sum(sqrt(sum(diff(path).^2, 2)));
    [pair_distances, pair_radii, pair_gaps] = calculate_pair_distances_and_gaps(obstacles, obstacle_radii, num_pairs);
    [min_clearance, avg_clearance, clearance_profile] = ...
        calculate_clearance_profile(path, obstacles, obstacle_radii);
    [curvature_factor, straight_distance] = ...
        calculate_path_curvature(path, X_s, X_e, data);
    
    % Calculate minimal rehab metrics
    try
        rehab = calculate_rehab_metrics_minimal(path, obstacles, obstacle_radii);
        has_rehab = true;
    catch
        has_rehab = false;
        warning('Could not calculate rehab metrics');
    end
    
    %% CREATE FIGURE
    fig = figure('Position', [100, 100, 1400, 800], ...
        'Name', ['Game: ' game_name]);
    
    % Main game visualization (left side)
    subplot(1, 2, 1);
    hold on;
    
    % Draw obstacles
    for i = 1:size(obstacles, 1)
        rectangle('Position', [obstacles(i,1)-obstacle_radii(i), ...
                               obstacles(i,2)-obstacle_radii(i), ...
                               2*obstacle_radii(i), 2*obstacle_radii(i)], ...
                 'Curvature', [1,1], 'EdgeColor', 'r', 'LineWidth', 1.5);
    end
    
    % Path colored by difficulty
    clearance_color = 1 ./ max(clearance_profile, 0.1);
    scatter(path(:,1), path(:,2), 20, clearance_color, 'filled');
    colormap(gca, 'jet');
    cb = colorbar;
    cb.Label.String = 'Difficulty (Inverse Clearance)';
    
    % Start/End markers
    plot(X_s(1), X_s(2), 'go', 'MarkerSize', 14, 'LineWidth', 3);
    plot(X_e(1), X_e(2), 'bs', 'MarkerSize', 14, 'LineWidth', 3);
    text(X_s(1), X_s(2)-1.5, 'START', 'HorizontalAlignment', 'center', ...
        'FontSize', 10, 'FontWeight', 'bold', 'Color', 'g');
    text(X_e(1), X_e(2)+1.5, 'END', 'HorizontalAlignment', 'center', ...
        'FontSize', 10, 'FontWeight', 'bold', 'Color', 'b');
    
    % Lines between pairs
    for i = 1:num_pairs
        idx1 = 2*i-1; idx2 = 2*i;
        if idx2 <= size(obstacles, 1)
            plot([obstacles(idx1,1), obstacles(idx2,1)], ...
                 [obstacles(idx1,2), obstacles(idx2,2)], ...
                 'k--', 'LineWidth', 0.5);
        end
    end
    
    axis equal; grid on;
    xlabel('X (cm)', 'FontSize', 11);
    ylabel('Y (cm)', 'FontSize', 11);
    title(sprintf('%s\n%s | %d Pairs', game_name, path_type, num_pairs), ...
        'FontSize', 12, 'FontWeight', 'bold', 'Interpreter', 'none');
    
    % Metrics panel (right side)
    subplot(1, 2, 2);
    axis off;
    
    % Calculate average slope
    dy = diff(path(:,2));
    dx = diff(path(:,1));
    slopes = atan2d(dy, dx);  % Slope in degrees
    avg_slope = mean(abs(slopes));
    
    % Build metrics text using cell array for proper line breaks
    txt_lines = {};
    txt_lines{end+1} = 'GAME METRICS';
    txt_lines{end+1} = repmat('═', 1, 40);
    txt_lines{end+1} = '';
    txt_lines{end+1} = sprintf('Game:             %s', game_name);
    txt_lines{end+1} = sprintf('Path Type:        %s', path_type);
    txt_lines{end+1} = sprintf('Number of Pairs:  %d', num_pairs);
    txt_lines{end+1} = '';
    txt_lines{end+1} = repmat('─', 1, 40);
    txt_lines{end+1} = 'PATH METRICS';
    txt_lines{end+1} = repmat('─', 1, 40);
    txt_lines{end+1} = sprintf('Path Length:      %.2f cm', path_length);
    txt_lines{end+1} = sprintf('Average Slope:    %.2f degrees', avg_slope);
    txt_lines{end+1} = '';
    
    if has_rehab
        txt_lines{end+1} = repmat('─', 1, 40);
        txt_lines{end+1} = 'DIFFICULTY METRICS';
        txt_lines{end+1} = repmat('─', 1, 40);
        txt_lines{end+1} = sprintf('Steering Index:   %.2f', rehab.SteeringIndex);
        txt_lines{end+1} = sprintf('K (Rotation):     %.4f rad', rehab.K_TotalRotation);
        txt_lines{end+1} = sprintf('Composite Score:  %.2f', rehab.CompositeScore);
        txt_lines{end+1} = '';
    end
    
    txt_lines{end+1} = repmat('─', 1, 40);
    txt_lines{end+1} = 'OBSTACLE PAIRS (cm)';
    txt_lines{end+1} = repmat('─', 1, 40);
    txt_lines{end+1} = sprintf('Pair    Radius    Gap (D-2R)');
    txt_lines{end+1} = repmat('─', 1, 40);
    for i = 1:length(pair_distances)
        txt_lines{end+1} = sprintf(' %d      %.2f      %.2f', i, pair_radii(i), pair_gaps(i));
    end
    txt_lines{end+1} = '';
    txt_lines{end+1} = sprintf('Mean Gap:         %.2f cm', mean(pair_gaps));
    txt_lines{end+1} = sprintf('Min Gap:          %.2f cm', min(pair_gaps));
    
    text(0.05, 0.95, txt_lines, 'FontSize', 11, 'FontName', 'Courier', ...
        'VerticalAlignment', 'top', 'Interpreter', 'none')
    
    % Save if requested
    if save_fig
        if ~exist(output_dir, 'dir')
            mkdir(output_dir);
        end
        saveas(fig, fullfile(output_dir, [game_name '_visualization.png']));
    end
end

function [pair_distances, pair_radii, pair_gaps] = calculate_pair_distances_and_gaps(obstacles, obstacle_radii, num_pairs)
    pair_distances = zeros(num_pairs, 1);
    pair_radii = zeros(num_pairs, 1);
    pair_gaps = zeros(num_pairs, 1);
    
    for i = 1:num_pairs
        idx1 = 2*i-1; idx2 = 2*i;
        if idx2 <= size(obstacles, 1)
            % Distance between centers
            pair_distances(i) = norm(obstacles(idx2,:) - obstacles(idx1,:));
            
            % Average radius (assuming both obstacles in pair have same radius)
            pair_radii(i) = (obstacle_radii(idx1) + obstacle_radii(idx2)) / 2;
            
            % Gap = Distance - 2*Radius (clearance between obstacles)
            pair_gaps(i) = pair_distances(i) - (obstacle_radii(idx1) + obstacle_radii(idx2));
        end
    end
end

function [min_clearance, avg_clearance, clearance_profile] = ...
        calculate_clearance_profile(path, obstacles, obstacle_radii)
    clearance_profile = zeros(size(path, 1), 1);
    for i = 1:size(path, 1)
        obstacle_dists = sqrt(sum((obstacles - path(i,:)).^2, 2));
        clearances = obstacle_dists - obstacle_radii;
        clearance_profile(i) = min(clearances);
    end
    min_clearance = min(clearance_profile);
    avg_clearance = mean(clearance_profile);
end

function [curvature_factor, straight_distance] = ...
        calculate_path_curvature(path, X_s, X_e, data)
    path_length = sum(sqrt(sum(diff(path).^2, 2)));
    
    if isfield(data, 'Start_points') && isfield(data, 'End_points') && ...
       ~isempty(data.Start_points) && ~isempty(data.End_points)
        Start_points = data.Start_points;
        End_points = data.End_points;
        segmented_straight_distance = 0;
        for i = 1:size(Start_points, 1)
            segmented_straight_distance = segmented_straight_distance + ...
                norm(End_points(i,:) - Start_points(i,:));
        end
        straight_distance = segmented_straight_distance;
    else
        straight_distance = norm(X_e - X_s);
    end
    
    curvature_factor = (path_length - straight_distance) / straight_distance;
end

