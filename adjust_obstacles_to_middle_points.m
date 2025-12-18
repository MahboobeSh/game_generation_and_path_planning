function [adjusted_obstacles] = adjust_obstacles_to_middle_points(obstacles, original_middle_points, new_middle_points)
% ADJUST_OBSTACLES_TO_MIDDLE_POINTS Adjusts obstacle pairs to maintain 
% the same relative positions when middle points are modified
%
% Inputs:
%   obstacles - Nx2 array of obstacle centers (pairs: [obs1; obs2; obs3; obs4; ...])
%   original_middle_points - Mx2 array of original middle points (M = N/2)
%   new_middle_points - Mx2 array of new middle points (M = N/2)
%
% Output:
%   adjusted_obstacles - Nx2 array of adjusted obstacle centers
%
% The function maintains the relative distance and angle of each obstacle
% from its pair's middle point, but shifts the pair to align with the new
% middle point.

adjusted_obstacles = obstacles;  % Initialize with original obstacles

% Loop through each obstacle pair
for i = 1:size(original_middle_points, 1)
    % Get indices for this obstacle pair
    obs1_idx = 2*i - 1;
    obs2_idx = 2*i;
    
    % Get original obstacles
    obs1_orig = obstacles(obs1_idx, :);
    obs2_orig = obstacles(obs2_idx, :);
    
    % Get original and new middle points
    X_m_orig = original_middle_points(i, :);
    X_m_new = new_middle_points(i, :);
    
    % Calculate the shift (offset) from original to new middle point
    shift = X_m_new - X_m_orig;
    
    % Apply the shift to both obstacles in the pair
    adjusted_obstacles(obs1_idx, :) = obs1_orig + shift;
    adjusted_obstacles(obs2_idx, :) = obs2_orig + shift;
end

end

