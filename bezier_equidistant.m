function curve = bezier_equidistant(points, num_samples)
    % 1. Create a high-resolution sample to measure true arc length
    % We use 1000 points (or 10x samples) to ensure the distance measurement is accurate
    n_high_res = max(2000, num_samples * 10);
    t_high = linspace(0, 1, n_high_res)';
    
    % 2. Evaluate the Bezier curve at high resolution
    n = size(points, 1) - 1; % Degree of curve
    curve_high = zeros(n_high_res, size(points, 2));
    
    for i = 0:n
        % Use your custom binomial_coefficient function here
        b_coef = binomial_coefficient(n, i);
        
        % Calculate contribution of this control point
        b_poly = b_coef .* (1 - t_high).^(n - i) .* t_high.^i;
        curve_high = curve_high + b_poly * points(i+1, :);
    end
    
    % 3. Calculate the Cumulative Arc Length
    % Euclidean distance between consecutive high-res points
    diffs = diff(curve_high, 1, 1); 
    segment_lengths = sqrt(sum(diffs.^2, 2));
    
    % Map 't' to 'physical distance'
    arc_lengths = [0; cumsum(segment_lengths)];
    total_length = arc_lengths(end);
    
    % 4. Determine target distances for perfectly even spacing
    target_lengths = linspace(0, total_length, num_samples);
    
    % 5. Interpolate to find the 't' value for each target distance
    [unique_lengths, unique_idx] = unique(arc_lengths);
    t_at_unique = t_high(unique_idx);
    
    % Find the t values that correspond to exactly equal distances
    t_equidistant = interp1(unique_lengths, t_at_unique, target_lengths, 'linear');
    
    % 6. Generate the final curve using these corrected t values
    curve = zeros(num_samples, size(points, 2));
    for i = 0:n
        % Use your custom binomial_coefficient function here again
        b_coef = binomial_coefficient(n, i);
        
        % Note: We use t_equidistant' (transpose) to keep dimensions consistent
        b_poly = b_coef .* (1 - t_equidistant').^(n - i) .* t_equidistant'.^i;
        curve = curve + b_poly * points(i+1, :);
    end
end
