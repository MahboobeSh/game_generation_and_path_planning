function plot_obstacles_consistent(obstacle_centers, obstacle_radii)
% PLOT_OBSTACLES_CONSISTENT - Plot obstacles with consistent style across all figures
%
% This function provides a standardized way to plot obstacles with:
%   - Filled circles with semi-transparent red/pink color
%   - Black edges with consistent line width
%   - No dependency on Image Processing Toolbox
%
% Inputs:
%   obstacle_centers - Nx2 array of obstacle center coordinates [x, y]
%   obstacle_radii   - Nx1 array of obstacle radii (or scalar for all same size)
%
% Usage:
%   plot_obstacles_consistent(obstacles, radii);
%
% Example:
%   hold on;
%   plot_obstacles_consistent(game_data.obstacle, game_data.obstacle_radious);

% Handle scalar radius (same size for all obstacles)
if isscalar(obstacle_radii)
    obstacle_radii = repmat(obstacle_radii, size(obstacle_centers, 1), 1);
end

% Ensure radii is a column vector
if isrow(obstacle_radii)
    obstacle_radii = obstacle_radii(:);
end

% Plot each obstacle
for i = 1:size(obstacle_centers, 1)
    theta = linspace(0, 2*pi, 100);
    x_circle = obstacle_centers(i, 1) + obstacle_radii(i) * cos(theta);
    y_circle = obstacle_centers(i, 2) + obstacle_radii(i) * sin(theta);
    
    % Filled circle with semi-transparency (consistent red/pink color)
    fill(x_circle, y_circle, [1, 0.3, 0.3], 'FaceAlpha', 0.5, ...
        'EdgeColor', 'k', 'LineWidth', 1.5);
end

end
