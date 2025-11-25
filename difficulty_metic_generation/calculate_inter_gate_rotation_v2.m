function [rotation_metrics] = calculate_inter_gate_rotation_v2(path_curve, num_samples_list)
    % CALCULATE_INTER_GATE_ROTATION_V2 (Includes Start/End)
    % Calculates the change in heading across the entire movement chain:
    % Start -> Gate 1 -> Gate 2 ... -> Gate N -> End
    
    crossing_vectors = [];
    w = 5; % Window size for vector calculation
    
    % --- 1. CALCULATE START VECTOR ---
    % Vector of the first few points (Immediate heading out of Start)
    if size(path_curve, 1) > w
        v_start = path_curve(w, :) - path_curve(1, :);
        v_start = v_start / norm(v_start);
        crossing_vectors = [crossing_vectors; v_start];
    end
    
    % --- 2. EXTRACT VECTORS AT EACH GATE ---
    current_idx = 1;
    for k = 1:length(num_samples_list)
        segment_len = num_samples_list(k);
        crossing_idx = current_idx + segment_len;
        current_idx = crossing_idx; 
        
        if crossing_idx <= w || crossing_idx > size(path_curve, 1) - w
            continue; 
        end
        
        % Purple Line at Gate
        p_start = path_curve(crossing_idx - w, :);
        p_end   = path_curve(crossing_idx + w, :);
        vec = p_end - p_start;
        vec = vec / norm(vec);
        
        crossing_vectors = [crossing_vectors; vec];
    end
    
    % --- 3. CALCULATE END VECTOR ---
    % Vector of the last few points (Heading into End)
    if size(path_curve, 1) > w
        v_end = path_curve(end, :) - path_curve(end-w, :);
        v_end = v_end / norm(v_end);
        crossing_vectors = [crossing_vectors; v_end];
    end
    
    % --- 4. CALCULATE ROTATION ---
    angle_changes = [];
    
    if size(crossing_vectors, 1) < 2
        rotation_metrics.TotalGateRotation = 0;
        return;
    end
    
    for i = 1:size(crossing_vectors, 1) - 1
        v1 = crossing_vectors(i, :);
        v2 = crossing_vectors(i+1, :);
        
        dot_prod = max(min(dot(v1, v2), 1), -1);
        angle_deg = rad2deg(acos(dot_prod));
        
        angle_changes(end+1) = angle_deg;
    end
    
    % --- PACK RESULTS ---
    rotation_metrics = struct();
    rotation_metrics.TotalGateRotation = sum(angle_changes);
    rotation_metrics.MaxGateRotation = max(angle_changes);
    
    % New: Average rotation per transition (Good for normalizing)
    rotation_metrics.AvgRotation = mean(angle_changes);
end