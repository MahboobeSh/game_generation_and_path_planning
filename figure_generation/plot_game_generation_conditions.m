% Plot game generation conditions
% Illustrates the distance-based configuration values:
%   - Obstacle pair gaps (d_g)
%   - Inter-pair obstacle distance (d_o,min)
%   - Distance from first pair to start (d_se)
%   - Distance from last pair to end (d_se)

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

% Annotation colors
color_gap    = [0.0, 0.45, 0.75];   % blue for pair gaps
color_inter  = [0.6, 0.0, 0.6];     % purple for inter-pair distance
color_se     = [0.0, 0.5, 0.0];     % green for start/end distances

% ============================================================================
% Create figure
% ============================================================================
figure_handle = figure('Position', [100, 100, 900, 650], 'Color', 'w');
hold on;

% --- Draw obstacles ---
for i = 1:num_obstacles
    theta = linspace(0, 2*pi, 100);
    x_circle = obstacles(i, 1) + obstacle_radii(i) * cos(theta);
    y_circle = obstacles(i, 2) + obstacle_radii(i) * sin(theta);
    fill(x_circle, y_circle, [1, 0.3, 0.3], 'FaceAlpha', 0.5, ...
        'EdgeColor', 'k', 'LineWidth', 1.5);
end

% --- Label each obstacle ---
for i = 1:num_obstacles
    cx = obstacles(i, 1);
    cy = obstacles(i, 2);
    text(cx, cy, sprintf('O_{%d}', i), ...
        'FontSize', 9, 'FontWeight', 'bold', 'Color', 'k', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
end

% --- Start and End points ---
plot(X_s(1), X_s(2), 'o', 'MarkerSize', 10, ...
    'MarkerFaceColor', [0.2, 0.8, 0.2], 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
text(X_s(1), X_s(2) - 0.4, 'Start', 'FontSize', 10, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');

plot(X_e(1), X_e(2), 'o', 'MarkerSize', 10, ...
    'MarkerFaceColor', [0.9, 0.2, 0.2], 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
text(X_e(1), X_e(2) - 0.4, 'End', 'FontSize', 10, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');

% ============================================================================
% ANNOTATION 1: Obstacle pair gaps (d_g) — arrow between each pair
% ============================================================================
gap_label_offsets = {[-0.8, -0.3], [-0.2, -0.7], [0, 0.7]};  % per pair offsets
ordinal = {'1st', '2nd', '3rd', '4th', '5th', '6th'};

for p = 1:num_pairs
    i1 = 2*p - 1;
    i2 = 2*p;
    
    c1 = obstacles(i1, :); r1 = obstacle_radii(i1);
    c2 = obstacles(i2, :); r2 = obstacle_radii(i2);
    
    % Direction from obstacle 1 to 2
    direction = c2 - c1;
    dist = norm(direction);
    dir_unit = direction / dist;
    perp = [-dir_unit(2), dir_unit(1)];
    
    % Edges of each obstacle closest to each other
    edge1 = c1 + r1 * dir_unit;
    edge2 = c2 - r2 * dir_unit;
    
    % Double-headed arrow for the gap
    draw_double_arrow(edge1, edge2, color_gap, 1.5);
    
    % Label the gap — offset perpendicular to the gap line
    gap_mid = (edge1 + edge2) / 2;
    if p <= length(gap_label_offsets)
        offset = gap_label_offsets{p};
    else
        offset = [0, 0.5];
    end
    label_pos = gap_mid + offset;
    
    text(label_pos(1), label_pos(2), ...
        sprintf('d_{g,%d}', p), ...
        'FontSize', 10, 'Color', color_gap, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
end

% ============================================================================
% ANNOTATION 2: d_se from Start to midpoint of first pair
% Two red tangent lines forming the gate + green d_se arrow
% ============================================================================
c1 = obstacles(1, :); r1 = obstacle_radii(1);
c2 = obstacles(2, :); r2 = obstacle_radii(2);
dir_pair1 = (c2 - c1) / norm(c2 - c1);
perp1 = [-dir_pair1(2), dir_pair1(1)];

% Red tangent line only on the side facing Start
upper_o1 = c1 + r1 * perp1;
upper_o2 = c2 + r2 * perp1;
lower_o1 = c1 - r1 * perp1;
lower_o2 = c2 - r2 * perp1;
% Pick the side closer to Start
upper_mid = (upper_o1 + upper_o2) / 2;
lower_mid = (lower_o1 + lower_o2) / 2;
if norm(upper_mid - X_s) < norm(lower_mid - X_s)
    plot([upper_o1(1), upper_o2(1)], [upper_o1(2), upper_o2(2)], '-', ...
        'Color', [0.9, 0.0, 0.0], 'LineWidth', 1.5);
else
    plot([lower_o1(1), lower_o2(1)], [lower_o1(2), lower_o2(2)], '-', ...
        'Color', [0.9, 0.0, 0.0], 'LineWidth', 1.5);
end

% Green d_se arrow: from Start to the nearest red tangent line
pair1_mid = mean(obstacles([1, 2], :), 1);
% Find intersection of Start→pair_mid line with the two red tangent lines
hit_upper = line_intersect(X_s, pair1_mid, upper_o1, upper_o2);
hit_lower = line_intersect(X_s, pair1_mid, lower_o1, lower_o2);
% Pick the one closest to Start
if norm(hit_upper - X_s) < norm(hit_lower - X_s)
    hit_point = hit_upper;
else
    hit_point = hit_lower;
end
draw_double_arrow(X_s, hit_point, color_se, 1.5);

% Label d_s
se_mid = (X_s + hit_point) / 2;
text(se_mid(1) - 0.3, se_mid(2) + 0.5, 'd_{s}', ...
    'FontSize', 10, 'Color', color_se, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');

% ============================================================================
% ANNOTATION 3: d_se from End to midpoint of last pair
% Two red tangent lines forming the gate + green d_se arrow
% ============================================================================
c_last1 = obstacles(num_obstacles-1, :); r_last1 = obstacle_radii(num_obstacles-1);
c_last2 = obstacles(num_obstacles, :);   r_last2 = obstacle_radii(num_obstacles);
dir_pair_last = (c_last2 - c_last1) / norm(c_last2 - c_last1);
perp_last = [-dir_pair_last(2), dir_pair_last(1)];

% Red tangent line only on the side facing End
upper_last1 = c_last1 + r_last1 * perp_last;
upper_last2 = c_last2 + r_last2 * perp_last;
lower_last1 = c_last1 - r_last1 * perp_last;
lower_last2 = c_last2 - r_last2 * perp_last;
% Pick the side closer to End
upper_mid_e = (upper_last1 + upper_last2) / 2;
lower_mid_e = (lower_last1 + lower_last2) / 2;
if norm(upper_mid_e - X_e) < norm(lower_mid_e - X_e)
    plot([upper_last1(1), upper_last2(1)], [upper_last1(2), upper_last2(2)], '-', ...
        'Color', [0.9, 0.0, 0.0], 'LineWidth', 1.5);
else
    plot([lower_last1(1), lower_last2(1)], [lower_last1(2), lower_last2(2)], '-', ...
        'Color', [0.9, 0.0, 0.0], 'LineWidth', 1.5);
end

% Green d_se arrow: from End to the nearest red tangent line
pair_last_mid = mean(obstacles([num_obstacles-1, num_obstacles], :), 1);
% Find intersection of End→pair_last_mid line with the two red tangent lines
hit_upper_e = line_intersect(X_e, pair_last_mid, upper_last1, upper_last2);
hit_lower_e = line_intersect(X_e, pair_last_mid, lower_last1, lower_last2);
% Pick the one closest to End
if norm(hit_upper_e - X_e) < norm(hit_lower_e - X_e)
    hit_point_e = hit_upper_e;
else
    hit_point_e = hit_lower_e;
end
draw_double_arrow(X_e, hit_point_e, color_se, 1.5);

% Label d_e
se_mid_e = (X_e + hit_point_e) / 2;
text(se_mid_e(1), se_mid_e(2) + 0.5, 'd_{e}', ...
    'FontSize', 10, 'Color', color_se, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');

% ============================================================================
% ANNOTATION 4: Inter-pair distance (d_o,min)
% Show between O4 (pair 2) and O5 (pair 3) — more space for the label
% ============================================================================
obs_from = obstacles(4, :);  % O4 from pair 2
r_from = obstacle_radii(4);
obs_to = obstacles(5, :);    % O5 from pair 3
r_to = obstacle_radii(5);

dir_inter = (obs_to - obs_from) / norm(obs_to - obs_from);
edge_from = obs_from + r_from * dir_inter;
edge_to   = obs_to   - r_to   * dir_inter;

draw_double_arrow(edge_from, edge_to, color_inter, 1.5);

% Label offset from the line to avoid overlap
inter_mid = (edge_from + edge_to) / 2;
text(inter_mid(1), inter_mid(2) - 0.5, 'd_{o,min}', ...
    'FontSize', 10, 'Color', color_inter, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');

% ============================================================================
% Configure plot appearance
% ============================================================================
title('Game Generation Conditions', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('X (cm)', 'FontSize', 11);
ylabel('Y (cm)', 'FontSize', 11);
box on;
axis([0 12 0 9]);
daspect([1 1 1]);
xticks(0:2:12);
yticks(0:2:8);
set(gca, 'FontSize', 9, 'Color', 'w');
hold off;

% ============================================================================
% Save
% ============================================================================
if save_figures
    output_file = fullfile(output_folder, 'game_generation_conditions.png');
    print(figure_handle, output_file, '-dpng', '-r300');
    
    output_file_eps = fullfile(output_folder, 'game_generation_conditions.eps');
    print(figure_handle, output_file_eps, '-depsc', '-r300');
    
    output_file_pdf = fullfile(output_folder, 'game_generation_conditions.pdf');
    print(figure_handle, output_file_pdf, '-dpdf', '-r300');
    
    fprintf('\nGame generation conditions saved to:\n');
    fprintf('  PNG: %s\n', output_file);
    fprintf('  EPS: %s\n', output_file_eps);
    fprintf('  PDF: %s\n', output_file_pdf);
else
    fprintf('\nGame generation conditions displayed (not saved).\n');
end
fprintf('Visualization complete!\n');

% ============================================================================
% HELPER: Draw a double-headed arrow between two points
% ============================================================================
function draw_double_arrow(p1, p2, color, linewidth)
    % Draw dashed line
    plot([p1(1), p2(1)], [p1(2), p2(2)], '--', ...
        'Color', color, 'LineWidth', linewidth);
    
    % Arrow parameters
    dir = (p2 - p1) / norm(p2 - p1);
    perp = [-dir(2), dir(1)];
    head_len = 0.15;
    head_w = 0.08;
    
    % Arrowhead at p2
    tip = p2;
    left  = tip - head_len * dir + head_w * perp;
    right = tip - head_len * dir - head_w * perp;
    fill([tip(1), left(1), right(1)], [tip(2), left(2), right(2)], ...
        color, 'EdgeColor', color, 'LineWidth', 0.5);
    
    % Arrowhead at p1
    tip = p1;
    left  = tip + head_len * dir + head_w * perp;
    right = tip + head_len * dir - head_w * perp;
    fill([tip(1), left(1), right(1)], [tip(2), left(2), right(2)], ...
        color, 'EdgeColor', color, 'LineWidth', 0.5);
end

% ============================================================================
% HELPER: Find intersection point of two lines (A→B and C→D)
% ============================================================================
function P = line_intersect(A, B, C, D)
    % Line 1: A + t*(B-A), Line 2: C + s*(D-C)
    dAB = B - A;
    dCD = D - C;
    dAC = C - A;
    
    denom = dAB(1)*dCD(2) - dAB(2)*dCD(1);
    t = (dAC(1)*dCD(2) - dAC(2)*dCD(1)) / denom;
    
    P = A + t * dAB;
end
