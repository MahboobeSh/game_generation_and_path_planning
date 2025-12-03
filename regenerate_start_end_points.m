% ============================================================================
% REGENERATE START/END POINTS FOR EXISTING GAMES
% ============================================================================
% This script loads existing game files and regenerates only the start/end
% points while keeping the obstacle configurations unchanged.
%
% Usage:
%   1. Set the input_folder to where your existing games are
%   2. Set the output_folder (can be same as input to overwrite)
%   3. Run the script
% ============================================================================

clc
clear

% ============================================================================
% CONFIGURATION
% ============================================================================
% Input folder containing existing games
input_folder = "C:\Users\Mahboobe\OneDrive - University of Calgary\code\game_creation_and_fits\final_games";

% Output folder for updated games (set same as input_folder to overwrite)
output_folder = "C:\Users\Mahboobe\OneDrive - University of Calgary\code\game_creation_and_fits\final_games_updated";

% Which number of pairs to process (set to [] to process all)
pairs_to_process = [];  % e.g., [4, 5] for only 4 and 5 pairs, [] for all

% Overwrite existing files in output folder?
overwrite_existing = true;

% Show figures? (set to false for batch processing)
show_figures = false;

% ============================================================================
% START/END POINT PARAMETERS
% ============================================================================
start_x_min = -3;  % Can extend 3cm before play area
start_x_max = 0;   % Up to play area start
start_end_y_margin = 2.0;  % Minimum margin from top/bottom edges (cm)
rectangle_buffer = 2.5;  % Safety buffer around obstacles
min_distance_to_end_and_start = 2.5;  % Minimum distance from obstacles

% Approach angles (in degrees)
approach_angles = [90, 80, 75, 60, 45];

% Maximum attempts for start/end point generation
max_start_end_attempts = 20;

% ============================================================================
% FIND AND PROCESS GAMES
% ============================================================================
fprintf('=== Regenerate Start/End Points ===\n\n');

% Find all pair folders
if isempty(pairs_to_process)
    pair_folders = dir(fullfile(input_folder, '*pairs'));
else
    pair_folders = [];
    for p = pairs_to_process
        folder = dir(fullfile(input_folder, sprintf('%dpairs', p)));
        if ~isempty(folder)
            pair_folders = [pair_folders; folder];
        end
    end
end

total_processed = 0;
total_failed = 0;

for pf = 1:length(pair_folders)
    pairs_folder_name = pair_folders(pf).name;
    pairs_folder_path = fullfile(input_folder, pairs_folder_name);
    
    % Extract number of pairs from folder name
    number_of_pairs = str2double(regexp(pairs_folder_name, '\d+', 'match', 'once'));
    
    fprintf('Processing %s...\n', pairs_folder_name);
    
    % Create output folder if needed
    output_pairs_folder = fullfile(output_folder, pairs_folder_name);
    if ~exist(output_pairs_folder, 'dir')
        mkdir(output_pairs_folder);
    end
    
    % Find all .mat files in this folder
    mat_files = dir(fullfile(pairs_folder_path, '*.mat'));
    
    for mf = 1:length(mat_files)
        mat_filename = mat_files(mf).name;
        mat_filepath = fullfile(pairs_folder_path, mat_filename);
        
        % Check if output already exists
        output_filepath = fullfile(output_pairs_folder, mat_filename);
        if ~overwrite_existing && exist(output_filepath, 'file')
            fprintf('  Skipping %s (already exists)\n', mat_filename);
            continue;
        end
        
        % Load existing game
        try
            game_data = load(mat_filepath);
        catch
            fprintf('  ERROR loading %s\n', mat_filename);
            total_failed = total_failed + 1;
            continue;
        end
        
        % Extract variables
        x_range = game_data.x_range;
        y_range = game_data.y_range;
        obstacle = game_data.obstacle;  % This is 'centers'
        obstacle_radious = game_data.obstacle_radious;  % This is 'radii'
        
        centers = obstacle;
        radii = obstacle_radious';  % Transpose back to column
        
        % Calculate rectangles for constraint checking
        numCentersPerSet = 2;
        numSets = number_of_pairs;
        rectangles = zeros(numSets, 4);
        
        for i = 1:numSets
            startIndex = (i - 1) * numCentersPerSet + 1;
            endIndex = i * numCentersPerSet;
            set_centers = centers(startIndex:endIndex, :);
            set_radii = radii(startIndex:endIndex);
            
            xMin = min(set_centers(:,1) - set_radii);
            yMin = min(set_centers(:,2) - set_radii);
            xMax = max(set_centers(:,1) + set_radii);
            yMax = max(set_centers(:,2) + set_radii);
            
            width = xMax - xMin;
            height = yMax - yMin;
            rectangles(i, :) = [xMin, yMin, width, height];
        end
        
        % Extended range for end points
        end_x_min = x_range;
        end_x_max = x_range + 3;
        
        % ================================================================
        % REGENERATE START/END POINTS
        % ================================================================
        start_end_found = false;
        
        for attempt = 1:max_start_end_attempts
            
            % === START POINT ===
            point1 = centers(1, :);
            point2 = centers(2, :);
            midpoint_first = (point1 + point2) / 2;
            gate_angle = atan2(point2(2) - point1(2), point2(1) - point1(1));
            
            % X position varies by attempt
            if attempt == 1
                X_s_x = 0;
            elseif attempt <= 5
                X_s_x = -1.5 + rand() * 1.5;
            elseif attempt <= 10
                X_s_x = start_x_min + rand() * 2;
            else
                X_s_x = start_x_min + rand() * (start_x_max - start_x_min);
            end
            
            % Y-coordinate strategy
            if attempt <= 5
                angle_idx = attempt;
                approach_deg = approach_angles(angle_idx);
                approach_rad = deg2rad(approach_deg);
                approach_line_angle = gate_angle + approach_rad;
                approach_slope = tan(approach_line_angle);
                approach_intercept = midpoint_first(2) - approach_slope * midpoint_first(1);
                X_s_y = approach_slope * X_s_x + approach_intercept;
            elseif attempt <= 15
                if attempt <= 10
                    X_s_y = midpoint_first(2);
                else
                    variation = (rand() - 0.5) * 3.0;
                    X_s_y = midpoint_first(2) + variation;
                end
            else
                X_s_y = start_end_y_margin + (y_range - 2*start_end_y_margin) * rand();
            end
            
            X_s_y = max(start_end_y_margin, min(y_range - start_end_y_margin, X_s_y));
            X_s = [X_s_x, X_s_y];
            
            % === END POINT ===
            point1 = centers(end, :);
            point2 = centers(end-1, :);
            midpoint_last = (point1 + point2) / 2;
            gate_angle_end = atan2(point2(2) - point1(2), point2(1) - point1(1));
            
            % X position varies by attempt
            if attempt == 1
                X_e_x = x_range;
            elseif attempt <= 5
                X_e_x = x_range + rand() * 1.5;
            elseif attempt <= 10
                X_e_x = x_range + 1 + rand() * 2;
            else
                X_e_x = end_x_min + rand() * (end_x_max - end_x_min);
            end
            
            % Y-coordinate strategy
            if attempt <= 5
                angle_idx = attempt;
                approach_deg = approach_angles(angle_idx);
                approach_rad = deg2rad(approach_deg);
                approach_line_angle = gate_angle_end + approach_rad;
                approach_slope = tan(approach_line_angle);
                approach_intercept = midpoint_last(2) - approach_slope * midpoint_last(1);
                X_e_y = approach_slope * X_e_x + approach_intercept;
            elseif attempt <= 15
                if attempt <= 10
                    X_e_y = midpoint_last(2);
                else
                    variation = (rand() - 0.5) * 3.0;
                    X_e_y = midpoint_last(2) + variation;
                end
            else
                X_e_y = start_end_y_margin + (y_range - 2*start_end_y_margin) * rand();
            end
            
            X_e_y = max(start_end_y_margin, min(y_range - start_end_y_margin, X_e_y));
            X_e = [X_e_x, X_e_y];
            
            % === CHECK CONSTRAINTS ===
            start_end_valid = true;
            
            % Check rectangle buffer
            for i = 1:numSets
                rect = rectangles(i, :);
                expanded_rect = [rect(1) - rectangle_buffer, ...
                                 rect(2) - rectangle_buffer, ...
                                 rect(3) + 2*rectangle_buffer, ...
                                 rect(4) + 2*rectangle_buffer];
                
                if isPointInsideRectangle(X_s, expanded_rect)
                    start_end_valid = false;
                    break;
                end
                if isPointInsideRectangle(X_e, expanded_rect)
                    start_end_valid = false;
                    break;
                end
            end
            
            % Check distance from obstacles
            if start_end_valid
                num_obstacles = size(centers, 1);
                for i = 1:num_obstacles
                    obstacle_position = centers(i, :);
                    obstacle_radius = radii(i);
                    distance_to_start = norm(X_s - obstacle_position);
                    distance_to_end = norm(X_e - obstacle_position);
                    
                    if distance_to_start < (min_distance_to_end_and_start + obstacle_radius)
                        start_end_valid = false;
                        break;
                    end
                    if distance_to_end < (min_distance_to_end_and_start + obstacle_radius)
                        start_end_valid = false;
                        break;
                    end
                end
            end
            
            if start_end_valid
                start_end_found = true;
                break;
            end
        end
        
        if ~start_end_found
            fprintf('  FAILED to find valid start/end for %s\n', mat_filename);
            total_failed = total_failed + 1;
            continue;
        end
        
        % ================================================================
        % SAVE UPDATED GAME
        % ================================================================
        save(output_filepath, 'y_range', 'x_range', 'X_e', 'X_s', 'obstacle', 'obstacle_radious', 'number_of_pairs');
        
        % ================================================================
        % OPTIONALLY SAVE FIGURE
        % ================================================================
        if show_figures
            fig = figure('Visible', 'on');
        else
            fig = figure('Visible', 'off');
        end
        
        hold on;
        axis equal;
        colors = ['r', 'g', 'b', 'c', 'k', 'm'];
        
        for i = 1:numSets
            startIndex = (i - 1) * numCentersPerSet + 1;
            endIndex = i * numCentersPerSet;
            set_centers = centers(startIndex:endIndex, :);
            set_radii = radii(startIndex:endIndex);
            
            xMin = min(set_centers(:,1) - set_radii);
            yMin = min(set_centers(:,2) - set_radii);
            xMax = max(set_centers(:,1) + set_radii);
            yMax = max(set_centers(:,2) + set_radii);
            
            width = xMax - xMin;
            height = yMax - yMin;
            theta = linspace(0, 2*pi, 100);
            
            for j = 1:length(set_radii)
                fill(set_centers(j,1) + set_radii(j)*cos(theta), ...
                     set_centers(j,2) + set_radii(j)*sin(theta), ...
                     colors(i), 'LineStyle', 'none');
            end
            rectangle('Position', [xMin, yMin, width, height], 'EdgeColor', colors(i), 'LineWidth', 2);
        end
        
        plot(X_s(1,1), X_s(1,2), 'ro', 'MarkerSize', 10);
        plot(X_e(1,1), X_e(1,2), 'ro', 'MarkerSize', 10);
        
        xlabel('X-coordinate');
        ylabel('Y-coordinate');
        title(sprintf('Obstacle Sets Configuration (Number of Pairs: %d)', number_of_pairs));
        grid on;
        legend('Set 1', 'Set 2', 'Set 3', 'Location', 'bestoutside');
        hold off;
        
        % Save figure
        [~, name, ~] = fileparts(mat_filename);
        figure_filename = [name, '.png'];
        figure_path = fullfile(output_pairs_folder, figure_filename);
        saveas(fig, figure_path);
        close(fig);
        
        total_processed = total_processed + 1;
        fprintf('  Updated %s\n', mat_filename);
    end
end

% ============================================================================
% SUMMARY
% ============================================================================
fprintf('\n=== Summary ===\n');
fprintf('Total games processed: %d\n', total_processed);
fprintf('Total failed: %d\n', total_failed);
fprintf('Output folder: %s\n', output_folder);
fprintf('Done!\n');

