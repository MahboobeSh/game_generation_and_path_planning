function visualize_game_with_metrics(game_path, varargin)
    % VISUALIZE_GAME_WITH_METRICS - Show game path and comprehensive metrics
    %
    % Usage:
    %   visualize_game_with_metrics('path/to/game.mat')
    %   visualize_game_with_metrics('path/to/game.mat', 'SaveFigure', true)
    %
    % Displays:
    %   - Equalized curve with obstacles
    %   - Path length and difficulty metrics
    %   - Distance between obstacle pairs
    %   - Clearance map
    %   - Steering and rotation metrics
    
    % Parse optional arguments
    p = inputParser;
    addParameter(p, 'SaveFigure', false, @islogical);
    addParameter(p, 'OutputDir', '', @ischar);
    parse(p, varargin{:});
    
    save_fig = p.Results.SaveFigure;
    output_dir = p.Results.OutputDir;
    
    % Load game data
    if ~exist(game_path, 'file')
        error('Game file not found: %s', game_path);
    end
    
    data = load(game_path);
    [~, game_name, ~] = fileparts(game_path);
    
    % Extract game components
    obstacles = data.obstacle;
    obstacle_radii = data.obstacle_radious(:);
    X_s = data.X_s;
    X_e = data.X_e;
    
    % Determine number of pairs
    if isfield(data, 'number_of_pairs')
        num_pairs = data.number_of_pairs;
    else
        num_pairs = size(obstacles, 1) / 2;
    end
    
    % Get path (prefer curve_equalized > curve > path)
    if isfield(data, 'curve_equalized') && ~isempty(data.curve_equalized)
        path = data.curve_equalized;
        path_type = 'Equalized Curve';
    elseif isfield(data, 'curve') && ~isempty(data.curve)
        path = data.curve;
        path_type = 'Bezier Curve';
    elseif isfield(data, 'path') && ~isempty(data.path)
        path = data.path;
        path_type = 'A* Path';
    else
        error('No path found in game data');
    end
    
    % Get game space dimensions
    if isfield(data, 'x_range')
        x_range = data.x_range;
        y_range = data.y_range;
    else
        x_range = 30;
        y_range = 40;
    end
    
    % Calculate path length
    path_length = sum(sqrt(sum(diff(path).^2, 2)));
    
    % Calculate rehab metrics (if function exists)
    try
        if isfield(data, 'num_samples_list')
            rehab_metrics = calculate_rehab_metrics(path, obstacles, obstacle_radii, x_range, y_range, data.num_samples_list);
        else
            rehab_metrics = calculate_rehab_metrics(path, obstacles, obstacle_radii, x_range, y_range, []);
        end
        has_rehab_metrics = true;
    catch
        has_rehab_metrics = false;
        warning('Could not calculate rehab metrics');
    end
    
    % Calculate obstacle pair distances
    pair_distances = calculate_pair_distances(obstacles, num_pairs);
    
    % Calculate clearance along path
    [min_clearance, avg_clearance, clearance_profile] = calculate_clearance_profile(path, obstacles, obstacle_radii);
    
    % Calculate path metrics
    [curvature_factor, straight_distance] = calculate_path_curvature(path, X_s, X_e, data);
    
    % Create figure
    fig = figure('Position', [50, 50, 1600, 1000], 'Name', ['Game Visualization: ' game_name]);
    
    % SUBPLOT 1: Main game visualization with path
    subplot(2, 3, [1, 4]);
    hold on;
    
    % Draw obstacles
    for i = 1:size(obstacles, 1)
        circle = viscircles(obstacles(i, :), obstacle_radii(i), 'Color', 'r', 'LineWidth', 1.5);
    end
    
    % Color path by clearance (inverse: red = narrow, blue = wide)
    path_pts = path;
    clearance_color = 1 ./ max(clearance_profile, 0.1);
    scatter(path_pts(:,1), path_pts(:,2), 20, clearance_color, 'filled');
    colormap(gca, 'jet');
    cb = colorbar;
    cb.Label.String = 'Difficulty (1/Clearance)';
    
    % Mark start and end
    plot(X_s(1), X_s(2), 'go', 'MarkerSize', 12, 'LineWidth', 3, 'DisplayName', 'Start');
    plot(X_e(1), X_e(2), 'bs', 'MarkerSize', 12, 'LineWidth', 3, 'DisplayName', 'End');
    
    % Draw lines between obstacle pairs
    for i = 1:num_pairs
        idx1 = 2*i - 1;
        idx2 = 2*i;
        if idx2 <= size(obstacles, 1)
            plot([obstacles(idx1,1), obstacles(idx2,1)], ...
                 [obstacles(idx1,2), obstacles(idx2,2)], ...
                 'k--', 'LineWidth', 0.5, 'HandleVisibility', 'off');
        end
    end
    
    axis equal;
    grid on;
    xlabel('X (cm)', 'FontSize', 11);
    ylabel('Y (cm)', 'FontSize', 11);
    title(sprintf('%s\n(%s, %d pairs)', game_name, path_type, num_pairs), ...
        'FontSize', 12, 'FontWeight', 'bold', 'Interpreter', 'none');
    legend('Location', 'best');
    
    % SUBPLOT 2: Basic metrics
    subplot(2, 3, 2);
    axis off;
    
    metric_text = sprintf('BASIC METRICS\n');
    metric_text = [metric_text repmat('=', 1, 40) '\n\n'];
    metric_text = [metric_text sprintf('Path Type: %s\n', path_type)];
    metric_text = [metric_text sprintf('Number of Pairs: %d\n\n', num_pairs)];
    metric_text = [metric_text sprintf('Path Length: %.2f cm\n', path_length)];
    metric_text = [metric_text sprintf('Straight Distance: %.2f cm\n', straight_distance)];
    metric_text = [metric_text sprintf('Curvature Factor: %.2f\n\n', curvature_factor)];
    metric_text = [metric_text sprintf('Min Clearance: %.2f cm\n', min_clearance)];
    metric_text = [metric_text sprintf('Avg Clearance: %.2f cm\n\n', avg_clearance)];
    
    if has_rehab_metrics
        metric_text = [metric_text sprintf('REHAB METRICS\n')];
        metric_text = [metric_text repmat('-', 1, 40) '\n'];
        metric_text = [metric_text sprintf('Composite Score: %.2f\n', rehab_metrics.CompositeScore)];
        metric_text = [metric_text sprintf('Steering Index: %.2f\n', rehab_metrics.SteeringIndex)];
        metric_text = [metric_text sprintf('Total Rotation: %.2f rad\n', rehab_metrics.TotalRotation)];
        metric_text = [metric_text sprintf('Gate Rotation: %.2f\n', rehab_metrics.GateRotation)];
        metric_text = [metric_text sprintf('Y Reversals: %d\n', rehab_metrics.Y_Reversals)];
        metric_text = [metric_text sprintf('Inflection Counts: %d\n', rehab_metrics.InflectionCounts)];
    end
    
    text(0.05, 0.95, metric_text, 'FontSize', 10, 'FontName', 'FixedWidth', ...
        'VerticalAlignment', 'top', 'Interpreter', 'none');
    
    % SUBPLOT 3: Obstacle pair distances
    subplot(2, 3, 3);
    bar(1:length(pair_distances), pair_distances, 'FaceColor', [0.3 0.6 0.9]);
    xlabel('Pair Number', 'FontSize', 11);
    ylabel('Distance (cm)', 'FontSize', 11);
    title('Distance Between Obstacle Pairs', 'FontSize', 11, 'FontWeight', 'bold');
    grid on;
    
    % Add mean line
    hold on;
    yline(mean(pair_distances), '--r', sprintf('Mean: %.2f cm', mean(pair_distances)), ...
        'LineWidth', 2, 'LabelHorizontalAlignment', 'left');
    
    % Add text annotations
    for i = 1:length(pair_distances)
        text(i, pair_distances(i), sprintf('%.1f', pair_distances(i)), ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 9);
    end
    
    % SUBPLOT 4: Clearance profile along path
    subplot(2, 3, 5);
    path_progress = linspace(0, 100, length(clearance_profile));
    plot(path_progress, clearance_profile, 'LineWidth', 2, 'Color', [0.2 0.5 0.8]);
    hold on;
    yline(min_clearance, '--r', sprintf('Min: %.2f cm', min_clearance), 'LineWidth', 1.5);
    yline(avg_clearance, '--g', sprintf('Avg: %.2f cm', avg_clearance), 'LineWidth', 1.5);
    
    % Highlight bottlenecks (clearance < 2 cm)
    bottleneck_threshold = 2.0;
    bottleneck_idx = find(clearance_profile < bottleneck_threshold);
    if ~isempty(bottleneck_idx)
        scatter(path_progress(bottleneck_idx), clearance_profile(bottleneck_idx), ...
            30, 'r', 'filled', 'DisplayName', 'Bottlenecks');
    end
    
    xlabel('Path Progress (%)', 'FontSize', 11);
    ylabel('Clearance (cm)', 'FontSize', 11);
    title('Clearance Profile Along Path', 'FontSize', 11, 'FontWeight', 'bold');
    grid on;
    legend('Location', 'best');
    
    % SUBPLOT 5: Difficulty metrics summary (if available)
    subplot(2, 3, 6);
    
    if has_rehab_metrics
        % Bar chart of normalized metrics
        metric_names = {'Steering', 'Rotation', 'Gate Rot', 'Y Rev', 'Inflections'};
        metric_values = [
            min(rehab_metrics.SteeringIndex / 50, 1), ...
            min(rehab_metrics.TotalRotation / 720, 1), ...
            min(rehab_metrics.GateRotation / 180, 1), ...
            min(rehab_metrics.Y_Reversals / 5, 1), ...
            min(rehab_metrics.InflectionCounts / 10, 1)
        ] * 100;  % Convert to percentage
        
        bar(metric_values, 'FaceColor', [0.8 0.4 0.2]);
        set(gca, 'XTickLabel', metric_names);
        xtickangle(45);
        ylabel('Normalized Difficulty (%)', 'FontSize', 11);
        title('Normalized Difficulty Metrics', 'FontSize', 11, 'FontWeight', 'bold');
        ylim([0, 100]);
        grid on;
        
        % Add value labels
        for i = 1:length(metric_values)
            text(i, metric_values(i), sprintf('%.0f%%', metric_values(i)), ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 9);
        end
    else
        axis off;
        text(0.5, 0.5, 'Rehab metrics not available', ...
            'HorizontalAlignment', 'center', 'FontSize', 12);
    end
    
    % Save figure if requested
    if save_fig
        if isempty(output_dir)
            output_dir = fileparts(game_path);
        end
        
        if ~exist(output_dir, 'dir')
            mkdir(output_dir);
        end
        
        fig_name = fullfile(output_dir, [game_name '_metrics.png']);
        saveas(fig, fig_name);
        fprintf('Figure saved: %s\n', fig_name);
    end
end

function pair_distances = calculate_pair_distances(obstacles, num_pairs)
    % Calculate distance between each obstacle pair
    pair_distances = zeros(num_pairs, 1);
    for i = 1:num_pairs
        idx1 = 2*i - 1;
        idx2 = 2*i;
        if idx2 <= size(obstacles, 1)
            pair_distances(i) = norm(obstacles(idx2, :) - obstacles(idx1, :));
        end
    end
end

function [min_clearance, avg_clearance, clearance_profile] = calculate_clearance_profile(path, obstacles, obstacle_radii)
    % Calculate clearance at each point along the path
    clearance_profile = zeros(size(path, 1), 1);
    
    for i = 1:size(path, 1)
        % Distance from path point to each obstacle center
        obstacle_dists = sqrt(sum((obstacles - path(i,:)).^2, 2));
        % Subtract radii to get clearance
        clearances = obstacle_dists - obstacle_radii;
        % Minimum clearance at this point
        clearance_profile(i) = min(clearances);
    end
    
    min_clearance = min(clearance_profile);
    avg_clearance = mean(clearance_profile);
end

function [curvature_factor, straight_distance] = calculate_path_curvature(path, X_s, X_e, data)
    % Calculate path curvature
    path_length = sum(sqrt(sum(diff(path).^2, 2)));
    
    % Try segmented distance if available
    if isfield(data, 'Start_points') && isfield(data, 'End_points') && ...
       ~isempty(data.Start_points) && ~isempty(data.End_points)
        Start_points = data.Start_points;
        End_points = data.End_points;
        
        segmented_straight_distance = 0;
        for i = 1:size(Start_points, 1)
            segmented_straight_distance = segmented_straight_distance + ...
                norm(End_points(i, :) - Start_points(i, :));
        end
        straight_distance = segmented_straight_distance;
    else
        % Fallback to direct distance
        straight_distance = norm(X_e - X_s);
    end
    
    curvature_factor = (path_length - straight_distance) / straight_distance;
end


