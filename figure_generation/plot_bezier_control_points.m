function plot_bezier_control_points(set_number, pairs_number, base_folder)
%PLOT_BEZIER_CONTROL_POINTS Creates a visualization of Bezier curve control points
%   This function generates a figure similar to the hand-drawn sketch showing:
%   - The Bezier curve path
%   - Main points (Pe, Pm, Ps)
%   - Control points with distances (d) and angles (φ)
%   - Circles with radii
%
%   Inputs:
%   - set_number: The game set number to load
%   - pairs_number: Number of obstacle pairs (2, 3, or 4)
%   - base_folder: Base folder path (optional, defaults to current directory)

if nargin < 3
    base_folder = pwd;
end

% Add parent folder to path to access helper functions
% Get the directory where this script is located
script_dir = fileparts(mfilename('fullpath'));
% Get the parent directory (one level up)
parent_dir = fileparts(script_dir);
% Add parent directory to MATLAB path
addpath(parent_dir);

% Load the game data
pairs_folder = fullfile(base_folder, sprintf('%dpairs', pairs_number), 'fit');
set_name = sprintf('set_%d_%dpairs.mat', set_number, pairs_number);
fullFileName = fullfile(pairs_folder, set_name);

if ~exist(fullFileName, 'file')
    error('File not found: %s', fullFileName);
end

data = load(fullFileName);

% Extract necessary data
if ~isfield(data, 'variables_matrix') || ~isfield(data, 'Start_points') || ~isfield(data, 'End_points')
    error('Required fields (variables_matrix, Start_points, End_points) not found in data file');
end

% Extract all data including obstacles
variables_matrix = data.variables_matrix;
Start_points = data.Start_points;
End_points = data.End_points;
num_segments = size(Start_points, 1);

% Extract obstacles and other data if available
if isfield(data, 'obstacle')
    obstacles = data.obstacle;
else
    obstacles = [];
end

if isfield(data, 'obstacle_radious')
    obstacle_radii = data.obstacle_radious;
elseif isfield(data, 'obstacle_radius')
    obstacle_radii = data.obstacle_radius;
else
    obstacle_radii = [];
end

if isfield(data, 'X_s')
    X_s = data.X_s;
else
    X_s = Start_points(1, :);
end

if isfield(data, 'X_e')
    X_e = data.X_e;
else
    X_e = End_points(end, :);
end

if isfield(data, 'x_range')
    x_range = data.x_range;
else
    x_range = [];
end

if isfield(data, 'y_range')
    y_range = data.y_range;
else
    y_range = [];
end

% Determine n_d and n_phi from variables_matrix structure
% variables_matrix should have columns: [d1, d2, d3, phi1, phi2]
n_cols = size(variables_matrix, 2);
if n_cols == 5
    n_d = 2;
    n_phi = 1;
else
    % Try to infer from structure
    n_d = 2;
    n_phi = 1;
end

% Calculate curve segment points
curve_segment_points = calculate_curve_segment_points(variables_matrix, Start_points, End_points, num_segments, n_d, n_phi);

% Generate Bezier curves for visualization
if isfield(data, 'num_samples_list')
    num_samples_list = data.num_samples_list;
else
    num_samples_list = 25 * ones(num_segments, 1);
end

composite_curve = [];
for i = 1:num_segments
    segment_control_points = curve_segment_points(:, :, i);
    segment_curve = bezier_curve(segment_control_points, num_samples_list(i));
    composite_curve = [composite_curve; segment_curve];
end

% Create figure
figure('Position', [100, 100, 1200, 800]);
hold on;
axis equal;
grid on;
colormap(parula);

% Define colors (matching your existing code)
color1 = [0, 119, 187] / 255;    % Blue color (#0077BB)
color2 = [43, 208, 158] / 255;   % Teal color (#22B199)
color3 = [238, 119, 51] / 255;   % Orange color (#EE7733)
color4 = [195, 48, 15] / 255;    % Red color (#C3300F)
color5 = [0, 0, 0] / 255;        % Black
color6 = [255, 0, 140] / 255;    % Magenta color (#FF008C)
color7 = [255, 120, 0] / 255;    % Orange color (#FF7800)
color8 = [57, 226, 213] / 255;   % Aqua color (#39E2D5)
color9 = [8, 61, 119] / 255;     % Navy blue color (#083D77)

% Subtle color scheme for better visibility without being garish
path_color = [0, 0, 0];  % Black for main path
main_point_color = [0.3, 0.3, 0.3];  % Dark gray for main points
control_line_color = [0.4, 0.4, 0.4];  % Medium gray for control lines
label_color = [0.4, 0.2, 0.6];  % Muted purple for labels
distance_label_color = [0.2, 0.4, 0.7];  % Muted blue for distance labels
angle_label_color = [0.6, 0.3, 0.5];  % Muted purple-pink for angle labels
obstacle_color = [0.3, 0.3, 0.3];  % Dark gray for obstacles

% Subtle segment colors for control points (muted tones)
segment_colors = [
    [0.5, 0.3, 0.3];  % Muted brown-red for segment 1
    [0.3, 0.4, 0.6];  % Muted blue for segment 2
    [0.3, 0.5, 0.4];  % Muted green for segment 3
    [0.5, 0.5, 0.3];  % Muted olive for segment 4
    [0.5, 0.3, 0.5];  % Muted purple for segment 5
];

% Plot obstacles first (so they appear behind everything else)
if ~isempty(obstacles) && ~isempty(obstacle_radii)
    for i = 1:size(obstacles, 1)
        viscircles(obstacles(i, :), obstacle_radii(i), 'EdgeColor', obstacle_color, 'color', [0.95, 0.95, 0.95], 'LineWidth', 1.5);
    end
end

% Plot start and end points
plot(X_s(1), X_s(2), 'o', 'MarkerSize', 8, 'MarkerFaceColor', main_point_color, ...
    'MarkerEdgeColor', 'k', 'LineWidth', 1.5, 'HandleVisibility', 'off');
text(X_s(1), X_s(2), ' Start', 'FontSize', 9, 'FontWeight', 'bold', 'Color', 'k', ...
    'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left');
plot(X_e(1), X_e(2), 'o', 'MarkerSize', 8, 'MarkerFaceColor', main_point_color, ...
    'MarkerEdgeColor', 'k', 'LineWidth', 1.5, 'HandleVisibility', 'off');
text(X_e(1), X_e(2), ' End', 'FontSize', 9, 'FontWeight', 'bold', 'Color', 'k', ...
    'VerticalAlignment', 'top', 'HorizontalAlignment', 'right');

% Plot the main Bezier curve path with thicker line
plot(composite_curve(:, 1), composite_curve(:, 2), '-', 'Color', path_color, 'LineWidth', 1);

% Plot main points and control points for each segment
for seg = 1:num_segments
    % Get control points for this segment
    P_s = curve_segment_points(1, :, seg);  % Start point
    P_c1 = curve_segment_points(2, :, seg); % Control point 1
    P_c2 = curve_segment_points(3, :, seg); % Control point 2
    P_c3 = curve_segment_points(4, :, seg); % Control point 3
    P_e = curve_segment_points(5, :, seg);  % End point
    
    % Get variables for this segment
    var_row = variables_matrix(seg, :);
    
    % Get segment color for this segment
    seg_color_idx = min(seg, size(segment_colors, 1));
    seg_color = segment_colors(seg_color_idx, :);
    
    % Plot main points with enhanced colors

    
    % Middle points (Pm1, Pm2, Pm3 for 3 pairs = 4 segments)
    % In variables_matrix order: start, mp1, mp2, mp3, end
    % So segment 1 ends at mp1, segment 2 ends at mp2, segment 3 ends at mp3
    if seg < num_segments
        % This is a middle point
        Pm_label = sprintf('Pm%d', seg);
        plot(P_e(1), P_e(2), 'o', 'MarkerSize', 8, 'MarkerFaceColor', main_point_color, ...
            'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
        text(P_e(1), P_e(2), [' ' Pm_label], 'Color', label_color, 'FontSize', 10, 'FontWeight', 'bold');
    else
        % Last segment: Ps (end of entire path)
        plot(P_e(1), P_e(2), 'o', 'MarkerSize', 8, 'MarkerFaceColor', main_point_color, ...
            'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
        text(P_e(1), P_e(2), ' Ps', 'Color', label_color, 'FontSize', 10, 'FontWeight', 'bold');
    end
    
    % Calculate and plot control points with d and φ labels
    % For n_d=2, n_phi=1, the structure is: [d1, d2, d3, phi1, phi2]
    if n_d == 2 && n_phi == 1
        d1 = var_row(1);
        d2 = var_row(2);
        d3 = var_row(3);
        phi1 = var_row(4);
        phi2 = var_row(5);
        
        % According to calculate_curve_segment_points:
        % - P_c1 comes from temp1 (d2, phi1 from start) 
        % - P_c2 comes from temp3 (d3, phi2 from start)
        % - P_c3 comes from temp2 (d1, phi1 from end of current or start of next)
        
        % Control points from start point (P_s)
        CP_start1 = P_c1;  % Uses d2, phi1
        CP_start2 = P_c2;  % Uses d3, phi2
        
        % Control point from end point (P_e)
        if seg < num_segments
            var_row_next = variables_matrix(seg + 1, :);
            d1_next = var_row_next(1);
            phi1_next = var_row_next(4);
            CP_end1 = P_c3;  % Uses d1_next, phi1_next (from next segment's start)
        else
            CP_end1 = P_c3;  % Uses d1, phi1 (from current segment)
        end
        
        % Reference line is horizontal (parallel to x-axis)
        % All phi angles are measured from this horizontal reference line
        ref_dir = 0;  % Horizontal direction (0 radians = along x-axis)
        
        % Plot control points and lines from START point (P_s)
        if seg == 1
            % First segment: label as CP_s1, CP_s2, CP_s3
            % d labels should match CP numbering: d_s1, d_s2, d_s3
            plot(CP_start1(1), CP_start1(2), 'o', 'MarkerSize', 6, 'MarkerEdgeColor', seg_color, ...
                'MarkerFaceColor', 'none', 'LineWidth', 1);
            line([P_s(1), CP_start1(1)], [P_s(2), CP_start1(2)], 'Color', control_line_color, 'LineWidth', 1, 'LineStyle', '-');
            mid_point1 = (P_s + CP_start1) / 2;
            text(mid_point1(1), mid_point1(2), 'd_{s1}', 'Color', distance_label_color, 'FontSize', 9, ...
                'BackgroundColor', 'white', 'HorizontalAlignment', 'center');
            text(CP_start1(1), CP_start1(2), ' CP_{s1}', 'Color', label_color, 'FontSize', 9);
            
            % CP_s2 (from P_s with d3, phi2)
            plot(CP_start2(1), CP_start2(2), 'o', 'MarkerSize', 6, 'MarkerEdgeColor', seg_color, ...
                'MarkerFaceColor', 'none', 'LineWidth', 1);
            line([P_s(1), CP_start2(1)], [P_s(2), CP_start2(2)], 'Color', control_line_color, 'LineWidth', 1, 'LineStyle', '-');
            mid_point2 = (P_s + CP_start2) / 2;
            text(mid_point2(1), mid_point2(2), 'd_{s2}', 'Color', distance_label_color, 'FontSize', 9, ...
                'BackgroundColor', 'white', 'HorizontalAlignment', 'center');
            text(CP_start2(1), CP_start2(2), ' CP_{s2}', 'Color', label_color, 'FontSize', 9);
            
            % CP_s3 (from P_e, but shown at end of segment)
            % This will be plotted when we handle the end point
        elseif seg < num_segments
            % Middle segments: Control points from start point of this segment
            % Segment 2 (mp1): CP_11, CP_12, CP_13 with d11, d12, d13
            % Segment 3 (mp2): CP_21, CP_22, CP_23 with d21, d22, d23
            % Segment 4 (mp3): CP_31, CP_32, CP_33 with d31, d32, d33
            % CP_{seg-1}1 uses d_{seg-1}1, CP_{seg-1}2 uses d_{seg-1}2
            cp_idx = seg - 1;  % CP index: seg 2 -> CP_11, seg 3 -> CP_21, etc.
            plot(CP_start1(1), CP_start1(2), 'o', 'MarkerSize', 6, 'MarkerEdgeColor', seg_color, ...
                'MarkerFaceColor', 'none', 'LineWidth', 1);
            line([P_s(1), CP_start1(1)], [P_s(2), CP_start1(2)], 'Color', control_line_color, 'LineWidth', 1, 'LineStyle', '-');
            mid_point1 = (P_s + CP_start1) / 2;
            text(mid_point1(1), mid_point1(2), sprintf('d_{%d1}', cp_idx), 'Color', distance_label_color, 'FontSize', 9, ...
                'BackgroundColor', 'white', 'HorizontalAlignment', 'center');
            text(CP_start1(1), CP_start1(2), sprintf(' CP_{%d1}', cp_idx), 'Color', label_color, 'FontSize', 9);
            
            plot(CP_start2(1), CP_start2(2), 'o', 'MarkerSize', 6, 'MarkerEdgeColor', seg_color, ...
                'MarkerFaceColor', 'none', 'LineWidth', 1);
            line([P_s(1), CP_start2(1)], [P_s(2), CP_start2(2)], 'Color', control_line_color, 'LineWidth', 1, 'LineStyle', '-');
            mid_point2 = (P_s + CP_start2) / 2;
            text(mid_point2(1), mid_point2(2), sprintf('d_{%d2}', cp_idx), 'Color', distance_label_color, 'FontSize', 9, ...
                'BackgroundColor', 'white', 'HorizontalAlignment', 'center');
            text(CP_start2(1), CP_start2(2), sprintf(' CP_{%d2}', cp_idx), 'Color', label_color, 'FontSize', 9);
        end
        
        % Plot control points and lines from END point (P_e)
        if seg == 1
            % For first segment, the end control point is CP_s3
            % CP_s3 uses d1 from segment 2 -> should be labeled d_11
            plot(CP_end1(1), CP_end1(2), 'o', 'MarkerSize', 6, 'MarkerEdgeColor', seg_color, ...
                'MarkerFaceColor', 'none', 'LineWidth', 1);
            line([P_e(1), CP_end1(1)], [P_e(2), CP_end1(2)], 'Color', control_line_color, 'LineWidth', 1, 'LineStyle', '-');
            mid_point3 = (P_e + CP_end1) / 2;
            text(mid_point3(1), mid_point3(2), 'd_{11}', 'Color', distance_label_color, 'FontSize', 9, ...
                'BackgroundColor', 'white', 'HorizontalAlignment', 'center');
            text(CP_end1(1), CP_end1(2), ' CP_{s3}', 'Color', label_color, 'FontSize', 9);
        elseif seg < num_segments
            % Control point from end point of current segment
            % CP_{seg-1}3 uses d_{seg-1}3
            % For example: CP_13 uses d13, CP_23 uses d23, CP_33 uses d33
            cp_idx = seg - 1;  % CP index: seg 2 -> CP_11, seg 3 -> CP_21, etc.
            plot(CP_end1(1), CP_end1(2), 'o', 'MarkerSize', 6, 'MarkerEdgeColor', seg_color, ...
                'MarkerFaceColor', 'none', 'LineWidth', 1);
            line([P_e(1), CP_end1(1)], [P_e(2), CP_end1(2)], 'Color', control_line_color, 'LineWidth', 1, 'LineStyle', '-');
            mid_point3 = (P_e + CP_end1) / 2;
            text(mid_point3(1), mid_point3(2), sprintf('d_{%d3}', cp_idx), 'Color', distance_label_color, 'FontSize', 9, ...
                'BackgroundColor', 'white', 'HorizontalAlignment', 'center');
            text(CP_end1(1), CP_end1(2), sprintf(' CP_{%d3}', cp_idx), 'Color', label_color, 'FontSize', 9);
        else
            % Last segment: Control points for segment num_segments
            % d labels should match CP numbering: d_{seg}1, d_{seg}2, d_{seg}3
            plot(CP_start1(1), CP_start1(2), 'o', 'MarkerSize', 6, 'MarkerEdgeColor', seg_color, ...
                'MarkerFaceColor', 'none', 'LineWidth', 1);
            line([P_s(1), CP_start1(1)], [P_s(2), CP_start1(2)], 'Color', control_line_color, 'LineWidth', 1, 'LineStyle', '-');
            mid_point1 = (P_s + CP_start1) / 2;
            text(mid_point1(1), mid_point1(2), sprintf('d_{%d1}', seg), 'Color', distance_label_color, 'FontSize', 9, ...
                'BackgroundColor', 'white', 'HorizontalAlignment', 'center');
            text(CP_start1(1), CP_start1(2), sprintf(' CP_{%d1}', seg), 'Color', label_color, 'FontSize', 9);
            
            plot(CP_start2(1), CP_start2(2), 'o', 'MarkerSize', 6, 'MarkerEdgeColor', seg_color, ...
                'MarkerFaceColor', 'none', 'LineWidth', 1);
            line([P_s(1), CP_start2(1)], [P_s(2), CP_start2(2)], 'Color', control_line_color, 'LineWidth', 1, 'LineStyle', '-');
            mid_point2 = (P_s + CP_start2) / 2;
            text(mid_point2(1), mid_point2(2), sprintf('d_{%d2}', seg), 'Color', distance_label_color, 'FontSize', 9, ...
                'BackgroundColor', 'white', 'HorizontalAlignment', 'center');
            text(CP_start2(1), CP_start2(2), sprintf(' CP_{%d2}', seg), 'Color', label_color, 'FontSize', 9);
            
            plot(CP_end1(1), CP_end1(2), 'o', 'MarkerSize', 6, 'MarkerEdgeColor', seg_color, ...
                'MarkerFaceColor', 'none', 'LineWidth', 1);
            line([P_e(1), CP_end1(1)], [P_e(2), CP_end1(2)], 'Color', control_line_color, 'LineWidth', 1, 'LineStyle', '-');
            mid_point3 = (P_e + CP_end1) / 2;
            text(mid_point3(1), mid_point3(2), sprintf('d_{%d3}', seg), 'Color', distance_label_color, 'FontSize', 9, ...
                'BackgroundColor', 'white', 'HorizontalAlignment', 'center');
            text(CP_end1(1), CP_end1(2), sprintf(' CP_{%d3}', seg), 'Color', label_color, 'FontSize', 9);
        end
        
        % Plot angle indicators (φ) - angles are measured from horizontal (x-axis)
        % The phi values in variables_matrix are already angles from horizontal
        if seg == 1
            % For start point (Be), show φs1 and φs2
            % phi1 and phi2 are from variables_matrix(seg, 4) and variables_matrix(seg, 5)
            phi1 = var_row(4);  % phi1 from variables_matrix
            phi2 = var_row(5);  % phi2 from variables_matrix
            
            % Draw reference line (horizontal dashed line)
            d_avg = (d2 + d3) / 2;
            ref_line_length = d_avg * 0.4;
            ref_line_end = P_s + ref_line_length * [cos(ref_dir), sin(ref_dir)];
            plot([P_s(1), ref_line_end(1)], [P_s(2), ref_line_end(2)], '--', ...
                'Color', angle_label_color, 'LineWidth', 1);
            
            % Draw first angle arc (phi_s1): from horizontal reference line to phi1
            arc_radius1 = d2 * 0.3;
            theta1 = linspace(ref_dir, phi1, 30);
            arc_x1 = P_s(1) + arc_radius1 * cos(theta1);
            arc_y1 = P_s(2) + arc_radius1 * sin(theta1);
            plot(arc_x1, arc_y1, '--', 'Color', angle_label_color, 'LineWidth', 1.5);
            text(P_s(1) + arc_radius1*1.4*cos((ref_dir+phi1)/2), ...
                P_s(2) + arc_radius1*1.4*sin((ref_dir+phi1)/2), ...
                'phi_{s1}', 'Color', angle_label_color, 'FontSize', 9);
            
            % Draw second angle arc (phi_s2): from horizontal reference line to phi2
            arc_radius2 = d3 * 0.3;
            theta2 = linspace(ref_dir, phi2, 30);
            arc_x2 = P_s(1) + arc_radius2 * cos(theta2);
            arc_y2 = P_s(2) + arc_radius2 * sin(theta2);
            plot(arc_x2, arc_y2, '--', 'Color', angle_label_color, 'LineWidth', 1.5);
            text(P_s(1) + arc_radius2*1.4*cos((ref_dir+phi2)/2), ...
                P_s(2) + arc_radius2*1.4*sin((ref_dir+phi2)/2), ...
                'phi_{s2}', 'Color', angle_label_color, 'FontSize', 9);
        elseif seg < num_segments
            % For middle points, show angles
            % phi1 and phi2 are from variables_matrix(seg, 4) and variables_matrix(seg, 5)
            % Segment 2 (ends at mp1): phi_11, phi_12 (using seg-1 = 1)
            % Segment 3 (ends at mp2): phi_21, phi_22 (using seg-1 = 2)
            % Segment 3 (ends at mp3): phi_31, phi_32 (using seg-1 = 3) - for 4 segments total
            phi1 = var_row(4);  % phi1 from variables_matrix
            phi2 = var_row(5);  % phi2 from variables_matrix
            cp_idx = seg - 1;  % CP index: seg 2 -> phi_11, seg 3 -> phi_21, seg 4 -> phi_31
            
            % Draw reference line (horizontal dashed line)
            d_avg = (d2 + d3) / 2;
            ref_line_length = d_avg * 0.4;
            ref_line_end = P_s + ref_line_length * [cos(ref_dir), sin(ref_dir)];
            plot([P_s(1), ref_line_end(1)], [P_s(2), ref_line_end(2)], '--', ...
                'Color', angle_label_color, 'LineWidth', 1);
            
            % Draw first angle arc (phi_ij1): from horizontal reference line to phi1
            arc_radius1 = d2 * 0.3;
            theta1 = linspace(ref_dir, phi1, 30);
            arc_x1 = P_s(1) + arc_radius1 * cos(theta1);
            arc_y1 = P_s(2) + arc_radius1 * sin(theta1);
            plot(arc_x1, arc_y1, '--', 'Color', angle_label_color, 'LineWidth', 1.5);
            text(P_s(1) + arc_radius1*1.4*cos((ref_dir+phi1)/2), ...
                P_s(2) + arc_radius1*1.4*sin((ref_dir+phi1)/2), ...
                sprintf('phi_{%d1}', cp_idx), 'Color', angle_label_color, 'FontSize', 9);
            
            % Draw second angle arc (phi_ij2): from horizontal reference line to phi2
            arc_radius2 = d3 * 0.3;
            theta2 = linspace(ref_dir, phi2, 30);
            arc_x2 = P_s(1) + arc_radius2 * cos(theta2);
            arc_y2 = P_s(2) + arc_radius2 * sin(theta2);
            plot(arc_x2, arc_y2, '--', 'Color', angle_label_color, 'LineWidth', 1.5);
            text(P_s(1) + arc_radius2*1.4*cos((ref_dir+phi2)/2), ...
                P_s(2) + arc_radius2*1.4*sin((ref_dir+phi2)/2), ...
                sprintf('phi_{%d2}', cp_idx), 'Color', angle_label_color, 'FontSize', 9);
        else
            % For end point (Ps), show φe1
            % For last segment, phi1 is from variables_matrix(seg, 4)
            phi1 = var_row(4);  % phi1 from variables_matrix
            
            % Draw reference line (horizontal dashed line)
            ref_line_length = d1 * 0.4;
            ref_line_end = P_e + ref_line_length * [cos(ref_dir), sin(ref_dir)];
            plot([P_e(1), ref_line_end(1)], [P_e(2), ref_line_end(2)], '--', ...
                'Color', angle_label_color, 'LineWidth', 1);
            
            % Draw angle arc from horizontal reference line to phi1
            arc_radius = d1 * 0.3;
            theta1 = linspace(ref_dir, phi1, 30);
            arc_x1 = P_e(1) + arc_radius * cos(theta1);
            arc_y1 = P_e(2) + arc_radius * sin(theta1);
            plot(arc_x1, arc_y1, '--', 'Color', angle_label_color, 'LineWidth', 1.5);
            text(P_e(1) + arc_radius*1.4*cos((ref_dir+phi1)/2), ...
                P_e(2) + arc_radius*1.4*sin((ref_dir+phi1)/2), ...
                'phi_{e1}', 'Color', angle_label_color, 'FontSize', 9);
        end
    end
    
    % Blue dashed circles removed - not needed for visualization
end

% Set axis labels and title
xlabel('X', 'FontSize', 12);
ylabel('Y', 'FontSize', 12);
title(sprintf('Bezier Curve Control Points - Set %d (%d pairs)', set_number, pairs_number), ...
    'FontSize', 14, 'FontWeight', 'bold');

% Adjust axis limits to show all elements
all_points = [composite_curve; reshape(curve_segment_points, [], 2)];
if ~isempty(obstacles)
    all_points = [all_points; obstacles];
end
all_points = [all_points; X_s; X_e];

x_margin = (max(all_points(:, 1)) - min(all_points(:, 1))) * 0.1;
y_margin = (max(all_points(:, 2)) - min(all_points(:, 2))) * 0.1;

% Use x_range and y_range if available, otherwise use calculated limits
if ~isempty(x_range) && ~isempty(y_range)
    xlim([0, x_range]);
    ylim([0, y_range]);
else
    xlim([min(all_points(:, 1)) - x_margin, max(all_points(:, 1)) + x_margin]);
    ylim([min(all_points(:, 2)) - y_margin, max(all_points(:, 2)) + y_margin]);
end

hold off;

% Save figure
output_folder = fullfile(base_folder, sprintf('%dpairs', pairs_number), 'fit');
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end
output_filename = sprintf('bezier_control_points_set_%d_%dpairs.png', set_number, pairs_number);
output_path = fullfile(output_folder, output_filename);
print(output_path, '-dpng', '-r300');
fprintf('Figure saved to: %s\n', output_path);

end

