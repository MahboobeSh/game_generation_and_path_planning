function difficulty_metrics = calculate_game_difficulty_v2(path, obstacles, obstacle_radii, X_s, X_e, x_range, y_range, number_of_pairs, Start_points, End_points)
    % Enhanced difficulty calculation with direction change and positioning metrics
    %
    % NEW METRICS ADDED:
    % Direction Change Metrics:
    %   - total_angular_change: Sum of all angle changes along path (radians)
    %   - max_turn_angle: Maximum single turn angle (radians)
    %   - num_sharp_turns: Number of turns > 45 degrees
    %   - num_very_sharp_turns: Number of turns > 90 degrees
    %   - turn_rate: Angular change per unit path length
    %   - avg_turn_angle: Average turn angle at direction changes
    %
    % Path Shape Metrics:
    %   - direction_reversals_x: Number of times path reverses in X direction
    %   - direction_reversals_y: Number of times path reverses in Y direction
    %   - path_waviness: Measure of oscillation perpendicular to main direction
    %   - slope_variance: Variance of slopes along the path
    %
    % Obstacle Positioning Metrics:
    %   - vertical_spread: How much obstacles span vertically
    %   - horizontal_coverage: How much obstacles block horizontal movement
    %   - bottleneck_count: Number of tight passages (< threshold clearance)
    %   - obstacle_alignment_score: How well obstacles block direct path
    
    % Game generation constraints
    min_distance_between_obstacles = 1.5;
    min_distance_between_obstacle_pairs = 2.0;
    min_distance_to_end_and_start = 2.5;
    
    % Calculate maximum constraints
    max_distance = sqrt(x_range^2 + y_range^2);
    
    if isempty(path) || size(path, 1) < 2
        difficulty_metrics = create_empty_metrics();
        return;
    end
    
    %% ========== BASIC METRICS ==========
    
    % 1. Path Length Factor
    diagonal_distance = sqrt(x_range^2 + y_range^2);
    path_length = sum(sqrt(sum(diff(path).^2, 2)));
    path_length_factor = path_length / diagonal_distance;
    
    % 2. Curvature Factor (both original and segmented)
    original_straight_distance = norm(X_e - X_s);
    curvature_factor_original = (path_length - original_straight_distance) / original_straight_distance;
    
    if nargin >= 9 && exist('Start_points', 'var') && ~isempty(Start_points) && ...
       exist('End_points', 'var') && ~isempty(End_points) && ...
       size(Start_points, 1) == size(End_points, 1) && size(Start_points, 1) > 0
        segmented_straight_distance = 0;
        for i = 1:size(Start_points, 1)
            segmented_straight_distance = segmented_straight_distance + norm(End_points(i, :) - Start_points(i, :));
        end
        curvature_factor_segmented = (path_length - segmented_straight_distance) / segmented_straight_distance;
        curvature_factor = curvature_factor_segmented;
        straight_line_distance = segmented_straight_distance;
    else
        curvature_factor_segmented = curvature_factor_original;
        curvature_factor = curvature_factor_original;
        straight_line_distance = original_straight_distance;
    end
    
    %% ========== DIRECTION CHANGE METRICS (NEW) ==========
    
    % Calculate angles and direction changes along the path
    [total_angular_change, max_turn_angle, num_sharp_turns, num_very_sharp_turns, ...
     turn_angles, turn_rate, avg_turn_angle, direction_reversals_x, direction_reversals_y] = ...
        calculate_direction_metrics(path, path_length);
    
    %% ========== PATH SHAPE METRICS (NEW) ==========
    
    % Calculate slope-based metrics
    [slope_variance, path_waviness, slope_changes] = calculate_slope_metrics(path, X_s, X_e);
    
    %% ========== REHABILITATION METRICS (NEW) ==========
    
    % Calculate rehabilitation/bio-motor difficulty metrics
    rehab_metrics = calculate_rehab_metrics(path, obstacles, obstacle_radii, x_range, y_range);
    
    %% ========== CLEARANCE METRICS ==========
    
    % Minimum clearance and average obstacle distance
    [min_clearance, avg_obstacle_distance, bottleneck_count, clearance_profile] = ...
        calculate_clearance_metrics(path, obstacles, obstacle_radii);
    
    %% ========== OBSTACLE POSITIONING METRICS (NEW) ==========
    
    [vertical_spread, horizontal_coverage, obstacle_alignment_score, ...
     obstacle_clustering, position_difficulty] = ...
        calculate_positioning_metrics(obstacles, obstacle_radii, X_s, X_e, x_range, y_range);
    
    %% ========== OBSTACLE PAIR METRICS ==========
    
    [min_pair_distance, avg_pair_distance, pair_distances] = ...
        calculate_pair_distances(obstacles, obstacle_radii);
    
    %% ========== CONSTRAINT TIGHTNESS ==========
    
    [constraint_tightness, pair_tightness, inter_pair_tightness, ...
     start_tightness, end_tightness, min_inter_pair_distance, ...
     min_start_distance, min_end_distance] = ...
        calculate_constraint_tightness(obstacles, obstacle_radii, X_s, X_e, ...
            min_distance_between_obstacles, min_distance_between_obstacle_pairs, ...
            min_distance_to_end_and_start, min_pair_distance);
    
    %% ========== OTHER METRICS ==========
    
    % Obstacle density
    game_area = x_range * y_range;
    num_obstacles = size(obstacles, 1);
    obstacle_density = num_obstacles / game_area;
    
    % Number of segments (direction changes > 30 degrees)
    num_segments = sum(turn_angles > pi/6) + 1;
    
    % Average obstacle size
    avg_obstacle_size = mean(obstacle_radii);
    
    %% ========== COMPOSITE DIFFICULTY SCORE (REVISED) ==========
    
    % Normalize all factors to 0-1 range
    norms = struct();
    
    % Path metrics
    norms.path_length = min(path_length_factor / 2, 1);
    norms.curvature = min(curvature_factor / 0.5, 1);
    
    % Direction change metrics (NEW)
    norms.total_angular = min(total_angular_change / (2*pi), 1);  % 360 degrees = 1
    norms.max_turn = min(max_turn_angle / pi, 1);  % 180 degrees = 1
    norms.sharp_turns = min(num_sharp_turns / 5, 1);
    norms.turn_rate = min(turn_rate * 10, 1);  % Normalized turn rate
    
    % Path shape metrics (NEW)
    norms.slope_variance = min(slope_variance / 2, 1);
    norms.waviness = min(path_waviness / 5, 1);
    norms.reversals = min((direction_reversals_x + direction_reversals_y) / 4, 1);
    
    % Clearance metrics
    norms.clearance = 1 - min(min_clearance / 5, 1);  % Inverse
    norms.avg_distance = 1 - min(avg_obstacle_distance / 10, 1);  % Inverse
    norms.bottlenecks = min(bottleneck_count / 3, 1);
    
    % Positioning metrics (NEW)
    norms.vertical_spread = vertical_spread;  % Already 0-1
    norms.horizontal_coverage = horizontal_coverage;  % Already 0-1
    norms.alignment = obstacle_alignment_score;  % Already 0-1
    norms.position_diff = position_difficulty;  % Already 0-1
    
    % Rehabilitation metrics (NEW)
    % Normalize rehab metrics to 0-1 range
    norms.steering_index = min(rehab_metrics.SteeringIndex / 50, 1);  % Normalize (adjust threshold as needed)
    norms.inflection_counts = min(rehab_metrics.InflectionCounts / 10, 1);  % Normalize
    norms.avg_reach_strain = min(rehab_metrics.AvgReachStrain, 1);  % Already 0-1 typically
    norms.max_reach_strain = min(rehab_metrics.MaxReachStrain, 1);  % Already 0-1 typically
    norms.geometric_jerk = min(rehab_metrics.GeometricJerk / 0.5, 1);  % Normalize (adjust threshold as needed)
    norms.rehab_composite = min(rehab_metrics.CompositeScore / 100, 1);  % Normalize composite score
    
    % Pair and constraint metrics
    if isfinite(min_pair_distance)
        norms.pair_distance = 1 - min(min_pair_distance / 5, 1);
    else
        norms.pair_distance = 0;
    end
    norms.constraint = constraint_tightness;
    
    % Other metrics
    norms.density = min(obstacle_density * 100, 1);
    norms.segments = min(num_segments / 10, 1);
    
    % Equal weights for all metrics (to see individual effects)
    % All weights set to 1, then normalized to sum to 1
    weights = struct();
    
    % Path complexity
    weights.path_length = 1;
    weights.curvature = 1;
    weights.slope_variance = 1;
    weights.waviness = 1;
    
    % Direction changes
    weights.total_angular = 1;
    weights.max_turn = 1;
    weights.sharp_turns = 1;
    weights.reversals = 1;
    
    % Clearance
    weights.clearance = 1;
    weights.avg_distance = 1;
    weights.bottlenecks = 1;
    
    % Positioning
    weights.horizontal_coverage = 1;
    weights.alignment = 1;
    weights.position_diff = 1;
    
    % Other
    weights.pair_distance = 1;
    weights.constraint = 1;
    weights.density = 1;
    
    % Rehabilitation metrics (NEW)
    weights.steering_index = 1;
    weights.inflection_counts = 1;
    weights.avg_reach_strain = 1;
    weights.max_reach_strain = 1;
    weights.geometric_jerk = 1;
    weights.rehab_composite = 1;
    
    % Normalize all weights to sum to 1
    total_weight = weights.path_length + weights.curvature + weights.slope_variance + ...
                   weights.waviness + weights.total_angular + weights.max_turn + ...
                   weights.sharp_turns + weights.reversals + weights.clearance + ...
                   weights.avg_distance + weights.bottlenecks + weights.horizontal_coverage + ...
                   weights.alignment + weights.position_diff + weights.pair_distance + ...
                   weights.constraint + weights.density + weights.steering_index + ...
                   weights.inflection_counts + weights.avg_reach_strain + weights.max_reach_strain + ...
                   weights.geometric_jerk + weights.rehab_composite;
    
    % Normalize each weight
    weights.path_length = weights.path_length / total_weight;
    weights.curvature = weights.curvature / total_weight;
    weights.slope_variance = weights.slope_variance / total_weight;
    weights.waviness = weights.waviness / total_weight;
    weights.total_angular = weights.total_angular / total_weight;
    weights.max_turn = weights.max_turn / total_weight;
    weights.sharp_turns = weights.sharp_turns / total_weight;
    weights.reversals = weights.reversals / total_weight;
    weights.clearance = weights.clearance / total_weight;
    weights.avg_distance = weights.avg_distance / total_weight;
    weights.bottlenecks = weights.bottlenecks / total_weight;
    weights.horizontal_coverage = weights.horizontal_coverage / total_weight;
    weights.alignment = weights.alignment / total_weight;
    weights.position_diff = weights.position_diff / total_weight;
    weights.pair_distance = weights.pair_distance / total_weight;
    weights.constraint = weights.constraint / total_weight;
    weights.density = weights.density / total_weight;
    weights.steering_index = weights.steering_index / total_weight;
    weights.inflection_counts = weights.inflection_counts / total_weight;
    weights.avg_reach_strain = weights.avg_reach_strain / total_weight;
    weights.max_reach_strain = weights.max_reach_strain / total_weight;
    weights.geometric_jerk = weights.geometric_jerk / total_weight;
    weights.rehab_composite = weights.rehab_composite / total_weight;
    
    % Calculate overall difficulty
    overall_difficulty = ...
        weights.path_length * norms.path_length + ...
        weights.curvature * norms.curvature + ...
        weights.slope_variance * norms.slope_variance + ...
        weights.waviness * norms.waviness + ...
        weights.total_angular * norms.total_angular + ...
        weights.max_turn * norms.max_turn + ...
        weights.sharp_turns * norms.sharp_turns + ...
        weights.reversals * norms.reversals + ...
        weights.clearance * norms.clearance + ...
        weights.avg_distance * norms.avg_distance + ...
        weights.bottlenecks * norms.bottlenecks + ...
        weights.horizontal_coverage * norms.horizontal_coverage + ...
        weights.alignment * norms.alignment + ...
        weights.position_diff * norms.position_diff + ...
        weights.pair_distance * norms.pair_distance + ...
        weights.constraint * norms.constraint + ...
        weights.density * norms.density + ...
        weights.steering_index * norms.steering_index + ...
        weights.inflection_counts * norms.inflection_counts + ...
        weights.avg_reach_strain * norms.avg_reach_strain + ...
        weights.max_reach_strain * norms.max_reach_strain + ...
        weights.geometric_jerk * norms.geometric_jerk + ...
        weights.rehab_composite * norms.rehab_composite;
    
    % Categorize difficulty
    if overall_difficulty < 0.33
        difficulty_category = 'Easy';
    elseif overall_difficulty < 0.67
        difficulty_category = 'Medium';
    else
        difficulty_category = 'Hard';
    end
    
    %% ========== STORE ALL METRICS ==========
    
    difficulty_metrics = struct();
    
    % Overall
    difficulty_metrics.overall_difficulty = overall_difficulty;
    difficulty_metrics.difficulty_category = difficulty_category;
    
    % Basic path metrics
    difficulty_metrics.path_length = path_length;
    difficulty_metrics.path_length_factor = path_length_factor;
    difficulty_metrics.straight_line_distance = straight_line_distance;
    difficulty_metrics.curvature_factor = curvature_factor;
    difficulty_metrics.curvature_factor_original = curvature_factor_original;
    difficulty_metrics.curvature_factor_segmented = curvature_factor_segmented;
    
    % Direction change metrics (NEW)
    difficulty_metrics.total_angular_change = total_angular_change;
    difficulty_metrics.total_angular_change_deg = rad2deg(total_angular_change);
    difficulty_metrics.max_turn_angle = max_turn_angle;
    difficulty_metrics.max_turn_angle_deg = rad2deg(max_turn_angle);
    difficulty_metrics.num_sharp_turns = num_sharp_turns;  % >45 deg
    difficulty_metrics.num_very_sharp_turns = num_very_sharp_turns;  % >90 deg
    difficulty_metrics.turn_rate = turn_rate;
    difficulty_metrics.avg_turn_angle = avg_turn_angle;
    difficulty_metrics.avg_turn_angle_deg = rad2deg(avg_turn_angle);
    
    % Path shape metrics (NEW)
    difficulty_metrics.direction_reversals_x = direction_reversals_x;
    difficulty_metrics.direction_reversals_y = direction_reversals_y;
    difficulty_metrics.slope_variance = slope_variance;
    difficulty_metrics.path_waviness = path_waviness;
    
    % Clearance metrics
    difficulty_metrics.min_clearance = min_clearance;
    difficulty_metrics.avg_obstacle_distance = avg_obstacle_distance;
    difficulty_metrics.bottleneck_count = bottleneck_count;
    
    % Positioning metrics (NEW)
    difficulty_metrics.vertical_spread = vertical_spread;
    difficulty_metrics.horizontal_coverage = horizontal_coverage;
    difficulty_metrics.obstacle_alignment_score = obstacle_alignment_score;
    difficulty_metrics.position_difficulty = position_difficulty;
    
    % Rehabilitation metrics (NEW)
    difficulty_metrics.steering_index = rehab_metrics.SteeringIndex;
    difficulty_metrics.inflection_counts = rehab_metrics.InflectionCounts;
    difficulty_metrics.avg_reach_strain = rehab_metrics.AvgReachStrain;
    difficulty_metrics.max_reach_strain = rehab_metrics.MaxReachStrain;
    difficulty_metrics.geometric_jerk = rehab_metrics.GeometricJerk;
    difficulty_metrics.rehab_composite_score = rehab_metrics.CompositeScore;
    
    % Obstacle metrics
    difficulty_metrics.obstacle_density = obstacle_density;
    difficulty_metrics.num_segments = num_segments;
    difficulty_metrics.avg_obstacle_size = avg_obstacle_size;
    difficulty_metrics.min_pair_distance = min_pair_distance;
    difficulty_metrics.avg_pair_distance = avg_pair_distance;
    
    % Constraint metrics
    difficulty_metrics.constraint_tightness = constraint_tightness;
    difficulty_metrics.pair_tightness = pair_tightness;
    difficulty_metrics.inter_pair_tightness = inter_pair_tightness;
    difficulty_metrics.min_inter_pair_distance = min_inter_pair_distance;
    difficulty_metrics.min_start_distance = min_start_distance;
    difficulty_metrics.min_end_distance = min_end_distance;
    
    % Store normalized values for analysis
    difficulty_metrics.normalized = norms;
    difficulty_metrics.weights = weights;
    
    % Store game area info
    difficulty_metrics.x_range = x_range;
    difficulty_metrics.y_range = y_range;
    difficulty_metrics.obstacles = obstacles;
end

%% ========== HELPER FUNCTIONS ==========

function [total_angular, max_turn, num_sharp, num_very_sharp, turn_angles, ...
          turn_rate, avg_turn, reversals_x, reversals_y] = calculate_direction_metrics(path, path_length)
    % Calculate direction change metrics along the path
    
    n = size(path, 1);
    total_angular = 0;
    max_turn = 0;
    turn_angles = [];
    reversals_x = 0;
    reversals_y = 0;
    
    if n < 3
        num_sharp = 0;
        num_very_sharp = 0;
        turn_rate = 0;
        avg_turn = 0;
        return;
    end
    
    % Calculate direction vectors
    prev_dir_x = sign(path(2, 1) - path(1, 1));
    prev_dir_y = sign(path(2, 2) - path(1, 2));
    
    for i = 2:n-1
        v1 = path(i, :) - path(i-1, :);
        v2 = path(i+1, :) - path(i, :);
        
        norm_v1 = norm(v1);
        norm_v2 = norm(v2);
        
        if norm_v1 > 1e-6 && norm_v2 > 1e-6
            v1 = v1 / norm_v1;
            v2 = v2 / norm_v2;
            
            % Calculate angle between vectors
            dot_product = dot(v1, v2);
            dot_product = max(-1, min(1, dot_product));  % Clamp for numerical stability
            angle = acos(dot_product);
            
            total_angular = total_angular + angle;
            turn_angles = [turn_angles; angle];
            
            if angle > max_turn
                max_turn = angle;
            end
            
            % Check for direction reversals
            curr_dir_x = sign(v2(1));
            curr_dir_y = sign(v2(2));
            
            if curr_dir_x ~= 0 && prev_dir_x ~= 0 && curr_dir_x ~= prev_dir_x
                reversals_x = reversals_x + 1;
            end
            if curr_dir_y ~= 0 && prev_dir_y ~= 0 && curr_dir_y ~= prev_dir_y
                reversals_y = reversals_y + 1;
            end
            
            if curr_dir_x ~= 0
                prev_dir_x = curr_dir_x;
            end
            if curr_dir_y ~= 0
                prev_dir_y = curr_dir_y;
            end
        end
    end
    
    % Count sharp turns
    num_sharp = sum(turn_angles > pi/4);      % > 45 degrees
    num_very_sharp = sum(turn_angles > pi/2);  % > 90 degrees
    
    % Turn rate (angular change per unit distance)
    if path_length > 0
        turn_rate = total_angular / path_length;
    else
        turn_rate = 0;
    end
    
    % Average turn angle
    if ~isempty(turn_angles)
        avg_turn = mean(turn_angles);
    else
        avg_turn = 0;
    end
end

function [slope_variance, waviness, slope_changes] = calculate_slope_metrics(path, X_s, X_e)
    % Calculate slope-based metrics
    
    n = size(path, 1);
    slope_variance = 0;
    waviness = 0;
    slope_changes = [];
    
    if n < 3
        return;
    end
    
    % Calculate slopes along the path
    slopes = [];
    for i = 1:n-1
        dx = path(i+1, 1) - path(i, 1);
        dy = path(i+1, 2) - path(i, 2);
        if abs(dx) > 1e-6
            slopes = [slopes; dy/dx];
        else
            slopes = [slopes; sign(dy) * 1000];  % Very steep
        end
    end
    
    % Slope variance
    if ~isempty(slopes)
        slope_variance = std(slopes);
    end
    
    % Calculate slope changes
    if length(slopes) > 1
        slope_changes = abs(diff(slopes));
    end
    
    % Waviness: perpendicular deviation from main direction
    main_direction = X_e - X_s;
    main_direction = main_direction / (norm(main_direction) + eps);
    
    % Calculate perpendicular component for each path point
    perp_deviations = [];
    for i = 1:n
        point_vec = path(i, :) - X_s;
        parallel_component = dot(point_vec, main_direction);
        perp_vec = point_vec - parallel_component * main_direction;
        perp_deviations = [perp_deviations; norm(perp_vec)];
    end
    
    % Waviness is the standard deviation of perpendicular deviations
    if ~isempty(perp_deviations)
        waviness = std(perp_deviations);
    end
end

function [min_clearance, avg_distance, bottleneck_count, clearance_profile] = ...
    calculate_clearance_metrics(path, obstacles, obstacle_radii)
    % Calculate clearance-related metrics
    
    min_clearance = inf;
    avg_distance = 0;
    clearance_profile = zeros(size(path, 1), 1);
    bottleneck_threshold = 1.5;  % cm
    
    for i = 1:size(path, 1)
        min_dist_to_any = inf;
        for j = 1:size(obstacles, 1)
            dist = norm(path(i, :) - obstacles(j, :)) - obstacle_radii(j);
            if dist < min_dist_to_any
                min_dist_to_any = dist;
            end
        end
        clearance_profile(i) = min_dist_to_any;
        
        if min_dist_to_any < min_clearance
            min_clearance = min_dist_to_any;
        end
        avg_distance = avg_distance + min_dist_to_any;
    end
    
    avg_distance = avg_distance / size(path, 1);
    
    % Count bottlenecks (local minima below threshold)
    bottleneck_count = 0;
    in_bottleneck = false;
    for i = 1:length(clearance_profile)
        if clearance_profile(i) < bottleneck_threshold
            if ~in_bottleneck
                bottleneck_count = bottleneck_count + 1;
                in_bottleneck = true;
            end
        else
            in_bottleneck = false;
        end
    end
end

function [vertical_spread, horizontal_coverage, alignment_score, clustering, position_diff] = ...
    calculate_positioning_metrics(obstacles, obstacle_radii, X_s, X_e, x_range, y_range)
    % Calculate obstacle positioning metrics
    
    if isempty(obstacles)
        vertical_spread = 0;
        horizontal_coverage = 0;
        alignment_score = 0;
        clustering = 0;
        position_diff = 0;
        return;
    end
    
    n = size(obstacles, 1);
    
    % Ensure obstacle_radii is a column vector for proper element-wise operations
    obstacle_radii = obstacle_radii(:);
    
    % Vertical spread: how much of y_range obstacles cover
    % Calculate min and max y positions (center +/- radius) for each obstacle
    obstacle_y_min = obstacles(:, 2) - obstacle_radii;
    obstacle_y_max = obstacles(:, 2) + obstacle_radii;
    min_y = min(obstacle_y_min);
    max_y = max(obstacle_y_max);
    vertical_spread = (max_y - min_y) / y_range;
    vertical_spread = min(1, max(0, vertical_spread));
    
    % Horizontal coverage: how much obstacles block x-axis movement
    % Sample x positions and check for blocking
    x_samples = linspace(min(X_s(1), X_e(1)), max(X_s(1), X_e(1)), 50);
    blocked_samples = 0;
    
    for x = x_samples
        % Check if any obstacle blocks this x position across full y range
        for i = 1:n
            if abs(obstacles(i, 1) - x) < obstacle_radii(i, 1)
                blocked_samples = blocked_samples + 1;
                break;
            end
        end
    end
    horizontal_coverage = blocked_samples / length(x_samples);
    
    % Alignment score: how well obstacles block the direct path
    direct_line = X_e - X_s;
    direct_length = norm(direct_line);
    direct_dir = direct_line / (direct_length + eps);
    
    obstacles_near_line = 0;
    for i = 1:n
        % Distance from obstacle center to direct line
        t = dot(obstacles(i, :) - X_s, direct_dir);
        closest_point = X_s + t * direct_dir;
        dist_to_line = norm(obstacles(i, :) - closest_point);
        
        % Check if obstacle is near the direct path (within 2x its radius)
        if dist_to_line < 2 * obstacle_radii(i, 1) && t > 0 && t < direct_length
            obstacles_near_line = obstacles_near_line + 1;
        end
    end
    alignment_score = obstacles_near_line / n;
    
    % Clustering: how clustered vs spread out obstacles are
    if n > 1
        distances = [];
        for i = 1:n
            for j = i+1:n
                distances = [distances; norm(obstacles(i, :) - obstacles(j, :))];
            end
        end
        avg_dist = mean(distances);
        expected_dist = sqrt(x_range * y_range / n);  % Expected if uniform
        clustering = 1 - min(1, avg_dist / (2 * expected_dist));
    else
        clustering = 0;
    end
    
    % Overall position difficulty
    position_diff = 0.4 * vertical_spread + 0.3 * horizontal_coverage + ...
                   0.2 * alignment_score + 0.1 * clustering;
end

function [min_pair_dist, avg_pair_dist, pair_distances] = ...
    calculate_pair_distances(obstacles, obstacle_radii)
    % Calculate distances between obstacle pairs
    
    pair_distances = [];
    min_pair_dist = inf;
    
    for i = 1:2:size(obstacles, 1)-1
        if i+1 <= size(obstacles, 1)
            center_dist = norm(obstacles(i, :) - obstacles(i+1, :));
            gap_dist = center_dist - obstacle_radii(i) - obstacle_radii(i+1);
            pair_distances = [pair_distances; gap_dist];
            if gap_dist < min_pair_dist
                min_pair_dist = gap_dist;
            end
        end
    end
    
    if isempty(pair_distances)
        min_pair_dist = inf;
        avg_pair_dist = inf;
    else
        avg_pair_dist = mean(pair_distances);
    end
end

function [constraint_tightness, pair_tight, inter_pair_tight, start_tight, end_tight, ...
          min_inter_pair_dist, min_start_dist, min_end_dist] = ...
    calculate_constraint_tightness(obstacles, obstacle_radii, X_s, X_e, ...
        min_dist_obstacles, min_dist_pairs, min_dist_endpoints, min_pair_distance)
    % Calculate constraint tightness metrics
    
    % Pair tightness
    if isfinite(min_pair_distance) && min_pair_distance > 0
        pair_tight = min_dist_pairs / (min_pair_distance + min_dist_pairs);
    else
        pair_tight = 0;
    end
    
    % Inter-pair tightness
    inter_pair_distances = [];
    for i = 1:2:size(obstacles, 1)-1
        for j = i+2:2:size(obstacles, 1)
            if j <= size(obstacles, 1)
                center_dist = norm(obstacles(i, :) - obstacles(j, :));
                gap_dist = center_dist - obstacle_radii(i) - obstacle_radii(j);
                inter_pair_distances = [inter_pair_distances; gap_dist];
            end
        end
    end
    
    if ~isempty(inter_pair_distances)
        min_inter_pair_dist = min(inter_pair_distances);
        inter_pair_tight = min_dist_obstacles / (min_inter_pair_dist + min_dist_obstacles);
    else
        min_inter_pair_dist = inf;
        inter_pair_tight = 0;
    end
    
    % Start/End tightness
    min_start_dist = inf;
    min_end_dist = inf;
    for i = 1:size(obstacles, 1)
        dist_start = norm(X_s - obstacles(i, :)) - obstacle_radii(i);
        dist_end = norm(X_e - obstacles(i, :)) - obstacle_radii(i);
        if dist_start < min_start_dist
            min_start_dist = dist_start;
        end
        if dist_end < min_end_dist
            min_end_dist = dist_end;
        end
    end
    
    if isfinite(min_start_dist) && min_start_dist > 0
        start_tight = min_dist_endpoints / (min_start_dist + min_dist_endpoints);
    else
        start_tight = 0;
    end
    if isfinite(min_end_dist) && min_end_dist > 0
        end_tight = min_dist_endpoints / (min_end_dist + min_dist_endpoints);
    else
        end_tight = 0;
    end
    
    constraint_tightness = (pair_tight + inter_pair_tight + start_tight + end_tight) / 4;
end

function metrics = create_empty_metrics()
    % Create empty metrics structure
    metrics = struct();
    metrics.overall_difficulty = 0;
    metrics.difficulty_category = 'N/A';
    metrics.path_length = 0;
    metrics.path_length_factor = 0;
    metrics.straight_line_distance = 0;
    metrics.curvature_factor = 0;
    metrics.curvature_factor_original = 0;
    metrics.curvature_factor_segmented = 0;
    metrics.total_angular_change = 0;
    metrics.total_angular_change_deg = 0;
    metrics.max_turn_angle = 0;
    metrics.max_turn_angle_deg = 0;
    metrics.num_sharp_turns = 0;
    metrics.num_very_sharp_turns = 0;
    metrics.turn_rate = 0;
    metrics.avg_turn_angle = 0;
    metrics.avg_turn_angle_deg = 0;
    metrics.direction_reversals_x = 0;
    metrics.direction_reversals_y = 0;
    metrics.slope_variance = 0;
    metrics.path_waviness = 0;
    metrics.min_clearance = 0;
    metrics.avg_obstacle_distance = 0;
    metrics.bottleneck_count = 0;
    metrics.vertical_spread = 0;
    metrics.horizontal_coverage = 0;
    metrics.obstacle_alignment_score = 0;
    metrics.position_difficulty = 0;
    metrics.obstacle_density = 0;
    metrics.num_segments = 0;
    metrics.avg_obstacle_size = 0;
    metrics.min_pair_distance = 0;
    metrics.avg_pair_distance = 0;
    metrics.constraint_tightness = 0;
    metrics.pair_tightness = 0;
    metrics.inter_pair_tightness = 0;
    metrics.min_inter_pair_distance = 0;
    metrics.min_start_distance = 0;
    metrics.min_end_distance = 0;
    metrics.steering_index = 0;
    metrics.inflection_counts = 0;
    metrics.avg_reach_strain = 0;
    metrics.max_reach_strain = 0;
    metrics.geometric_jerk = 0;
    metrics.rehab_composite_score = 0;
end

