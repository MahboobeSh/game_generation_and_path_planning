function [rehab_metrics] = calculate_rehab_metrics_minimal(path_curve, obstacles, obstacle_radii)
    % CALCULATE_REHAB_METRICS (Final Thesis Version)
    % Implements the Extended Steering Law (Accot-Zhai):
    % ID = Steering_Index + alpha * log(1 + K)
    %
    % Inputs:
    %   path_curve: Nx2 smoothed path (Ideally sampled at 0.25 cm)
    %   obstacles: Mx2 obstacle centers
    %   obstacle_radii: Mx1 radii
    
    %% 1. Derivatives & Geometry
    % Calculate step lengths (ds) and total length
    diffs = diff(path_curve);
    step_lengths = sqrt(sum(diffs.^2, 2));
    total_length = sum(step_lengths);
    
    %% 2. Steering Index (The "Constraint" Term)
    % Formula: Sum( ds / Width )
    obstacle_radii = obstacle_radii(:); 
    path_points = path_curve(1:end-1, :); 
    min_clearances = zeros(size(path_points, 1), 1);
    
    for i = 1:size(path_points, 1)
        pt = path_points(i, :);
        dist_to_centers = sqrt(sum((obstacles - pt).^2, 2));
        dists_to_edge = dist_to_centers - obstacle_radii;
        % Tunnel Width = 2 * Radius (Clamped at 0.1cm for safety)
        width = 2 * max(min(dists_to_edge), 0.1); 
        min_clearances(i) = width;
    end
    steering_index = sum(step_lengths ./ min_clearances);

    %% 3. Total Curvature K (The "Geometry" Term)
    % Formula: K = Sum of absolute angle changes (in Radians)
    
    % Calculate heading angle at each step
    headings = atan2(diffs(:,2), diffs(:,1));
    headings = unwrap(headings); % Handle 360-degree jumps
    
    % K = Integral of |d_theta|
    K_total_rotation = sum(abs(diff(headings)));

    %% 4. Metadata: Average Path Slope (Orientation)
    % This is NOT K. This is the average steepness of the path.
    % 0 deg = Horizontal, 90 deg = Vertical.
    avg_path_slope_deg = mean(abs(rad2deg(headings)));

    %% 5. Composite Score (Extended Steering Law)
    % Formula: ID = Steering + alpha * log(1 + K)
    
    alpha = 5.0; % Empirical weighting factor
    curvature_term =  log(1 + K_total_rotation);
    
    composite_score = steering_index + alpha *curvature_term;

    %% 6. Pack Results
    rehab_metrics = struct();
    
    % Primary Difficulty Metrics (For Score)
    rehab_metrics.SteeringIndex = steering_index;      
    rehab_metrics.K_TotalRotation = K_total_rotation;  
    rehab_metrics.CurvatureTerm = curvature_term;      
    rehab_metrics.CompositeScore = composite_score;    
    
    % Metadata (For Categorization/Filtering)
    rehab_metrics.PathLength = total_length;
    rehab_metrics.AvgPathSlope = avg_path_slope_deg;
end