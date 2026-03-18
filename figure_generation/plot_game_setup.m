% Plot game setup showing start point, end point, and obstacles
% Uses consistent aesthetics: filled semi-transparent obstacles, proper colors
%
% Set-to-figure mapping:
%   set37  -> invalid: colliding obstacles
%   set361 -> invalid: too close obstacle pair
%   set351 -> invalid: too far obstacle pairs
%   set453 -> invalid: too close to end point
%   set451 -> valid game (default)
%   set33  -> first valid sample
clear; close all; clc;

% ============================================================================
% CONFIGURATION
% ============================================================================
% Set which versions to generate:
%   'both'      - Generate gaps + simple versions
%   'gaps'      - Only version with gaps and legend
%   'simple'    - Only simple version (no gaps, no legend)
%   'annotated' - Version with P_s, P_e, P_m labels (math notation)
version_to_generate = 'annotated';  % OPTIONS: 'both', 'gaps', 'simple', 'annotated'

% Set whether to save figures or just display them
save_figures = true;  % true = save to files, false = only display

% Generate all invalid game samples? If true, ignores version_to_generate
% and generates simple plots for all invalid sets plus the valid sample.
generate_invalid_samples = false;

% Data folder
data_folder = "C:\Users\Mahboobe\OneDrive - University of Calgary\code\game_code\temp-figure";

% Output folder setup
script_dir = fileparts(mfilename('fullpath'));
output_folder = fullfile(script_dir, '..', 'logs');
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

% ============================================================================
% Generate figures
% ============================================================================
if generate_invalid_samples
    game_sets = {
        'set37',  'game_sample_invalid_coliding_obstacles';
        'set361', 'game_sample_invalid_too_close_obstacle_pair';
        'set351', 'game_sample_invalid_too_far_obstacle_pair';
        'set453', 'game_sample_invalid_too_close_to_end_point';
        'set33',  'game_sample_valid';
    };
    
    for g = 1:size(game_sets, 1)
        set_name = game_sets{g, 1};
        fig_name = game_sets{g, 2};
        mat_path = fullfile(data_folder, [set_name, '.mat']);
        
        fprintf('Loading %s -> %s\n', set_name, fig_name);
        data = load(mat_path);
        
        generate_simple_plot(data.X_s, data.X_e, data.obstacle, ...
            data.obstacle_radious, save_figures, output_folder, fig_name);
    end
else
    data = load("C:\Users\Mahboobe\OneDrive - University of Calgary\code\game_code\temp\set22.mat");
    X_s = data.X_s;
    X_e = data.X_e;
    obstacles = data.obstacle;
    obstacle_radii = data.obstacle_radious;
    
    if strcmp(version_to_generate, 'both') || strcmp(version_to_generate, 'gaps')
        generate_plot_with_gaps(X_s, X_e, obstacles, obstacle_radii, ...
            save_figures, output_folder);
    end
    
    if strcmp(version_to_generate, 'both') || strcmp(version_to_generate, 'simple')
        generate_simple_plot(X_s, X_e, obstacles, obstacle_radii, ...
            save_figures, output_folder, 'game_setup_plot_simple');
    end
    
    if strcmp(version_to_generate, 'annotated')
        generate_annotated_plot(X_s, X_e, obstacles, obstacle_radii, ...
            save_figures, output_folder);
    end
end

fprintf('\nVisualization complete!\n');

% ============================================================================
% FUNCTION: Annotated plot with P_s, P_e, P_m labels
% ============================================================================
function generate_annotated_plot(X_s, X_e, obstacles, obstacle_radii, save_figures, output_folder)
    figure_handle = figure('Position', [100, 100, 800, 600], 'Color', 'w');
    hold on;
    
    % Plot obstacles (semi-transparent red/pink, black edge)
    for i = 1:size(obstacles, 1)
        theta = linspace(0, 2*pi, 100);
        x_circle = obstacles(i, 1) + obstacle_radii(i) * cos(theta);
        y_circle = obstacles(i, 2) + obstacle_radii(i) * sin(theta);
        fill(x_circle, y_circle, [1, 0.3, 0.3], 'FaceAlpha', 0.5, ...
            'EdgeColor', 'k', 'LineWidth', 1.5);
    end
    
    % Compute middle points (midpoint of each obstacle pair)
    num_pairs = size(obstacles, 1) / 2;
    centers = zeros(num_pairs, 2);
    for i = 1:num_pairs
        idx = (i-1)*2 + 1;
        centers(i, :) = mean(obstacles(idx:idx+1, :), 1);
    end
    
    % Plot middle points (magenta filled circle, black edge)
    for i = 1:num_pairs
        plot(centers(i,1), centers(i,2), 'o', 'MarkerSize', 10, ...
            'MarkerFaceColor', [0.85, 0.2, 0.85], 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
        text(centers(i,1) + 0.4, centers(i,2), sprintf('P_{m%d}', i), ...
            'FontSize', 11, 'FontWeight', 'bold');
    end
    
    % Plot start point (green filled circle, black edge)
    plot(X_s(1), X_s(2), 'o', 'MarkerSize', 10, ...
        'MarkerFaceColor', [0.2, 0.8, 0.2], 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
    text(X_s(1) + 0.5, X_s(2), 'P_{s}', 'FontSize', 11, 'FontWeight', 'bold');
    
    % Plot end point (red filled circle, black edge)
    plot(X_e(1), X_e(2), 'o', 'MarkerSize', 10, ...
        'MarkerFaceColor', [0.9, 0.2, 0.2], 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
    text(X_e(1) + 0.5, X_e(2), 'P_{e}', 'FontSize', 11, 'FontWeight', 'bold');
    
    % Configure plot appearance
    xlabel('X (cm)', 'FontSize', 11);
    ylabel('Y (cm)', 'FontSize', 11);
    box on;
    axis([0 12 0 9]);
    daspect([1 1 1]);
    xticks(0:2:12);
    yticks(0:2:8);
    set(gca, 'FontSize', 9, 'Color', 'w');
    hold off;
    
    if save_figures
        fig_name = 'game_setup_annotated';
        print(figure_handle, fullfile(output_folder, [fig_name, '.png']), '-dpng', '-r300');
        print(figure_handle, fullfile(output_folder, [fig_name, '.pdf']), '-dpdf', '-r300');
        fprintf('  Saved: %s (.png, .pdf)\n', fig_name);
    else
        fprintf('  Displayed: annotated version (not saved)\n');
    end
end

% ============================================================================
% FUNCTION: Plot with gaps and legend
% ============================================================================
function generate_plot_with_gaps(X_s, X_e, obstacles, obstacle_radii, save_figures, output_folder)
    figure_handle = figure('Position', [100, 100, 800, 600], 'Color', 'w');
    hold on;
    
    % Highlight gaps between obstacle pairs as shaded rectangles
    num_pairs = size(obstacles, 1) / 2;
    for pair_idx = 1:num_pairs
        obs1_idx = 2 * pair_idx - 1;
        obs2_idx = 2 * pair_idx;
        
        center1 = obstacles(obs1_idx, :);
        center2 = obstacles(obs2_idx, :);
        radius1 = obstacle_radii(obs1_idx);
        radius2 = obstacle_radii(obs2_idx);
        
        direction = center2 - center1;
        distance = norm(direction);
        direction_unit = direction / distance;
        perp_unit = [-direction_unit(2), direction_unit(1)];
        
        edge1 = center1 + radius1 * direction_unit;
        edge2 = center2 - radius2 * direction_unit;
        rect_width = (radius1 + radius2) / 2;
        
        p1 = edge1 + rect_width * perp_unit;
        p2 = edge1 - rect_width * perp_unit;
        p3 = edge2 - rect_width * perp_unit;
        p4 = edge2 + rect_width * perp_unit;
        
        fill([p1(1), p2(1), p3(1), p4(1)], [p1(2), p2(2), p3(2), p4(2)], ...
            [0.3, 0.7, 0.9], 'FaceAlpha', 0.3, 'EdgeColor', [0, 0.4, 0.7], ...
            'LineWidth', 1.5, 'LineStyle', '--');
    end
    
    % Plot obstacles (semi-transparent red/pink)
    for i = 1:size(obstacles, 1)
        theta = linspace(0, 2*pi, 100);
        x_circle = obstacles(i, 1) + obstacle_radii(i) * cos(theta);
        y_circle = obstacles(i, 2) + obstacle_radii(i) * sin(theta);
        fill(x_circle, y_circle, [1, 0.3, 0.3], 'FaceAlpha', 0.5, ...
            'EdgeColor', 'k', 'LineWidth', 1.5);
    end
    
    % Plot start point
    plot(X_s(1), X_s(2), 'o', 'MarkerSize', 10, ...
        'MarkerFaceColor', [0.2, 0.8, 0.2], 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
    text(X_s(1) + 0.5, X_s(2), 'Start', 'FontSize', 11, 'FontWeight', 'bold');
    
    % Plot end point
    plot(X_e(1), X_e(2), 'o', 'MarkerSize', 10, ...
        'MarkerFaceColor', [0.9, 0.2, 0.2], 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
    text(X_e(1) + 0.5, X_e(2), 'End', 'FontSize', 11, 'FontWeight', 'bold');
    
    % Legend
    h_obstacle = fill(NaN, NaN, [1, 0.3, 0.3], 'FaceAlpha', 0.5, 'EdgeColor', 'k', 'LineWidth', 1.5);
    h_gap = fill(NaN, NaN, [0.3, 0.7, 0.9], 'FaceAlpha', 0.3, 'EdgeColor', [0, 0.4, 0.7], 'LineWidth', 1.5, 'LineStyle', '--');
    h_start = plot(NaN, NaN, 'o', 'MarkerSize', 8, 'MarkerFaceColor', [0.2, 0.8, 0.2], 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
    h_end = plot(NaN, NaN, 'o', 'MarkerSize', 8, 'MarkerFaceColor', [0.9, 0.2, 0.2], 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
    legend([h_start, h_end, h_obstacle, h_gap], {'Start Point', 'End Point', 'Obstacles', 'Obstacle Pair Gaps'}, ...
        'Location', 'southeast', 'FontSize', 9);
    
    xlabel('X (cm)', 'FontSize', 11);
    ylabel('Y (cm)', 'FontSize', 11);
    box on;
    axis([0 12 0 9]);
    daspect([1 1 1]);
    xticks(0:2:12);
    yticks(0:2:8);
    set(gca, 'FontSize', 9, 'Color', 'w');
    hold off;
    
    if save_figures
        fig_name = 'game_setup_plot_with_gaps';
        print(figure_handle, fullfile(output_folder, [fig_name, '.png']), '-dpng', '-r300');
        print(figure_handle, fullfile(output_folder, [fig_name, '.pdf']), '-dpdf', '-r300');
        fprintf('  Saved: %s (.png, .pdf)\n', fig_name);
    else
        fprintf('  Displayed: version with gaps (not saved)\n');
    end
end

% ============================================================================
% FUNCTION: Simple plot without gaps or legend
% ============================================================================
function generate_simple_plot(X_s, X_e, obstacles, obstacle_radii, save_figures, output_folder, fig_name)
    figure_handle = figure('Position', [100, 100, 800, 600], 'Color', 'w');
    hold on;
    
    % Plot obstacles (semi-transparent red/pink)
    for i = 1:size(obstacles, 1)
        theta = linspace(0, 2*pi, 100);
        x_circle = obstacles(i, 1) + obstacle_radii(i) * cos(theta);
        y_circle = obstacles(i, 2) + obstacle_radii(i) * sin(theta);
        fill(x_circle, y_circle, [1, 0.3, 0.3], 'FaceAlpha', 0.5, ...
            'EdgeColor', 'k', 'LineWidth', 1.5);
    end
    
    % Plot start point
    plot(X_s(1), X_s(2), 'o', 'MarkerSize', 10, ...
        'MarkerFaceColor', [0.2, 0.8, 0.2], 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
    text(X_s(1) + 0.5, X_s(2), 'Start', 'FontSize', 11, 'FontWeight', 'bold');
    
    % Plot end point
    plot(X_e(1), X_e(2), 'o', 'MarkerSize', 10, ...
        'MarkerFaceColor', [0.9, 0.2, 0.2], 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
    text(X_e(1) + 0.5, X_e(2), 'End', 'FontSize', 11, 'FontWeight', 'bold');
    
    xlabel('X (cm)', 'FontSize', 11);
    ylabel('Y (cm)', 'FontSize', 11);
    box on;
    axis([0 12 0 9]);
    daspect([1 1 1]);
    xticks(0:2:12);
    yticks(0:2:8);
    set(gca, 'FontSize', 9, 'Color', 'w');
    hold off;
    
    if save_figures
        print(figure_handle, fullfile(output_folder, [fig_name, '.png']), '-dpng', '-r300');
        print(figure_handle, fullfile(output_folder, [fig_name, '.pdf']), '-dpdf', '-r300');
        fprintf('  Saved: %s (.png, .pdf)\n', fig_name);
    else
        fprintf('  Displayed: %s (not saved)\n', fig_name);
    end
end
