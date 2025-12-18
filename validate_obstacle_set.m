function [all_passed, results] = validate_obstacle_set(set_number, pairs_number, base_folder)
% VALIDATE_OBSTACLE_SET Validates an obstacle set against all criteria
%
% Usage:
%   [all_passed, results] = validate_obstacle_set(set_number, pairs_number)
%   [all_passed, results] = validate_obstacle_set(set_number, pairs_number, base_folder)
%
% Inputs:
%   set_number    - The set number to validate
%   pairs_number  - The number of pairs in the set (e.g., 2, 3, 4, 5)
%   base_folder   - (Optional) Base folder path. Default: current directory structure
%
% Outputs:
%   all_passed    - Logical: true if all conditions pass, false otherwise
%   results       - Structure containing detailed validation results
%
% This function checks if a manually created or altered obstacle set meets
% all the criteria used in create_obstacle_sets.m

% ============================================================================
% DEFAULT CONFIGURATION (matches create_obstacle_sets.m)
% ============================================================================
x_range = 48;
y_range = 27;
x_margin = 0.025*x_range;  % 2.5% margin
y_margin = 0.025*y_range;
max_distance = sqrt(x_range^2 + y_range^2);

% Obstacle radius constraints
min_radius = 2;  % Minimum obstacle radius (cm)
max_radius = 3.25;  % Maximum obstacle radius (cm)

% Distance constraints (same as create_obstacle_sets.m)
min_distance_between_obstacles = 2;  % Minimum gap between obstacles from different pairs (cm)
min_distance_between_obstacle_pairs = 2.0;  % Minimum gap between obstacles in same pair (cm)
min_distance_to_end_and_start = 2.5;  % Minimum distance from start/end points (cm)
min_distance_middle_points = 2.5;  % Minimum distance between middle points of pairs (cm)

% Maximum values (scale with pairs)
max_distance_to_end_and_start = 0.15*max_distance + 0.2*(max_distance/pairs_number);
max_distance_between_obstacle_pairs = 3;

% ============================================================================
% LOAD OBSTACLE SET
% ============================================================================
if nargin < 3 || isempty(base_folder)
    % Default base folder (adjust to match your setup)
    base_folder = 'C:\Users\mahbo\OneDrive - University of Calgary\code\game_creation_and_fits\new_game_set';
end

pairs_folder = fullfile(base_folder, sprintf('%dpairs', pairs_number));
set_name = sprintf('set_%d_%dpairs.mat', set_number, pairs_number);
fullFileName = fullfile(pairs_folder, set_name);

% Check if file exists
if ~exist(fullFileName, 'file')
    error('Obstacle set file not found: %s', fullFileName);
end

% Load the data
data = load(fullFileName);

% Extract variables (handle typo in variable name)
if isfield(data, 'obstacle_radious')
    obstacle_radii = data.obstacle_radious;
elseif isfield(data, 'obstacle_radius')
    obstacle_radii = data.obstacle_radius;
else
    error('Could not find obstacle radii in the loaded file');
end

centers = data.obstacle;
X_s = data.X_s;
X_e = data.X_e;

% Override x_range and y_range if they exist in the file
if isfield(data, 'x_range')
    x_range = data.x_range;
end
if isfield(data, 'y_range')
    y_range = data.y_range;
end

% Verify number of pairs matches
if isfield(data, 'number_of_pairs')
    if data.number_of_pairs ~= pairs_number
        warning('Loaded file has %d pairs, but %d was specified', data.number_of_pairs, pairs_number);
    end
end

% Ensure obstacle_radii is a column vector
if size(obstacle_radii, 2) > size(obstacle_radii, 1)
    obstacle_radii = obstacle_radii';
end

num_obstacles = size(centers, 1);
expected_obstacles = 2 * pairs_number;

if num_obstacles ~= expected_obstacles
    error('Expected %d obstacles (2 per pair), but found %d', expected_obstacles, num_obstacles);
end

% ============================================================================
% INITIALIZE RESULTS STRUCTURE
% ============================================================================
results = struct();
results.set_number = set_number;
results.pairs_number = pairs_number;
results.file_path = fullFileName;
results.all_passed = false;

% ============================================================================
% CONSTRAINT CHECK 1: Obstacle Radius Range (ACTIVE)
% ============================================================================
results.check1_radius_range = struct();
results.check1_radius_range.passed = true;
results.check1_radius_range.violations = [];
results.check1_radius_range.message = 'All obstacle radii are within valid range [%.2f, %.2f] cm';

for i = 1:num_obstacles
    if obstacle_radii(i) < min_radius || obstacle_radii(i) > max_radius
        results.check1_radius_range.passed = false;
        results.check1_radius_range.violations = [results.check1_radius_range.violations; i, obstacle_radii(i)];
    end
end

% ============================================================================
% CONSTRAINT CHECK 2: Minimum Distance Between Obstacles in Same Pair (ACTIVE)
% ============================================================================
results.check2_min_pair_distance = struct();
results.check2_min_pair_distance.passed = true;
results.check2_min_pair_distance.violations = [];

numCentersPerSet = 2;
numSets = pairs_number;

for i = 1:numSets
    startIndex = (i - 1) * numCentersPerSet + 1;
    endIndex = i * numCentersPerSet;
    
    radius = obstacle_radii(startIndex);
    distance_between_obstacles = norm(centers(startIndex,:) - centers(endIndex,:));
    min_required = min_distance_between_obstacle_pairs + 2*radius;
    
    if distance_between_obstacles < min_required
        results.check2_min_pair_distance.passed = false;
        results.check2_min_pair_distance.violations = [results.check2_min_pair_distance.violations; ...
            i, distance_between_obstacles, min_required];
    end
end

% ============================================================================
% CONSTRAINT CHECK 3: Maximum Distance Between Obstacles in Same Pair (ACTIVE)
% ============================================================================
results.check3_max_pair_distance = struct();
results.check3_max_pair_distance.passed = true;
results.check3_max_pair_distance.violations = [];

for i = 1:numSets
    startIndex = (i - 1) * numCentersPerSet + 1;
    endIndex = i * numCentersPerSet;
    
    radius = obstacle_radii(startIndex);
    distance_between_obstacles = norm(centers(startIndex,:) - centers(endIndex,:));
    max_allowed = max_distance_between_obstacle_pairs + 2*radius;
    
    if distance_between_obstacles > max_allowed
        results.check3_max_pair_distance.passed = false;
        results.check3_max_pair_distance.violations = [results.check3_max_pair_distance.violations; ...
            i, distance_between_obstacles, max_allowed];
    end
end

% ============================================================================
% CONSTRAINT CHECK 4: Rectangle Collisions (ACTIVE)
% ============================================================================
results.check4_rectangle_collisions = struct();
results.check4_rectangle_collisions.passed = true;
results.check4_rectangle_collisions.violations = [];

rectangles = zeros(numSets, 4); % [xMin, yMin, width, height]

for i = 1:numSets
    startIndex = (i - 1) * numCentersPerSet + 1;
    endIndex = i * numCentersPerSet;
    set_centers = centers(startIndex:endIndex, :);
    set_radii = obstacle_radii(startIndex:endIndex);
    
    xMin = min(set_centers(:,1) - set_radii);
    yMin = min(set_centers(:,2) - set_radii);
    xMax = max(set_centers(:,1) + set_radii);
    yMax = max(set_centers(:,2) + set_radii);
    
    width = xMax - xMin;
    height = yMax - yMin;
    
    rectangles(i, :) = [xMin, yMin, width, height];
end

% Check for collisions between rectangles
colliding_pairs = [];
for i = 1:numSets
    for j = i+1:numSets
        if checkRectangleCollision(rectangles(i,1), rectangles(i,2), rectangles(i,3), rectangles(i,4), ...
                rectangles(j,1), rectangles(j,2), rectangles(j,3), rectangles(j,4))
            results.check4_rectangle_collisions.passed = false;
            colliding_pairs = [colliding_pairs; i, j];
        end
    end
end
results.check4_rectangle_collisions.violations = colliding_pairs;

% ============================================================================
% CONSTRAINT CHECK 5: Collision Check Between Obstacles from Different Pairs (ACTIVE)
% ============================================================================
results.check5_obstacle_collisions = struct();
results.check5_obstacle_collisions.passed = true;
results.check5_obstacle_collisions.violations = [];

colliding_obstacles = [];
for i = 1:num_obstacles
    for j = i+1:num_obstacles
        % Determine which pairs these obstacles belong to
        pair_i = ceil(i / 2);
        pair_j = ceil(j / 2);
        
        % Skip if they're in the same pair (already checked above)
        if pair_i == pair_j
            continue
        end
        
        center1 = centers(i, :);
        center2 = centers(j, :);
        radius1 = obstacle_radii(i);
        radius2 = obstacle_radii(j);
        distance = norm(center1 - center2);
        
        % Check if obstacles overlap (collision)
        min_required = radius1 + radius2 + min_distance_between_obstacles;
        if distance < min_required
            results.check5_obstacle_collisions.passed = false;
            colliding_obstacles = [colliding_obstacles; i, j, distance, min_required];
        end
    end
end
results.check5_obstacle_collisions.violations = colliding_obstacles;

% ============================================================================
% CONSTRAINT CHECK 6: Obstacles Within Bounds (ACTIVE)
% ============================================================================
results.check6_bounds = struct();
results.check6_bounds.passed = true;
results.check6_bounds.violations = [];

out_of_bounds = [];
for i = 1:num_obstacles
    center = centers(i, :);
    radius = obstacle_radii(i);
    
    % Check if obstacle extends beyond boundaries
    if (center(1) - radius < x_margin) || (center(1) + radius > x_range - x_margin) || ...
       (center(2) - radius < y_margin) || (center(2) + radius > y_range - y_margin)
        results.check6_bounds.passed = false;
        out_of_bounds = [out_of_bounds; i, center, radius];
    end
end
results.check6_bounds.violations = out_of_bounds;

% ============================================================================
% CONSTRAINT CHECK 7: Start/End Points Within Bounds (ACTIVE)
% ============================================================================
results.check7_start_end_bounds = struct();
results.check7_start_end_bounds.passed = true;
results.check7_start_end_bounds.violations = [];
room = 3;
if X_s(1) < 0 -room || X_s(1) > x_range + room || X_s(2) < 0 || X_s(2) > y_range
    results.check7_start_end_bounds.passed = false;
    results.check7_start_end_bounds.violations = [results.check7_start_end_bounds.violations; 1, X_s];
end

if X_e(1) < 0- room || X_e(1) > x_range + room || X_e(2) < 0 || X_e(2) > y_range
    results.check7_start_end_bounds.passed = false;
    results.check7_start_end_bounds.violations = [results.check7_start_end_bounds.violations; 2, X_e];
end

% ============================================================================
% CONSTRAINT CHECK 8: Start/End Distance (OPTIONAL - Currently commented out in create script)
% ============================================================================
% This check is commented out in create_obstacle_sets.m, but included here
% for completeness. Uncomment if you want to validate this constraint.
results.check8_start_end_distance = struct();
results.check8_start_end_distance.passed = true;
results.check8_start_end_distance.violations = [];
results.check8_start_end_distance.enabled = false;  % Set to true to enable

if results.check8_start_end_distance.enabled
    for i = 1:num_obstacles
        obstacle_position = centers(i, :);
        obstacle_radius = obstacle_radii(i);
        
        distance_to_start = norm(X_s - obstacle_position);
        distance_to_end = norm(X_e - obstacle_position);
        
        % Check first obstacle's distance to start point
        if i == 1
            if distance_to_start < (min_distance_to_end_and_start + obstacle_radius) || ...
               distance_to_start > (max_distance_to_end_and_start + obstacle_radius)
                results.check8_start_end_distance.passed = false;
                results.check8_start_end_distance.violations = [results.check8_start_end_distance.violations; ...
                    i, 1, distance_to_start, min_distance_to_end_and_start + obstacle_radius, max_distance_to_end_and_start + obstacle_radius];
            end
        % Check last obstacle's distance to end point
        elseif i == num_obstacles
            if distance_to_end < (min_distance_to_end_and_start + obstacle_radius) || ...
               distance_to_end > (max_distance_to_end_and_start + obstacle_radius)
                results.check8_start_end_distance.passed = false;
                results.check8_start_end_distance.violations = [results.check8_start_end_distance.violations; ...
                    i, 2, distance_to_end, min_distance_to_end_and_start + obstacle_radius, max_distance_to_end_and_start + obstacle_radius];
            end
        else
            % For all other obstacles, ensure they're not too close to start/end
            if distance_to_start < (min_distance_to_end_and_start + obstacle_radius)
                results.check8_start_end_distance.passed = false;
                results.check8_start_end_distance.violations = [results.check8_start_end_distance.violations; ...
                    i, 1, distance_to_start, min_distance_to_end_and_start + obstacle_radius, NaN];
            end
            if distance_to_end < (min_distance_to_end_and_start + obstacle_radius)
                results.check8_start_end_distance.passed = false;
                results.check8_start_end_distance.violations = [results.check8_start_end_distance.violations; ...
                    i, 2, distance_to_end, min_distance_to_end_and_start + obstacle_radius, NaN];
            end
        end
    end
end

% ============================================================================
% CONSTRAINT CHECK 9: Middle Points Distance (OPTIONAL - Currently commented out)
% ============================================================================
results.check9_middle_points = struct();
results.check9_middle_points.passed = true;
results.check9_middle_points.violations = [];
results.check9_middle_points.enabled = false;  % Set to true to enable

if results.check9_middle_points.enabled
    X_m = find_middle_point_in_obstacles(centers);
    if exist('pdist', 'file')
        distances = pdist(X_m);
        min_dist = min(distances);
        if min_dist < min_distance_middle_points
            results.check9_middle_points.passed = false;
            results.check9_middle_points.violations = min_dist;
        end
    end
end

% ============================================================================
% FINAL RESULT
% ============================================================================
all_passed = results.check1_radius_range.passed && ...
             results.check2_min_pair_distance.passed && ...
             results.check3_max_pair_distance.passed && ...
             results.check4_rectangle_collisions.passed && ...
             results.check5_obstacle_collisions.passed && ...
             results.check6_bounds.passed && ...
             results.check7_start_end_bounds.passed && ...
             (results.check8_start_end_distance.enabled == false || results.check8_start_end_distance.passed) && ...
             (results.check9_middle_points.enabled == false || results.check9_middle_points.passed);

results.all_passed = all_passed;

% ============================================================================
% DISPLAY RESULTS
% ============================================================================
fprintf('\n');
fprintf('========================================\n');
fprintf('OBSTACLE SET VALIDATION RESULTS\n');
fprintf('========================================\n');
fprintf('Set Number: %d\n', set_number);
fprintf('Number of Pairs: %d\n', pairs_number);
fprintf('File: %s\n', fullFileName);
fprintf('----------------------------------------\n');

% Check 1: Radius Range
status1 = 'PASS';
if ~results.check1_radius_range.passed
    status1 = 'FAIL';
    fprintf('  ❌ Check 1: Obstacle Radius Range - %s\n', status1);
    fprintf('     Violations: %d obstacles out of range\n', size(results.check1_radius_range.violations, 1));
    for v = 1:size(results.check1_radius_range.violations, 1)
        fprintf('       Obstacle %d: radius = %.2f cm (valid range: [%.2f, %.2f])\n', ...
            results.check1_radius_range.violations(v,1), results.check1_radius_range.violations(v,2), min_radius, max_radius);
    end
else
    fprintf('  ✓ Check 1: Obstacle Radius Range - %s\n', status1);
end

% Check 2: Min Pair Distance
status2 = 'PASS';
if ~results.check2_min_pair_distance.passed
    status2 = 'FAIL';
    fprintf('  ❌ Check 2: Minimum Distance Between Obstacles in Same Pair - %s\n', status2);
    fprintf('     Violations: %d pairs too close\n', size(results.check2_min_pair_distance.violations, 1));
    for v = 1:size(results.check2_min_pair_distance.violations, 1)
        fprintf('       Pair %d: distance = %.2f cm (minimum required: %.2f cm)\n', ...
            results.check2_min_pair_distance.violations(v,1), ...
            results.check2_min_pair_distance.violations(v,2), ...
            results.check2_min_pair_distance.violations(v,3));
    end
else
    fprintf('  ✓ Check 2: Minimum Distance Between Obstacles in Same Pair - %s\n', status2);
end

% Check 3: Max Pair Distance
status3 = 'PASS';
if ~results.check3_max_pair_distance.passed
    status3 = 'FAIL';
    fprintf('  ❌ Check 3: Maximum Distance Between Obstacles in Same Pair - %s\n', status3);
    fprintf('     Violations: %d pairs too far apart\n', size(results.check3_max_pair_distance.violations, 1));
    for v = 1:size(results.check3_max_pair_distance.violations, 1)
        fprintf('       Pair %d: distance = %.2f cm (maximum allowed: %.2f cm)\n', ...
            results.check3_max_pair_distance.violations(v,1), ...
            results.check3_max_pair_distance.violations(v,2), ...
            results.check3_max_pair_distance.violations(v,3));
    end
else
    fprintf('  ✓ Check 3: Maximum Distance Between Obstacles in Same Pair - %s\n', status3);
end

% Check 4: Rectangle Collisions
status4 = 'PASS';
if ~results.check4_rectangle_collisions.passed
    status4 = 'FAIL';
    fprintf('  ❌ Check 4: Rectangle Collisions - %s\n', status4);
    fprintf('     Violations: %d rectangle pairs colliding\n', size(results.check4_rectangle_collisions.violations, 1));
    for v = 1:size(results.check4_rectangle_collisions.violations, 1)
        fprintf('       Pairs %d and %d have overlapping bounding rectangles\n', ...
            results.check4_rectangle_collisions.violations(v,1), ...
            results.check4_rectangle_collisions.violations(v,2));
    end
else
    fprintf('  ✓ Check 4: Rectangle Collisions - %s\n', status4);
end

% Check 5: Obstacle Collisions
status5 = 'PASS';
if ~results.check5_obstacle_collisions.passed
    status5 = 'FAIL';
    fprintf('  ❌ Check 5: Obstacle Collisions (Different Pairs) - %s\n', status5);
    fprintf('     Violations: %d obstacle pairs too close\n', size(results.check5_obstacle_collisions.violations, 1));
    for v = 1:size(results.check5_obstacle_collisions.violations, 1)
        fprintf('       Obstacles %d and %d: distance = %.2f cm (minimum required: %.2f cm)\n', ...
            results.check5_obstacle_collisions.violations(v,1), ...
            results.check5_obstacle_collisions.violations(v,2), ...
            results.check5_obstacle_collisions.violations(v,3), ...
            results.check5_obstacle_collisions.violations(v,4));
    end
else
    fprintf('  ✓ Check 5: Obstacle Collisions (Different Pairs) - %s\n', status5);
end

% Check 6: Bounds
status6 = 'PASS';
if ~results.check6_bounds.passed
    status6 = 'FAIL';
    fprintf('  ❌ Check 6: Obstacles Within Bounds - %s\n', status6);
    fprintf('     Violations: %d obstacles out of bounds\n', size(results.check6_bounds.violations, 1));
    for v = 1:size(results.check6_bounds.violations, 1)
        fprintf('       Obstacle %d: center = [%.2f, %.2f], radius = %.2f\n', ...
            results.check6_bounds.violations(v,1), ...
            results.check6_bounds.violations(v,2), ...
            results.check6_bounds.violations(v,3), ...
            results.check6_bounds.violations(v,4));
    end
else
    fprintf('  ✓ Check 6: Obstacles Within Bounds - %s\n', status6);
end

% Check 7: Start/End Bounds
status7 = 'PASS';
if ~results.check7_start_end_bounds.passed
    status7 = 'FAIL';
    fprintf('  ❌ Check 7: Start/End Points Within Bounds - %s\n', status7);
    for v = 1:size(results.check7_start_end_bounds.violations, 1)
        if results.check7_start_end_bounds.violations(v,1) == 1
            fprintf('       Start point: [%.2f, %.2f] is out of bounds\n', ...
                results.check7_start_end_bounds.violations(v,2), ...
                results.check7_start_end_bounds.violations(v,3));
        else
            fprintf('       End point: [%.2f, %.2f] is out of bounds\n', ...
                results.check7_start_end_bounds.violations(v,2), ...
                results.check7_start_end_bounds.violations(v,3));
        end
    end
else
    fprintf('  ✓ Check 7: Start/End Points Within Bounds - %s\n', status7);
end

% Check 8: Start/End Distance (if enabled)
if results.check8_start_end_distance.enabled
    status8 = 'PASS';
    if ~results.check8_start_end_distance.passed
        status8 = 'FAIL';
        fprintf('  ❌ Check 8: Start/End Distance - %s\n', status8);
        fprintf('     Violations: %d obstacles\n', size(results.check8_start_end_distance.violations, 1));
    else
        fprintf('  ✓ Check 8: Start/End Distance - %s\n', status8);
    end
end

% Check 9: Middle Points (if enabled)
if results.check9_middle_points.enabled
    status9 = 'PASS';
    if ~results.check9_middle_points.passed
        status9 = 'FAIL';
        fprintf('  ❌ Check 9: Middle Points Distance - %s\n', status9);
        fprintf('     Minimum distance: %.2f cm (required: %.2f cm)\n', ...
            results.check9_middle_points.violations, min_distance_middle_points);
    else
        fprintf('  ✓ Check 9: Middle Points Distance - %s\n', status9);
    end
end

fprintf('----------------------------------------\n');
if all_passed
    fprintf('✓ OVERALL RESULT: ALL CHECKS PASSED\n');
else
    fprintf('❌ OVERALL RESULT: SOME CHECKS FAILED\n');
end
fprintf('========================================\n');
fprintf('\n');

end

