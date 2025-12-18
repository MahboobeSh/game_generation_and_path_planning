function [X_s, X_e] = findBestStartEndPoints(centers, radii, rectangles, x_range, y_range, number_of_pairs)
    % findBestStartEndPoints - Intelligently places start and end points
    %
    % This function tries multiple candidate positions and selects the best
    % ones based on:
    %   1. Alignment with first/last gates
    %   2. Distance from obstacles
    %   3. Not too close to edges
    %   4. Good path potential
    %
    % Inputs:
    %   centers - Nx2 array of obstacle centers
    %   radii - Nx1 array of obstacle radii
    %   rectangles - Mx4 array of bounding rectangles
    %   x_range, y_range - Play area dimensions
    %   number_of_pairs - Number of obstacle pairs
    %
    % Outputs:
    %   X_s - Start point [x, y]
    %   X_e - End point [x, y]
    
    % Configuration
    start_end_x_margin = 0.5;  % Small margin from edges
    start_end_y_margin = 2.0;  % Minimum Y margin
    num_candidates = 5;  % Try 5 different positions
    
    % === GENERATE START POINT CANDIDATES ===
    midpoint_first = (centers(1,:) + centers(2,:)) / 2;
    
    start_candidates = zeros(num_candidates, 2);
    for i = 1:num_candidates
        X_s_x = start_end_x_margin;
        
        if i == 1
            % Option 1: Aligned with first gate midpoint (default)
            X_s_y = midpoint_first(2);
        elseif i == 2
            % Option 2: Random in safe zone
            X_s_y = start_end_y_margin + (y_range - 2*start_end_y_margin) * rand();
        elseif i == 3
            % Option 3: 1/3 from bottom
            X_s_y = y_range / 3;
        elseif i == 4
            % Option 4: 2/3 from bottom
            X_s_y = 2 * y_range / 3;
        else
            % Option 5: Middle
            X_s_y = y_range / 2;
        end
        
        % Clamp to safe bounds
        X_s_y = max(start_end_y_margin, min(y_range - start_end_y_margin, X_s_y));
        start_candidates(i, :) = [X_s_x, X_s_y];
    end
    
    % === GENERATE END POINT CANDIDATES ===
    midpoint_last = (centers(end-1,:) + centers(end,:)) / 2;
    
    end_candidates = zeros(num_candidates, 2);
    for i = 1:num_candidates
        X_e_x = x_range - start_end_x_margin;
        
        if i == 1
            % Option 1: Aligned with last gate midpoint (default)
            X_e_y = midpoint_last(2);
        elseif i == 2
            % Option 2: Random in safe zone
            X_e_y = start_end_y_margin + (y_range - 2*start_end_y_margin) * rand();
        elseif i == 3
            % Option 3: 1/3 from bottom
            X_e_y = y_range / 3;
        elseif i == 4
            % Option 4: 2/3 from bottom
            X_e_y = 2 * y_range / 3;
        else
            % Option 5: Middle
            X_e_y = y_range / 2;
        end
        
        % Clamp to safe bounds
        X_e_y = max(start_end_y_margin, min(y_range - start_end_y_margin, X_e_y));
        end_candidates(i, :) = [X_e_x, X_e_y];
    end
    
    % === SCORE EACH COMBINATION ===
    best_score = -inf;
    best_start = start_candidates(1, :);
    best_end = end_candidates(1, :);
    
    for i = 1:num_candidates
        for j = 1:num_candidates
            candidate_start = start_candidates(i, :);
            candidate_end = end_candidates(j, :);
            
            score = 0;
            
            % Score 1: Distance from all obstacles (higher is better)
            min_dist_start = inf;
            min_dist_end = inf;
            for k = 1:length(radii)
                dist_start = norm(candidate_start - centers(k,:)) - radii(k);
                dist_end = norm(candidate_end - centers(k,:)) - radii(k);
                min_dist_start = min(min_dist_start, dist_start);
                min_dist_end = min(min_dist_end, dist_end);
            end
            score = score + min_dist_start + min_dist_end;
            
            % Score 2: Not too far from vertical center (prefer middle Y values)
            y_center = y_range / 2;
            dist_from_center_start = abs(candidate_start(2) - y_center);
            dist_from_center_end = abs(candidate_end(2) - y_center);
            score = score - 0.5 * (dist_from_center_start + dist_from_center_end);
            
            % Score 3: Reasonable path straightness (not too zigzag)
            y_diff = abs(candidate_end(2) - candidate_start(2));
            score = score - 0.2 * y_diff;
            
            % Score 4: Bonus for being aligned with gates (i==1, j==1)
            if i == 1 && j == 1
                score = score + 5;  % Preference for gate alignment
            end
            
            % Update best if this is better
            if score > best_score
                best_score = score;
                best_start = candidate_start;
                best_end = candidate_end;
            end
        end
    end
    
    X_s = best_start;
    X_e = best_end;
end

