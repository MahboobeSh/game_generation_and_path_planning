% ============================================================================
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

% Which pairs to process (set to specific number, e.g., 5)
number_of_pairs_to_process = 5;

% Number of options to generate for each game
num_options = 6;

% ============================================================================
% PARAMETERS
% ============================================================================
start_x_min = -3;
start_x_max = 0;
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
mat_files = dir(fullfile(input_pairs_folder, '*.mat'));

fprintf('=== Interactive Start/End Point Selection ===\n\n');
fprintf('Found %d games in %s\n\n', length(mat_files), pairs_folder_name);
fprintf('Instructions:\n');
fprintf('  - Enter option number (1-%d) to save that configuration\n', num_options);
fprintf('  - Enter 0 to skip this game\n');
fprintf('  - Enter "s" to stop processing\n\n');

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
    options_valid = false(num_options, 1);
    
    for opt = 1:num_options
        % Try different approaches for each option
        max_attempts = 50;
        
        for attempt = 1:max_attempts
            % === START POINT ===
            point1 = centers(1, :);
            point2 = centers(2, :);
            midpoint_first = (point1 + point2) / 2;
            gate_angle = atan2(point2(2) - point1(2), point2(1) - point1(1));
            
            % Different X positions for different options
            if opt == 1
                X_s_x = 0;
            elseif opt == 2
                X_s_x = -1;
            elseif opt == 3
                X_s_x = -2;
            else
                X_s_x = start_x_min + rand() * (start_x_max - start_x_min);
            end
            
            % Different angles for different options
            if opt <= length(approach_angles)
                approach_deg = approach_angles(opt);
            else
                approach_deg = 45 + rand() * 45;  % Random between 45-90
            end
            approach_rad = deg2rad(approach_deg);
            approach_line_angle = gate_angle + approach_rad;
            approach_slope = tan(approach_line_angle);
            approach_intercept = midpoint_first(2) - approach_slope * midpoint_first(1);
            X_s_y = approach_slope * X_s_x + approach_intercept;
            
            % Clamp Y
            X_s_y = max(start_end_y_margin, min(y_range - start_end_y_margin, X_s_y));
            X_s = [X_s_x, X_s_y];
            
            % === END POINT ===
            point1 = centers(end, :);
            point2 = centers(end-1, :);
            midpoint_last = (point1 + point2) / 2;
            gate_angle_end = atan2(point2(2) - point1(2), point2(1) - point1(1));
            
            % Different X positions for different options
            if opt == 1
                X_e_x = x_range;
            elseif opt == 2
                X_e_x = x_range + 1;
            elseif opt == 3
                X_e_x = x_range + 2;
            else
                X_e_x = end_x_min + rand() * (end_x_max - end_x_min);
            end
            
            % Same angle approach for end
            approach_line_angle = gate_angle_end + approach_rad;
            approach_slope = tan(approach_line_angle);
            approach_intercept = midpoint_last(2) - approach_slope * midpoint_last(1);
            X_e_y = approach_slope * X_e_x + approach_intercept;
            
            % Clamp Y
            X_e_y = max(start_end_y_margin, min(y_range - start_end_y_margin, X_e_y));
            X_e = [X_e_x, X_e_y];
            
            % === CHECK CONSTRAINTS ===
            valid = true;
            
            % Check rectangle buffer
            for i = 1:numSets
                rect = rectangles(i, :);
                expanded_rect = [rect(1) - rectangle_buffer, ...
                                 rect(2) - rectangle_buffer, ...
                                 rect(3) + 2*rectangle_buffer, ...
                                 rect(4) + 2*rectangle_buffer];
                
                if isPointInsideRectangle(X_s, expanded_rect) || isPointInsideRectangle(X_e, expanded_rect)
                    valid = false;
                    break;
                end
            end
            
            % Check distance from obstacles
            if valid
                num_obstacles = size(centers, 1);
                for i = 1:num_obstacles
                    obstacle_position = centers(i, :);
                    obstacle_radius = radii(i);
                    
                    if norm(X_s - obstacle_position) < (min_distance_to_end_and_start + obstacle_radius) || ...
                       norm(X_e - obstacle_position) < (min_distance_to_end_and_start + obstacle_radius)
                        valid = false;
                        break;
                    end
                end
            end
            
            if valid
                options_start(opt, :) = X_s;
                options_end(opt, :) = X_e;
                options_valid(opt) = true;
                break;
            end
        end
    end
    
    % Count valid options
    num_valid = sum(options_valid);
    if num_valid == 0
        fprintf('  No valid options found, skipping...\n');
        continue;
    end
    
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
        if options_valid(opt)
            X_s = options_start(opt, :);
            X_e = options_end(opt, :);
            
            % Draw path line
            plot([X_s(1), X_e(1)], [X_s(2), X_e(2)], '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1);
            
            % Draw start/end points
            plot(X_s(1), X_s(2), 'o', 'MarkerSize', 12, 'LineWidth', 3, ...
                 'Color', option_colors{opt}, 'MarkerFaceColor', option_colors{opt});
            plot(X_e(1), X_e(2), 's', 'MarkerSize', 12, 'LineWidth', 3, ...
                 'Color', option_colors{opt}, 'MarkerFaceColor', option_colors{opt});
            
            % Add labels
            text(X_s(1), X_s(2) + 2, 'S', 'FontSize', 12, 'FontWeight', 'bold', ...
                 'HorizontalAlignment', 'center', 'Color', option_colors{opt});
            text(X_e(1), X_e(2) + 2, 'E', 'FontSize', 12, 'FontWeight', 'bold', ...
                 'HorizontalAlignment', 'center', 'Color', option_colors{opt});
            
            title_str = sprintf('Option %d (Angle: %d°)\nStart: (%.1f, %.1f)  End: (%.1f, %.1f)', ...
                               opt, approach_angles(min(opt, length(approach_angles))), ...
                               X_s(1), X_s(2), X_e(1), X_e(2));
        else
            title_str = sprintf('Option %d - INVALID', opt);
        end
        
        title(title_str, 'FontSize', 10);
        xlabel('X');
        ylabel('Y');
        grid on;
        xlim([-5, x_range + 5]);
        ylim([-2, y_range + 2]);
        hold off;
    end
    
    sgtitle(sprintf('Game: %s - Select an option (1-%d), 0 to skip, s to stop', ...
                    mat_filename, num_options), 'FontSize', 14, 'FontWeight', 'bold');
    
    % ================================================================
    % GET USER INPUT
    % ================================================================
    drawnow;  % Ensure figure is displayed
    
    while true
        choice = input(sprintf('  Enter choice (1-%d, 0=skip, s=stop): ', num_options), 's');
        
        if strcmpi(choice, 's')
            fprintf('\nStopping...\n');
            close(fig);
            break;
        end
        
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
                
                plot(X_s(1), X_s(2), 'ro', 'MarkerSize', 10);
                plot(X_e(1), X_e(2), 'ro', 'MarkerSize', 10);
                
                xlabel('X-coordinate');
                ylabel('Y-coordinate');
                title(sprintf('Obstacle Sets Configuration (Number of Pairs: %d)', number_of_pairs));
                grid on;
                legend('Set 1', 'Set 2', 'Set 3', 'Location', 'bestoutside');
                hold off;
                
                saveas(fig_save, fullfile(output_pairs_folder, figure_filename));
                close(fig_save);
                
                fprintf('  Saved option %d!\n', choice_num);
                total_saved = total_saved + 1;
                close(fig);
                break;
            else
                fprintf('  Option %d is invalid, choose another.\n', choice_num);
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

