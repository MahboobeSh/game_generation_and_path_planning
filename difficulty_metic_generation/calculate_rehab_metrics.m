function [rehab_metrics] = calculate_rehab_metrics(path_curve, obstacles, obstacle_radii, x_range, y_range, num_samples_list)
    % CALCULATE_REHAB_METRICS (V7 - Full Integration)
    % Inputs:
    %   path_curve: Nx2 smoothed path
    %   obstacles: Mx2 obstacle centers
    %   obstacle_radii: Mx1 radii
    %   x_range, y_range: Workspace dimensions
    %   num_samples_list: (Optional) Array defining points per segment for gate logic
    
    %% 1. Standard Metrics (Steering, Inflections, Goal Alignment)
    
    % --- Steering Index (Precision) ---
    obstacle_radii = obstacle_radii(:); 
    diffs = diff(path_curve);
    step_lengths = sqrt(sum(diffs.^2, 2));
    
    path_points = path_curve(1:end-1, :); 
    min_clearances = zeros(size(path_points, 1), 1);
    
    for i = 1:size(path_points, 1)
        pt = path_points(i, :);
        dist_to_centers = sqrt(sum((obstacles - pt).^2, 2));
        dists_to_edge = dist_to_centers - obstacle_radii;
        width = 2 * max(min(dists_to_edge), 0.1); 
        min_clearances(i) = width;
    end
    steering_index = sum(step_lengths ./ min_clearances);

    % --- Inflection Count (Micro-Waviness) ---
    dx = gradient(path_curve(:,1));
    dy = gradient(path_curve(:,2));
    ddx = gradient(dx);
    ddy = gradient(dy);
    denom = (dx.^2 + dy.^2).^(3/2);
    denom(denom < 1e-6) = 1e-6;
    curvature = (dx .* ddy - dy .* ddx) ./ denom;
    curvature(isnan(curvature)) = 0;
    
    sign_changes = 0;
    threshold = 0.001; 
    for i = 2:length(curvature)
        if abs(curvature(i)) > threshold && abs(curvature(i-1)) > threshold
            if sign(curvature(i)) ~= sign(curvature(i-1))
                sign_changes = sign_changes + 1;
            end
        end
    end

    % --- Goal Alignment (Cognitive Conflict) ---
    end_point = path_curve(end, :);
    alignment_scores = [];
    for i = 1:size(path_points, 1)
        current_pt = path_points(i, :);
        vec_to_goal = end_point - current_pt;
        dist_to_goal = norm(vec_to_goal);
        current_move_vec = [dx(i), dy(i)];
        norm_move = norm(current_move_vec);
        if norm_move > 1e-6 && dist_to_goal > 1e-6
            vec_to_goal = vec_to_goal / dist_to_goal;
            current_move_vec = current_move_vec / norm_move;
            dot_prod = max(min(dot(vec_to_goal, current_move_vec), 1), -1);
            alignment_scores(end+1) = acos(dot_prod);
        end
    end
    if isempty(alignment_scores), goal_metric = 0; else, goal_metric = mean(alignment_scores); end

    %% 2. Directional Flow Metrics (Y-Reversals & Verticality)
    
    % Y-Axis Reversals (Zigzag Count)
    y_vel = diff(path_curve(:,2));
    y_vel = smoothdata(y_vel, 'gaussian', 5); % Smooth noise
    
    y_reversals = 0;
    current_sign = sign(y_vel(1));
    for k = 2:length(y_vel)
        if abs(y_vel(k)) > 0.05 % Velocity threshold
            new_sign = sign(y_vel(k));
            if new_sign ~= current_sign && new_sign ~= 0
                y_reversals = y_reversals + 1;
                current_sign = new_sign;
            end
        end
    end

    % Path Verticality (Aspect Ratio)
    total_dx = sum(abs(diff(path_curve(:,1))));
    total_dy = sum(abs(diff(path_curve(:,2))));
    if total_dx == 0, total_dx = 1; end
    verticality_ratio = total_dy / total_dx;

    % Cumulative Turning Angle (Micro-Rotation)
    headings = atan2(diff(path_curve(:,2)), diff(path_curve(:,1)));
    headings = unwrap(headings);
    total_rotation = sum(abs(diff(headings)));

    %% 3. Gate Rotation (Macro-Flow Logic)
    % Only runs if segment data (num_samples_list) is provided
    if nargin >= 6 && ~isempty(num_samples_list)
        try
            % Calls the helper function we defined for Start->Gate->End rotation
            rot_m = calculate_inter_gate_rotation_v2(path_curve, num_samples_list);
            gate_rotation_score = deg2rad(rot_m.TotalGateRotation);
        catch
            gate_rotation_score = 0;
        end
    else
        gate_rotation_score = 0;
    end

    %% 6. Consistency Checks (Length & Slope)
    
    % A. Average Path Slope (Degrees)
    step_headings = atan2(diffs(:,2), diffs(:,1)); 
    avg_path_slope = mean(abs(rad2deg(step_headings)));
    
    % B. Total Path Length (cm)
    total_path_length = sum(step_lengths);


    %% 4. Pack Results
    rehab_metrics = struct();
    rehab_metrics.SteeringIndex = steering_index;
    rehab_metrics.InflectionCounts = sign_changes;
    rehab_metrics.GoalAlignmentAvgDeg = goal_metric;
    
    % Directional Metrics
    rehab_metrics.Y_Reversals = y_reversals;       
    rehab_metrics.Verticality = verticality_ratio; 
    rehab_metrics.TotalRotation = total_rotation;  
    rehab_metrics.GateRotation = gate_rotation_score; % The new macro-metric
    
    % Consistency Metrics (Not in Composite Score)
    rehab_metrics.AvgPathSlope = avg_path_slope;
    rehab_metrics.PathLength = total_path_length;
    % === UPDATED COMPOSITE SCORE ===
    % Steering (1.0): Base difficulty (Narrowness/Length)
    % Goal Alignment (0.5): Conflict with end point (Average Intensity)
    % Y-Reversals (2.0): Penalty for full stops/direction switches
    % Gate Rotation (2.0): Penalty for high "Zigzag" intensity (Macro turns)
    
    rehab_metrics.CompositeScore = (steering_index * 1.0) + ...
                                   (goal_metric * 10.0) + ...
                                   (verticality_ratio * 2.0) + ...
                                   (gate_rotation_score * 2.0); 
end