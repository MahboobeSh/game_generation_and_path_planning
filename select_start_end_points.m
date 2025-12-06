0% ============================================================================
% INTERACTIVE START/END POINT SELECTION
% ============================================================================
% This script loads existing games and shows multiple start/end point options
% You can visually compare them and choose which one to save.
%
% Usage:
%   1. Set the input_folder and output_folder
%   2. Run the script
%   3. For each game, you'll see multiple options
%   4. Enter the option number you like (1-6)
%   5. Or enter 0 to skip, 's' to stop
% ============================================================================

clc
clear
close all

% ============================================================================
% CONFIGURATION
% ============================================================================
input_folder = "C:\Users\Mahboobe\OneDrive - University of Calgary\code\game_creation_and_fits\final_games";
output_folder = "C:\Users\Mahboobe\OneDrive - University of Calgary\code\game_creation_and_fits\selected_games";
input_folder = '/home/mahboobe/Desktop/game_generation_and_path_planning/new_games/selected_games_3';
output_folder = '/home/mahboobe/Desktop/game_generation_and_path_planning/new_games/selected_games_temp';
% Which pairs to process (set to specific number, e.g., 5)
number_of_pairs_to_process = 4;

% OPTIONAL: Specify a set number to show options for just that game
% Leave empty [] to process all games, or set to a number (e.g., 44)
specific_set_number = [110];  % Set to [] for all games, or specific number like 44

% Number of options to generate for each game
num_options = 6;

% ============================================================================
% PARAMETERS
% ============================================================================
start_x_min = -3;    % Start point can extend 3cm before play area
start_x_max = 0;     % Up to play area boundary
% end_x_min and end_x_max will be set after loading game data (based on x_range)
start_end_y_margin = 2.0;
rectangle_buffer = 2.5;
min_distance_to_end_and_start = 2.5;
approach_angles = [90, 80, 75, 60, 45, 30];

% ============================================================================
% SETUP OUTPUT FOLDER
% ============================================================================
pairs_folder_name = sprintf('%dpairs', number_of_pairs_to_process);
output_pairs_folder = fullfile(output_folder, pairs_folder_name);
if ~exist(output_pairs_folder, 'dir')
    mkdir(output_pairs_folder);
end

% ============================================================================
% FIND GAMES TO PROCESS
% ============================================================================
input_pairs_folder = fullfile(input_folder, pairs_folder_name);

% Filter by specific set number if provided
if ~isempty(specific_set_number)
    mat_filename = sprintf('set_%d_%dpairs.mat', specific_set_number, number_of_pairs_to_process);
    mat_files = dir(fullfile(input_pairs_folder, mat_filename));
    if isempty(mat_files)
        error('Set %d not found in %s', specific_set_number, pairs_folder_name);
    end
    fprintf('=== Interactive Start/End Point Selection (Single Game) ===\n\n');
    fprintf('Game: %s\n\n', mat_filename);
else
    mat_files = dir(fullfile(input_pairs_folder, '*.mat'));
    fprintf('=== Interactive Start/End Point Selection ===\n\n');
    fprintf('Found %d games in %s\n\n', length(mat_files), pairs_folder_name);
end
fprintf('Instructions:\n');
fprintf('  - Enter option number (1-%d) to save that configuration\n', num_options);
fprintf('  - Enter "s1e2" to mix: start from option 1, end from option 2\n');
fprintf('  - Enter 0 to skip this game\n');
fprintf('  - Enter "s" to stop processing\n');
fprintf('  - ✓ = Valid point, ✗ = Invalid point\n\n');

total_saved = 0;
total_skipped = 0;

for mf = 1:length(mat_files)
    mat_filename = mat_files(mf).name;
    mat_filepath = fullfile(input_pairs_folder, mat_filename);
    
    fprintf('Game %d/%d: %s\n', mf, length(mat_files), mat_filename);
    
    % Load existing game
    try
        game_data = load(mat_filepath);
    catch
        fprintf('  ERROR loading file, skipping...\n');
        continue;
    end
    
    % Extract variables
    x_range = game_data.x_range;
    y_range = game_data.y_range;
    obstacle = game_data.obstacle;
    obstacle_radious = game_data.obstacle_radious;
    number_of_pairs = game_data.number_of_pairs;
    
    centers = obstacle;
    radii = obstacle_radious';
    
    % Calculate rectangles
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
        
        rectangles(i, :) = [xMin, yMin, xMax - xMin, yMax - yMin];
    end
    
    end_x_min = x_range;
    end_x_max = x_range + 3;
    
    % ================================================================
    % GENERATE MULTIPLE OPTIONS
    % ================================================================
    options_start = zeros(num_options, 2);
    options_end = zeros(num_options, 2);
    options_start_valid = false(num_options, 1);
    options_end_valid = false(num_options, 1);
    options_valid = false(num_options, 1);
    
    for opt = 1:num_options
        % Try different approaches for each option
        max_attempts = 50;
        
        for attempt = 1:max_attempts
            % === START POINT ===
            point1 = centers(1, :);
            point2 = centers(2, :);
            midpoint_first = (point1 + point2) / 2;
            
            % Calculate gate angle (angle of line connecting obstacle centers)
            gate_angle = atan2(point2(2) - point1(2), point2(1) - point1(1));
            
            % Different X positions for different options (explore full -3 to 0 range)
            if opt == 1
                X_s_x = 0;        % At boundary
            elseif opt == 2
                X_s_x = -1;       % 1cm before boundary
            elseif opt == 3
                X_s_x = -2;       % 2cm before boundary
            elseif opt == 4
                X_s_x = -3;       % Maximum extension
            elseif opt == 5
                X_s_x = -1.5;     % Mid-range
            else
                X_s_x = start_x_min + rand() * (start_x_max - start_x_min);  % Random in [-3, 0]
            end
            
            % Different angles for different options
            if opt <= length(approach_angles)
                approach_deg = approach_angles(opt);
            else
                approach_deg = 45 + rand() * 45;  % Random between 45-90
            end
            approach_rad = deg2rad(approach_deg);
            
            % EXACT COPY from create_obstacle_sets.m
            % Calculate approach line angle (perpendicular + deviation)
            approach_line_angle = gate_angle + approach_rad;
            approach_slope = tan(approach_line_angle);
            approach_intercept = midpoint_first(2) - approach_slope * midpoint_first(1);
            X_s_y = approach_slope * X_s_x + approach_intercept;
            
            % Check if result is valid (not NaN or Inf)
            if isnan(X_s_y) || isinf(X_s_y)
                % Fallback: use gate midpoint Y
                X_s_y = midpoint_first(2);
            end
            
            % Clamp Y
            X_s_y = max(start_end_y_margin, min(y_range - start_end_y_margin, X_s_y));
            X_s = [X_s_x, X_s_y];
            
            % === END POINT ===
            point1 = centers(end, :);
            point2 = centers(end-1, :);
            midpoint_last = (point1 + point2) / 2;
            
            % Calculate gate angle (angle of line connecting obstacle centers)
            gate_angle_end = atan2(point2(2) - point1(2), point2(1) - point1(1));
            
            % Different X positions for different options (explore full 48 to 51 range)
            if opt == 1
                X_e_x = x_range;        % At boundary (48)
            elseif opt == 2
                X_e_x = x_range + 1;    % 1cm after boundary (49)
            elseif opt == 3
                X_e_x = x_range + 2;    % 2cm after boundary (50)
            elseif opt == 4
                X_e_x = x_range + 3;    % Maximum extension (51)
            elseif opt == 5
                X_e_x = x_range + 1.5;  % Mid-range (49.5)
            else
                X_e_x = end_x_min + rand() * (end_x_max - end_x_min);  % Random in [48, 51]
            end
            
            % EXACT COPY from create_obstacle_sets.m
            % Calculate approach line angle (perpendicular + deviation)
            approach_line_angle = gate_angle_end + approach_rad;
            approach_slope = tan(approach_line_angle);
            approach_intercept = midpoint_last(2) - approach_slope * midpoint_last(1);
            X_e_y = approach_slope * X_e_x + approach_intercept;
            
            % Check if result is valid (not NaN or Inf)
            if isnan(X_e_y) || isinf(X_e_y)
                % Fallback: use gate midpoint Y
                X_e_y = midpoint_last(2);
            end
            
            % Clamp Y
            X_e_y = max(start_end_y_margin, min(y_range - start_end_y_margin, X_e_y));
            X_e = [X_e_x, X_e_y];
            
            % === CHECK CONSTRAINTS (Separate for Start and End) ===
            start_valid = true;
            end_valid = true;
            
            % Check rectangle buffer for START
            for i = 1:numSets
                rect = rectangles(i, :);
                expanded_rect = [rect(1) - rectangle_buffer, ...
                                 rect(2) - rectangle_buffer, ...
                                 rect(3) + 2*rectangle_buffer, ...
                                 rect(4) + 2*rectangle_buffer];
                
                if isPointInsideRectangle(X_s, expanded_rect)
                    start_valid = false;
                end
                if isPointInsideRectangle(X_e, expanded_rect)
                    end_valid = false;
                end
            end
            
            % Check distance from obstacles for START
            if start_valid
                num_obstacles = size(centers, 1);
                for i = 1:num_obstacles
                    obstacle_position = centers(i, :);
                    obstacle_radius = radii(i);
                    
                    if norm(X_s - obstacle_position) < (min_distance_to_end_and_start + obstacle_radius)
                        start_valid = false;
                        break;
                    end
                end
            end
            
            % Check distance from obstacles for END
            if end_valid
                num_obstacles = size(centers, 1);
                for i = 1:num_obstacles
                    obstacle_position = centers(i, :);
                    obstacle_radius = radii(i);
                    
                    if norm(X_e - obstacle_position) < (min_distance_to_end_and_start + obstacle_radius)
                        end_valid = false;
                        break;
                    end
                end
            end
            
            % Store start and end separately
            % Always store the values (for visualization)
            options_start(opt, :) = X_s;
            options_end(opt, :) = X_e;
            options_start_valid(opt) = start_valid;
            options_end_valid(opt) = end_valid;
            options_valid(opt) = start_valid && end_valid;
            
            % If at least one is valid, we're done
            if start_valid || end_valid
                break;
            end
            
            % If this is the last attempt, keep these values anyway
            if attempt == max_attempts
                break;
            end
        end
    end
    
    % Count valid options
    num_valid_pairs = sum(options_valid);
    num_valid_starts = sum(options_start_valid);
    num_valid_ends = sum(options_end_valid);
    
    if num_valid_starts == 0 && num_valid_ends == 0
        fprintf('  No valid start or end points found, skipping...\n');
        continue;
    end
    
    fprintf('  Valid pairs: %d, Valid starts: %d, Valid ends: %d\n', ...
            num_valid_pairs, num_valid_starts, num_valid_ends);
    
    % ================================================================
    % DISPLAY OPTIONS IN FIGURE
    % ================================================================
    fig = figure('Name', sprintf('Select Option - %s', mat_filename), ...
                 'Position', [50, 50, 1400, 900]);
    
    colors = ['r', 'g', 'b', 'c', 'k', 'm'];
    option_colors = {'r', 'b', 'g', 'm', 'c', [1 0.5 0]};  % Different colors for each option
    
    % Calculate subplot layout
    ncols = 3;
    nrows = 2;
    
    for opt = 1:num_options
        subplot(nrows, ncols, opt);
        hold on;
        axis equal;
        
        % Draw obstacles
        for i = 1:numSets
            startIndex = (i - 1) * numCentersPerSet + 1;
            endIndex = i * numCentersPerSet;
            set_centers = centers(startIndex:endIndex, :);
            set_radii = radii(startIndex:endIndex);
            
            xMin = min(set_centers(:,1) - set_radii);
            yMin = min(set_centers(:,2) - set_radii);
            xMax = max(set_centers(:,1) + set_radii);
            yMax = max(set_centers(:,2) + set_radii);
            
            theta = linspace(0, 2*pi, 100);
            for j = 1:length(set_radii)
                fill(set_centers(j,1) + set_radii(j)*cos(theta), ...
                     set_centers(j,2) + set_radii(j)*sin(theta), ...
                     colors(i), 'LineStyle', 'none');
            end
            rectangle('Position', [xMin, yMin, xMax-xMin, yMax-yMin], 'EdgeColor', colors(i), 'LineWidth', 1.5);
        end
        
        % Draw start/end points for this option
        X_s = options_start(opt, :);
        X_e = options_end(opt, :);
        
        % Draw path line (if both exist)
        if options_start_valid(opt) && options_end_valid(opt)
            plot([X_s(1), X_e(1)], [X_s(2), X_e(2)], '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1);
        elseif options_start_valid(opt) || options_end_valid(opt)
            plot([X_s(1), X_e(1)], [X_s(2), X_e(2)], '--', 'Color', [0.9 0.5 0.5], 'LineWidth', 1, 'LineStyle', ':');
        end
        
        % Draw START point
        if options_start_valid(opt)
            plot(X_s(1), X_s(2), 'o', 'MarkerSize', 12, 'LineWidth', 3, ...
                 'Color', option_colors{opt}, 'MarkerFaceColor', option_colors{opt});
            text(X_s(1), X_s(2) + 2, 'S', 'FontSize', 12, 'FontWeight', 'bold', ...
                 'HorizontalAlignment', 'center', 'Color', option_colors{opt});
            start_str = sprintf('Start: (%.1f, %.1f) ✓', X_s(1), X_s(2));
        else
            plot(X_s(1), X_s(2), 'x', 'MarkerSize', 10, 'LineWidth', 2, ...
                 'Color', [0.7 0.7 0.7]);
            start_str = sprintf('Start: (%.1f, %.1f) ✗', X_s(1), X_s(2));
        end
        
        % Draw END point
        if options_end_valid(opt)
            plot(X_e(1), X_e(2), 's', 'MarkerSize', 12, 'LineWidth', 3, ...
                 'Color', option_colors{opt}, 'MarkerFaceColor', option_colors{opt});
            text(X_e(1), X_e(2) + 2, 'E', 'FontSize', 12, 'FontWeight', 'bold', ...
                 'HorizontalAlignment', 'center', 'Color', option_colors{opt});
            end_str = sprintf('End: (%.1f, %.1f) ✓', X_e(1), X_e(2));
        else
            plot(X_e(1), X_e(2), 'x', 'MarkerSize', 10, 'LineWidth', 2, ...
                 'Color', [0.7 0.7 0.7]);
            end_str = sprintf('End: (%.1f, %.1f) ✗', X_e(1), X_e(2));
        end
        
        % Title based on validity
        if options_valid(opt)
            status = 'VALID';
        elseif options_start_valid(opt) && ~options_end_valid(opt)
            status = 'START ONLY';
        elseif ~options_start_valid(opt) && options_end_valid(opt)
            status = 'END ONLY';
        else
            status = 'INVALID';
        end
        
        title_str = sprintf('Option %d (%s) - Angle: %d°\n%s\n%s', ...
                           opt, status, approach_angles(min(opt, length(approach_angles))), ...
                           start_str, end_str);
        
        title(title_str, 'FontSize', 10);
        xlabel('X');
        ylabel('Y');
        grid on;
        xlim([-5, x_range + 5]);
        ylim([-2, y_range + 2]);
        hold off;
    end
    
    sgtitle(sprintf('Game: %s\nSelect option (1-%d), mix (e.g., "s1e2"), skip (0), stop (s)', ...
                    mat_filename, num_options), 'FontSize', 14, 'FontWeight', 'bold');
    
    % ================================================================
    % GET USER INPUT
    % ================================================================
    drawnow;  % Ensure figure is displayed
    
    while true
        choice = input(sprintf('  Enter choice (1-%d, s1e2=mix, 0=skip, s=stop): ', num_options), 's');
        
        if strcmpi(choice, 's')
            fprintf('\nStopping...\n');
            close(fig);
            break;
        end
        
        % Check for mixed selection (e.g., "s1e2")
        mixed = regexp(choice, 's(\d+)e(\d+)', 'tokens');
        if ~isempty(mixed)
            start_opt = str2double(mixed{1}{1});
            end_opt = str2double(mixed{1}{2});
            
            if start_opt >= 1 && start_opt <= num_options && ...
               end_opt >= 1 && end_opt <= num_options
                if options_start_valid(start_opt) && options_end_valid(end_opt)
                    % Save mixed selection
                    X_s = options_start(start_opt, :);
                    X_e = options_end(end_opt, :);
                    
                    output_filepath = fullfile(output_pairs_folder, mat_filename);
                    save(output_filepath, 'y_range', 'x_range', 'X_e', 'X_s', 'obstacle', 'obstacle_radious', 'number_of_pairs');
                    
                    % Save figure (same code as before, extracted to function later)
                    [~, name, ~] = fileparts(mat_filename);
                    figure_filename = [name, '.png'];
                    
                    fig_save = figure('Visible', 'off');
                    hold on;
                    axis equal;
                    
                    for i = 1:numSets
                        startIndex = (i - 1) * numCentersPerSet + 1;
                        endIndex = i * numCentersPerSet;
                        set_centers = centers(startIndex:endIndex, :);
                        set_radii = radii(startIndex:endIndex);
                        
                        xMin = min(set_centers(:,1) - set_radii);
                        yMin = min(set_centers(:,2) - set_radii);
                        xMax = max(set_centers(:,1) + set_radii);
                        yMax = max(set_centers(:,2) + set_radii);
                        
                        theta = linspace(0, 2*pi, 100);
                        for j = 1:length(set_radii)
                            fill(set_centers(j,1) + set_radii(j)*cos(theta), ...
                                 set_centers(j,2) + set_radii(j)*sin(theta), ...
                                 colors(i), 'LineStyle', 'none');
                        end
                        rectangle('Position', [xMin, yMin, xMax-xMin, yMax-yMin], 'EdgeColor', colors(i), 'LineWidth', 2);
                    end
                    
                    plot(X_s(1), X_s(2), 'go', 'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', 'g');
                    plot(X_e(1), X_e(2), 'bs', 'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', 'b');
                    plot([X_s(1), X_e(1)], [X_s(2), X_e(2)], '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1);
                    
                    xlabel('X-coordinate');
                    ylabel('Y-coordinate');
                    title(sprintf('Obstacle Sets Configuration (Pairs: %d, Start from Opt %d, End from Opt %d)', ...
                                  number_of_pairs, start_opt, end_opt));
                    grid on;
                    hold off;
                    
                    saveas(fig_save, fullfile(output_pairs_folder, figure_filename));
                    close(fig_save);
                    
                    fprintf('  Saved mixed: Start from option %d, End from option %d!\n', start_opt, end_opt);
                    total_saved = total_saved + 1;
                    close(fig);
                    break;
                else
                    if ~options_start_valid(start_opt)
                        fprintf('  Start option %d is invalid!\n', start_opt);
                    end
                    if ~options_end_valid(end_opt)
                        fprintf('  End option %d is invalid!\n', end_opt);
                    end
                end
            else
                fprintf('  Invalid option numbers, try again.\n');
            end
            continue;
        end
        
        % Standard single option selection
        choice_num = str2double(choice);
        
        if choice_num == 0
            fprintf('  Skipped.\n');
            total_skipped = total_skipped + 1;
            close(fig);
            break;
        elseif choice_num >= 1 && choice_num <= num_options
            if options_valid(choice_num)
                % Save the selected option
                X_s = options_start(choice_num, :);
                X_e = options_end(choice_num, :);
                
                output_filepath = fullfile(output_pairs_folder, mat_filename);
                save(output_filepath, 'y_range', 'x_range', 'X_e', 'X_s', 'obstacle', 'obstacle_radious', 'number_of_pairs');
                
                % Save figure
                [~, name, ~] = fileparts(mat_filename);
                figure_filename = [name, '.png'];
                
                % Create clean figure for saving
                fig_save = figure('Visible', 'off');
                hold on;
                axis equal;
                
                for i = 1:numSets
                    startIndex = (i - 1) * numCentersPerSet + 1;
                    endIndex = i * numCentersPerSet;
                    set_centers = centers(startIndex:endIndex, :);
                    set_radii = radii(startIndex:endIndex);
                    
                    xMin = min(set_centers(:,1) - set_radii);
                    yMin = min(set_centers(:,2) - set_radii);
                    xMax = max(set_centers(:,1) + set_radii);
                    yMax = max(set_centers(:,2) + set_radii);
                    
                    theta = linspace(0, 2*pi, 100);
                    for j = 1:length(set_radii)
                        fill(set_centers(j,1) + set_radii(j)*cos(theta), ...
                             set_centers(j,2) + set_radii(j)*sin(theta), ...
                             colors(i), 'LineStyle', 'none');
                    end
                    rectangle('Position', [xMin, yMin, xMax-xMin, yMax-yMin], 'EdgeColor', colors(i), 'LineWidth', 2);
                end
                
                plot(X_s(1), X_s(2), 'go', 'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', 'g');
                plot(X_e(1), X_e(2), 'bs', 'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', 'b');
                plot([X_s(1), X_e(1)], [X_s(2), X_e(2)], '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1);
                
                xlabel('X-coordinate');
                ylabel('Y-coordinate');
                title(sprintf('Obstacle Sets Configuration (Number of Pairs: %d)', number_of_pairs));
                grid on;
                hold off;
                
                saveas(fig_save, fullfile(output_pairs_folder, figure_filename));
                close(fig_save);
                
                fprintf('  Saved option %d!\n', choice_num);
                total_saved = total_saved + 1;
                close(fig);
                break;
            else
                fprintf('  Option %d is not fully valid. Use mixed selection (e.g., s1e2) if needed.\n', choice_num);
            end
        else
            fprintf('  Invalid choice, try again.\n');
        end
    end
    
    % Check if user wants to stop
    if strcmpi(choice, 's')
        break;
    end
end

% ============================================================================
% SUMMARY
% ============================================================================
fprintf('\n=== Summary ===\n');
fprintf('Total saved: %d\n', total_saved);
fprintf('Total skipped: %d\n', total_skipped);
fprintf('Output folder: %s\n', output_pairs_folder);
fprintf('Done!\n');

