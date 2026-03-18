% Plot game notations - shows each obstacle with its label (O_i),
% center point, and radius line (r_j) where j is the pair index
% Uses consistent aesthetics

clear; close all; clc;

% ============================================================================
% CONFIGURATION
% ============================================================================
save_figures = true;  % true = save to files, false = only display

% Load the data from the .mat file
data = load("C:\Users\Mahboobe\OneDrive - University of Calgary\code\game_code\temp\set22.mat");
X_s = data.X_s;
X_e = data.X_e;
obstacles = data.obstacle;
obstacle_radii = data.obstacle_radious;

num_obstacles = size(obstacles, 1);
num_pairs = num_obstacles / 2;

% Output folder setup
script_dir = fileparts(mfilename('fullpath'));
output_folder = fullfile(script_dir, '..', 'logs');
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

% Create figure
figure_handle = figure('Position', [100, 100, 800, 600], 'Color', 'w');
hold on;

% Radius line angles per obstacle (vary to avoid overlap)
radius_angles = [5*pi/4, ...  % O1: lower-left
                 -pi/4,  ...  % O2: lower-right
                 -pi/3,  ...  % O3: lower-right
                 pi/6,   ...  % O4: upper-right
                 -pi/6,  ...  % O5: lower-right
                 pi/4];       % O6: upper-right
% Extend if more obstacles than expected
if num_obstacles > length(radius_angles)
    extra_angles = linspace(0, 2*pi, num_obstacles - length(radius_angles) + 1);
    radius_angles = [radius_angles, extra_angles(1:end-1)];
end

% Plot each obstacle
for i = 1:num_obstacles
    cx = obstacles(i, 1);
    cy = obstacles(i, 2);
    r  = obstacle_radii(i);
    pair_idx = ceil(i / 2);
    
    % Draw filled circle
    theta = linspace(0, 2*pi, 100);
    x_circle = cx + r * cos(theta);
    y_circle = cy + r * sin(theta);
    fill(x_circle, y_circle, [1, 0.3, 0.3], 'FaceAlpha', 0.5, ...
        'EdgeColor', 'k', 'LineWidth', 1.5);
    
    % Draw center dot
    plot(cx, cy, '.', 'MarkerSize', 10, 'Color', 'k');
    
    % Draw radius line from center to edge
    angle = radius_angles(i);
    rx = cx + r * cos(angle);
    ry = cy + r * sin(angle);
    plot([cx, rx], [cy, ry], 'k-', 'LineWidth', 1.2);
    
    % Add obstacle label (O_i) - placed below for O2, O3, O4; above for others
    if ismember(i, [2, 3, 4])
        text(cx, cy - r - 0.3, sprintf('O_{%d}', i), ...
            'FontSize', 11, 'FontWeight', 'bold', 'Color', 'k', ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');
    else
        text(cx, cy + r + 0.3, sprintf('O_{%d}', i), ...
            'FontSize', 11, 'FontWeight', 'bold', 'Color', 'k', ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
    end
    
    % Add radius label (r_j) just outside the radius line endpoint
    label_x = rx + 0.25 * cos(angle);
    label_y = ry + 0.25 * sin(angle);
    text(label_x, label_y, sprintf('r_{%d}', pair_idx), ...
        'FontSize', 10, 'FontWeight', 'bold', 'Color', 'k', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
end

% Plot start point (green filled circle with black edge)
plot(X_s(1), X_s(2), 'o', 'MarkerSize', 10, ...
    'MarkerFaceColor', [0.2, 0.8, 0.2], 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
text(X_s(1) + 0.5, X_s(2), 'Start', 'FontSize', 11, 'FontWeight', 'bold');

% Plot end point (red filled circle with black edge)
plot(X_e(1), X_e(2), 'o', 'MarkerSize', 10, ...
    'MarkerFaceColor', [0.9, 0.2, 0.2], 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
text(X_e(1) - 0.5, X_e(2), 'End', 'FontSize', 11, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'right');

% Configure plot appearance
title('Game Notations', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('X (cm)', 'FontSize', 11);
ylabel('Y (cm)', 'FontSize', 11);
box on;
axis([0 12 0 9]);
daspect([1 1 1]);
xticks(0:2:12);
yticks(0:2:8);
set(gca, 'FontSize', 9, 'Color', 'w');
hold off;

% Save the figure (if requested)
if save_figures
    output_file = fullfile(output_folder, 'game_notations.png');
    print(figure_handle, output_file, '-dpng', '-r300');
    
    output_file_eps = fullfile(output_folder, 'game_notations.eps');
    print(figure_handle, output_file_eps, '-depsc', '-r300');
    
    output_file_pdf = fullfile(output_folder, 'game_notations.pdf');
    print(figure_handle, output_file_pdf, '-dpdf', '-r300');
    
    fprintf('\nGame notations saved to:\n');
    fprintf('  PNG: %s\n', output_file);
    fprintf('  EPS: %s\n', output_file_eps);
    fprintf('  PDF: %s\n', output_file_pdf);
else
    fprintf('\nGame notations displayed (not saved).\n');
end

fprintf('Visualization complete!\n');
