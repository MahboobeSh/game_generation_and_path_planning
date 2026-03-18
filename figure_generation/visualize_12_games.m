% visualize_12_games.m
% Simple visualization of 12 games from the user study
% Shows obstacles, start point (green), and end point (red) for each game

clear; close all; clc;

%% Configuration
% Define which games to show (set numbers from the study)
% You can modify these to show different games
game_sets = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];  % Games 1-12

% Path to game files - study games location
game_folder = 'C:\Users\Mahboobe\OneDrive - University of Calgary\user_study_info\study_information\game_sets_data\final_games_solved';

%% Create figure
fig = figure('Position', [100, 100, 1200, 1600], 'Color', 'w');
fig.Name = 'Study Games';

%% Plot each game in a 4x3 grid
for i = 1:length(game_sets)
    set_num = game_sets(i);
    
    % Load game file
    filename = sprintf('set_%d_fit.mat', set_num);
    file_path = fullfile(game_folder, filename);
    
    if ~exist(file_path, 'file')
        fprintf('Warning: File not found: %s\n', filename);
        continue;
    end
    
    data = load(file_path);
    
    % Create subplot
    subplot(4, 3, i);
    hold on;
    
    % Plot obstacles with filled circles (semi-transparent) - consistent style
    for j = 1:size(data.obstacle, 1)
        theta = linspace(0, 2*pi, 100);
        x_circle = data.obstacle(j, 1) + data.obstacle_radious(j) * cos(theta);
        y_circle = data.obstacle(j, 2) + data.obstacle_radious(j) * sin(theta);
        % Filled circle with transparency
        fill(x_circle, y_circle, [1, 0.3, 0.3], 'FaceAlpha', 0.5, ...
            'EdgeColor', 'k', 'LineWidth', 1.5);
    end
    
    % Plot start point (green filled circle with black edge)
    plot(data.X_s(1), data.X_s(2), 'o', 'MarkerSize', 10, ...
        'MarkerFaceColor', [0.2, 0.8, 0.2], 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
    
    % Plot end point (red filled circle with black edge)
    plot(data.X_e(1), data.X_e(2), 'o', 'MarkerSize', 10, ...
        'MarkerFaceColor', [0.9, 0.2, 0.2], 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
    
    % Formatting
    title(sprintf('Game %d', set_num), 'FontSize', 11, 'FontWeight', 'bold');
    xlabel('X (cm)', 'FontSize', 9);
    ylabel('Y (cm)', 'FontSize', 9);
    xlim([-3, 51]);
    ylim([-3, 30]);
    pbaspect([54 33 1]);  % Keep proper aspect ratio for the workspace
    grid on;
    box on;
    set(gca, 'FontSize', 9, 'Color', 'w');  % White background
    ax = gca;
    ax.GridColor = [0.15, 0.15, 0.15];  % Dark gray grid lines
    ax.GridAlpha = 0.3;  % Lighter grid
    
    hold off;
end

%% Add overall title
sgtitle('User Study Games', 'FontSize', 14, 'FontWeight', 'bold');

%% Save figure
script_dir = fileparts(mfilename('fullpath'));
output_folder = fullfile(script_dir, '..', 'logs');  % Save in logs folder
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

output_file = fullfile(output_folder, '12_study_games.png');
print(fig, output_file, '-dpng', '-r300');

% Also save as EPS for thesis (vector format - better quality for publications)
output_file_eps = fullfile(output_folder, '12_study_games.eps');
print(fig, output_file_eps, '-depsc', '-r300');

fprintf('\nFigure saved to:\n');
fprintf('  PNG: %s\n', output_file);
fprintf('  EPS: %s\n', output_file_eps);
fprintf('Visualization complete!\n');
