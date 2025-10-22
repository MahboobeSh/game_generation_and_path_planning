function [cost, grad] = optimize_bezier_to_astar(variables, num_segments, start_points, end_points, astar_path, num_samples, n_d, n_phi, num_samples_list,start_index, end_index)
    variables_matrix = reshape(variables, [], n_d + n_phi + 2);
    curve_segment_points = calculate_curve_segment_points(variables_matrix, start_points, end_points, num_segments, n_d, n_phi);
    
    % Calculate the composite Bézier curve
    composite_curve = [];
    min_distance_vector = [];
    min_distance_vector_temp_2 = [];
    min_distance_vector_temp= [];
    smoothness_penalty = 0;

    for i = 1:num_segments
        segment_control_points = curve_segment_points(:, :, i);
        segment_curve = bezier_curve(segment_control_points, num_samples_list(i));
        composite_curve = [composite_curve; segment_curve];
        min_distance_vector_temp = [];
        for j = 1: size(segment_curve,1)
            d = norm(segment_curve(j,:) - astar_path(start_index(i)-1+j,:));
            min_distance_vector_temp = [min_distance_vector_temp;d];
        end
        % distance_matrix = pdist2(segment_curve , astar_path(start_index(i):end_index(i),:));
        % min_distance_vector_temp_2 = 2*min(distance_matrix, [], 2);
        % if i == 2 || i ==3
        % %     min_distance_vector_temp = *min_distance_vector_temp ;
        % end
        min_distance_vector = [min_distance_vector;min_distance_vector_temp;min_distance_vector_temp_2];
                % Compute gradient (for demonstration, this is a simple approximation)
                % Calculate smoothness penalty (second derivative)
        if size(segment_curve, 1) > 2
            second_derivative = diff(segment_curve, 2, 1);
            smoothness_penalty = smoothness_penalty + sum(sum(second_derivative.^2));
        end
    end

    % Calculate the distance between the Bézier curve and the A* path
    % distance_matrix = pdist2(composite_curve, astar_path);
    % min_distance_vector = min(distance_matrix, [], 2);

    % sorted_distances = sort(distance_matrix, 2);
    % min_distance_vector = sorted_distances(:, 1) + sorted_distances(:, 2) + sorted_distances(:,3);
    path_fidelity_cost = sum(min_distance_vector.^2)/length(min_distance_vector);
    % path_fidelity_cost = sum(abs(min_distance_vector)) / length(min_distance_vector);
    % path_fidelity_cost = sum((log(1 + min_distance_vector)).^2) / length(min_distance_vector);
    % path_fidelity_cost = sum(log(cosh(min_distance_vector))) / length(min_distance_vector);
    % min_distance_vector;
    % delta = 0.2; % Threshold parameter, can be tuned
    % squared_loss = (min_distance_vector.^2) / 2;
    % linear_loss = delta * (abs(min_distance_vector) - delta / 2);
    % path_fidelity_cost = sum((abs(min_distance_vector) <= delta) .* squared_loss + (abs(min_distance_vector) > delta) .* linear_loss) / length(min_distance_vector);

    
    d2y= gradient(composite_curve(:,2));
    smoothness_cost = sum(d2y.^2);

    curve_length_cost = sum(sqrt(sum(diff(composite_curve).^2, 2)))/25;
    smoothness_penalty;

    alpha = 1;
    beta = 0;
    gamma = 0.0;
    cost = alpha * path_fidelity_cost + beta * smoothness_penalty + gamma * curve_length_cost;

end

