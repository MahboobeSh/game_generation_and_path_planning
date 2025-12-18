function difficulty_metrics = calculate_game_difficulty(path, obstacles, obstacle_radii, X_s, X_e, x_range, y_range, number_of_pairs, Start_points, End_points)
    % Calculate comprehensive difficulty metrics for the game
    % Returns a structure with various difficulty measures
    % Incorporates game generation constraints and metrics
    %
    % Inputs:
    %   path - Nx2 matrix of path coordinates
    %   obstacles - Mx2 matrix of obstacle center coordinates
    %   obstacle_radii - Mx1 vector of obstacle radii
    %   X_s - 1x2 start point coordinates
    %   X_e - 1x2 end point coordinates
    %   x_range - x-axis extent of game area
    %   y_range - y-axis extent of game area
    %   number_of_pairs - number of obstacle pairs
    %
    % Outputs:
    %   difficulty_metrics - structure containing:
    %       overall_difficulty - composite score (0-1)
    %       difficulty_category - 'Easy', 'Medium', or 'Hard'
    %       path_length_factor - normalized path length
    %       curvature_factor - deviation from straight line
    %       min_clearance - narrowest gap to obstacles
    %       avg_obstacle_distance - average distance to obstacles
    %       obstacle_density - obstacles per unit area
    %       num_segments - number of significant turns
    %       avg_obstacle_size - average obstacle radius
    %       path_length - total path length
    %       straight_line_distance - direct distance from start to end
    
    % Game generation constraints (from create_obstacle_sets.m)
    min_distance_between_obstacles = 1.5;  % Minimum gap between obstacles from different pairs (cm)
    min_distance_between_obstacle_pairs = 2.0;  % Minimum gap between obstacles in same pair (cm)
    min_distance_to_end_and_start = 2.5;  % Minimum distance from start/end points (cm)
    min_radius = 2;  % Minimum obstacle radius (cm)
    max_radius = 4;  % Maximum obstacle radius (cm)
    
    % Calculate maximum constraints (scaled with number of pairs)
    max_distance = sqrt(x_range^2 + y_range^2);
    max_distance_to_end_and_start = 0.15*max_distance + 0.2*(max_distance/number_of_pairs);
    max_distance_between_obstacle_pairs = 0.05*max_distance + 0.03*(max_distance/number_of_pairs);
    
    if isempty(path) || size(path, 1) < 2
        % If no path, return default difficulty
        difficulty_metrics = struct();
        difficulty_metrics.overall_difficulty = 0;
        difficulty_metrics.path_length_factor = 0;
        difficulty_metrics.curvature_factor = 0;
        difficulty_metrics.min_clearance = 0;
        difficulty_metrics.avg_obstacle_distance = 0;
        difficulty_metrics.obstacle_density = 0;
        difficulty_metrics.num_segments = 0;
        difficulty_metrics.avg_obstacle_size = 0;
        difficulty_metrics.min_pair_distance = 0;
        difficulty_metrics.avg_pair_distance = 0;
        difficulty_metrics.constraint_tightness = 0;
        difficulty_metrics.difficulty_category = 'N/A';
        difficulty_metrics.path_length = 0;
        difficulty_metrics.straight_line_distance = 0;
        return;
    end
    
    % 1. Path Length Factor (normalized by diagonal distance)
    diagonal_distance = sqrt(x_range^2 + y_range^2);
    path_length = sum(sqrt(sum(diff(path).^2, 2)));
    path_length_factor = path_length / diagonal_distance;
    
    % 2. Curvature Factor (deviation from straight line)
    % Calculate both original (single straight line) and segmented (through middle points) curvature
    
    % Original curvature: single straight line from start to end
    original_straight_distance = norm(X_e - X_s);
    curvature_factor_original = (path_length - original_straight_distance) / original_straight_distance;
    
    % Segmented curvature: through middle points (if available)
    if nargin >= 9 && exist('Start_points', 'var') && ~isempty(Start_points) && ...
       exist('End_points', 'var') && ~isempty(End_points) && ...
       size(Start_points, 1) == size(End_points, 1) && size(Start_points, 1) > 0
        % Calculate segmented straight line through middle points
        % Start_points = [X_s; middle_points], End_points = [middle_points; X_e]
        segmented_straight_distance = 0;
        for i = 1:size(Start_points, 1)
            segmented_straight_distance = segmented_straight_distance + norm(End_points(i, :) - Start_points(i, :));
        end
        curvature_factor_segmented = (path_length - segmented_straight_distance) / segmented_straight_distance;
        % Use segmented as the main curvature factor
        curvature_factor = curvature_factor_segmented;
        straight_line_distance = segmented_straight_distance;
    else
        % Fallback: use single straight line from start to end
        curvature_factor_segmented = curvature_factor_original;
        curvature_factor = curvature_factor_original;
        straight_line_distance = original_straight_distance;
    end
    
    % 3. Minimum Clearance (narrowest gap between path and obstacles)
    min_clearance = inf;
    avg_obstacle_distance = 0;
    for i = 1:size(path, 1)
        min_dist_to_any_obstacle = inf;
        for j = 1:size(obstacles, 1)
            dist_to_obstacle = norm(path(i, :) - obstacles(j, :)) - obstacle_radii(j);
            if dist_to_obstacle < min_dist_to_any_obstacle
                min_dist_to_any_obstacle = dist_to_obstacle;
            end
        end
        if min_dist_to_any_obstacle < min_clearance
            min_clearance = min_dist_to_any_obstacle;
        end
        avg_obstacle_distance = avg_obstacle_distance + min_dist_to_any_obstacle;
    end
    avg_obstacle_distance = avg_obstacle_distance / size(path, 1);
    
    % 4. Obstacle Density (obstacles per unit area)
    game_area = x_range * y_range;
    num_obstacles = size(obstacles, 1);
    obstacle_density = num_obstacles / game_area;
    
    % 5. Number of Segments (complexity indicator)
    % Count significant direction changes in the path
    if size(path, 1) > 2
        direction_changes = 0;
        for i = 2:size(path, 1)-1
            v1 = path(i, :) - path(i-1, :);
            v2 = path(i+1, :) - path(i, :);
            v1 = v1 / (norm(v1) + eps);
            v2 = v2 / (norm(v2) + eps);
            angle_change = acos(dot(v1, v2));
            if angle_change > pi/6  % Significant turn (>30 degrees)
                direction_changes = direction_changes + 1;
            end
        end
        num_segments = direction_changes + 1;
    else
        num_segments = 1;
    end
    
    % 6. Average Obstacle Size Factor
    avg_obstacle_size = mean(obstacle_radii);
    obstacle_size_factor = avg_obstacle_size / (min(x_range, y_range) / 10); % Normalized
    
    % 7. Obstacle Pair Distance (distance between obstacles in each pair)
    % Obstacles are arranged in pairs: (1,2), (3,4), (5,6), etc.
    pair_distances = [];
    min_pair_distance = inf;
    for i = 1:2:size(obstacles, 1)-1
        if i+1 <= size(obstacles, 1)
            % Calculate distance between obstacles in the pair
            % Distance is center-to-center minus both radii (actual gap)
            center_distance = norm(obstacles(i, :) - obstacles(i+1, :));
            gap_distance = center_distance - obstacle_radii(i) - obstacle_radii(i+1);
            pair_distances = [pair_distances; gap_distance];
            if gap_distance < min_pair_distance
                min_pair_distance = gap_distance;
            end
        end
    end
    if isempty(pair_distances)
        min_pair_distance = inf;
        avg_pair_distance = inf;
    else
        avg_pair_distance = mean(pair_distances);
    end
    
    % 8. Game Generation Constraint Metrics
    % Measure how close the actual game is to the generation constraints
    % Games closer to minimums = tighter spaces = harder
    
    % Pair distance constraint tightness
    % Ratio of actual pair distance to minimum required (closer to 1 = tighter = harder)
    if isfinite(min_pair_distance) && min_pair_distance > 0
        pair_tightness = min_distance_between_obstacle_pairs / (min_pair_distance + min_distance_between_obstacle_pairs);
    else
        pair_tightness = 0;
    end
    
    % Inter-pair distance tightness (distance between obstacles from different pairs)
    inter_pair_distances = [];
    for i = 1:2:size(obstacles, 1)-1
        for j = i+2:2:size(obstacles, 1)
            if j <= size(obstacles, 1)
                center_distance = norm(obstacles(i, :) - obstacles(j, :));
                gap_distance = center_distance - obstacle_radii(i) - obstacle_radii(j);
                inter_pair_distances = [inter_pair_distances; gap_distance];
            end
        end
    end
    if ~isempty(inter_pair_distances)
        min_inter_pair_distance = min(inter_pair_distances);
        inter_pair_tightness = min_distance_between_obstacles / (min_inter_pair_distance + min_distance_between_obstacles);
    else
        min_inter_pair_distance = inf;
        inter_pair_tightness = 0;
    end
    
    % Start/End point constraint tightness
    min_start_distance = inf;
    min_end_distance = inf;
    for i = 1:size(obstacles, 1)
        dist_to_start = norm(X_s - obstacles(i, :)) - obstacle_radii(i);
        dist_to_end = norm(X_e - obstacles(i, :)) - obstacle_radii(i);
        if dist_to_start < min_start_distance
            min_start_distance = dist_to_start;
        end
        if dist_to_end < min_end_distance
            min_end_distance = dist_to_end;
        end
    end
    if isfinite(min_start_distance) && min_start_distance > 0
        start_tightness = min_distance_to_end_and_start / (min_start_distance + min_distance_to_end_and_start);
    else
        start_tightness = 0;
    end
    if isfinite(min_end_distance) && min_end_distance > 0
        end_tightness = min_distance_to_end_and_start / (min_end_distance + min_distance_to_end_and_start);
    else
        end_tightness = 0;
    end
    
    % Overall constraint tightness (average of all tightness measures)
    constraint_tightness = (pair_tightness + inter_pair_tightness + start_tightness + end_tightness) / 4;
    
    % 9. Composite Difficulty Score (weighted combination)
    % Normalize each factor to 0-1 range, then combine
    path_length_norm = min(path_length_factor / 2, 1); % Cap at 1
    curvature_norm = min(curvature_factor / 0.5, 1); % Cap at 1
    clearance_norm = 1 - min(min_clearance / 5, 1); % Inverse: smaller clearance = higher difficulty
    distance_norm = 1 - min(avg_obstacle_distance / 10, 1); % Inverse: closer = harder
    density_norm = min(obstacle_density * 100, 1); % Normalize density
    segments_norm = min(num_segments / 10, 1); % Normalize segments
    size_norm = min(obstacle_size_factor, 1);
    % Pair distance: smaller gap = higher difficulty (inverse relationship)
    if isfinite(min_pair_distance)
        pair_distance_norm = 1 - min(min_pair_distance / 5, 1); % Normalize: smaller gap = harder
    else
        pair_distance_norm = 0;
    end
    
    % Constraint tightness: higher tightness = closer to minimums = harder
    constraint_tightness_norm = constraint_tightness; % Already 0-1
    
    % Weighted combination (adjust weights based on importance)
    weights = struct();
    weights.path_length = 0.10;
    weights.curvature = 0.12;
    weights.clearance = 0.18;  % Important - narrow passages
    weights.pair_distance = 0.18;  % Important - obstacle pair gaps
    weights.constraint_tightness = 0.15;  % NEW - how close to generation minimums
    weights.distance = 0.10;
    weights.density = 0.07;
    weights.segments = 0.07;
    weights.size = 0.03;
    
    overall_difficulty = weights.path_length * path_length_norm + ...
                         weights.curvature * curvature_norm + ...
                         weights.clearance * clearance_norm + ...
                         weights.pair_distance * pair_distance_norm + ...
                         weights.constraint_tightness * constraint_tightness_norm + ...
                         weights.distance * distance_norm + ...
                         weights.density * density_norm + ...
                         weights.segments * segments_norm + ...
                         weights.size * size_norm;
    
    % Categorize difficulty
    if overall_difficulty < 0.33
        difficulty_category = 'Easy';
    elseif overall_difficulty < 0.67
        difficulty_category = 'Medium';
    else
        difficulty_category = 'Hard';
    end
    
    % Store all metrics in structure
    difficulty_metrics = struct();
    difficulty_metrics.overall_difficulty = overall_difficulty;
    difficulty_metrics.path_length_factor = path_length_factor;
    difficulty_metrics.curvature_factor = curvature_factor;
    difficulty_metrics.curvature_factor_original = curvature_factor_original;
    difficulty_metrics.curvature_factor_segmented = curvature_factor_segmented;
    difficulty_metrics.min_clearance = min_clearance;
    difficulty_metrics.avg_obstacle_distance = avg_obstacle_distance;
    difficulty_metrics.obstacle_density = obstacle_density;
    difficulty_metrics.num_segments = num_segments;
    difficulty_metrics.avg_obstacle_size = avg_obstacle_size;
    difficulty_metrics.min_pair_distance = min_pair_distance;
    difficulty_metrics.avg_pair_distance = avg_pair_distance;
    difficulty_metrics.constraint_tightness = constraint_tightness;
    difficulty_metrics.pair_tightness = pair_tightness;
    difficulty_metrics.inter_pair_tightness = inter_pair_tightness;
    difficulty_metrics.min_inter_pair_distance = min_inter_pair_distance;
    difficulty_metrics.min_start_distance = min_start_distance;
    difficulty_metrics.min_end_distance = min_end_distance;
    difficulty_metrics.difficulty_category = difficulty_category;
    difficulty_metrics.path_length = path_length;
    difficulty_metrics.straight_line_distance = straight_line_distance;
end

