function examine_specific_games(set_numbers, pairs_number, use_curve)
    % EXAMINE_SPECIFIC_GAMES - Examine and compare specific games
    %
    % Usage:
    %   examine_specific_games([9, 6], 3)  % Compare set 9 and set 6, 3 pairs (uses Bezier curve)
    %   examine_specific_games(9, 3)       % Examine only set 9, 3 pairs (uses Bezier curve)
    %   examine_specific_games([9, 6], 3, false)  % Use A* path instead of Bezier curve
    %
    % Inputs:
    %   set_numbers - array of set numbers to examine (e.g., [9, 6])
    %   pairs_number - number of pairs (2, 3, or 4)
    %   use_curve - optional, if true uses Bezier curve, if false uses A* path (default: true)
    
    if nargin < 2
        error('Usage: examine_specific_games(set_numbers, pairs_number, [use_curve])');
    end
    
    if nargin < 3
        use_curve = true;  % Default to Bezier curve
    end
    
    if ~isscalar(set_numbers)
        set_numbers = set_numbers(:)';  % Ensure row vector
    else
        set_numbers = [set_numbers];  % Convert to array
    end
    
    base_folder = '/home/mahboobe/Desktop/game_generation_and_path_planning/game/';
    folder_path = fullfile(base_folder, sprintf('%dpairs/fit', pairs_number));
    
    fprintf('=== Examining Games: Sets %s, %d pairs ===\n\n', ...
        mat2str(set_numbers), pairs_number);
    
    % Load and analyze each game
    games_data = struct();
    games_data.set_number = [];
    games_data.file_path = {};
    games_data.data = {};
    games_data.metrics = {};  % Use cell array for metrics
    games_data.path_type = {};  % Track which path type is used
    
    for i = 1:length(set_numbers)
        set_num = set_numbers(i);
        filename = sprintf('set_%d_%dpairs.mat', set_num, pairs_number);
        file_path = fullfile(folder_path, filename);
        
        if ~exist(file_path, 'file')
            fprintf('Warning: File not found: %s\n', filename);
            continue;
        end
        
        fprintf('Loading %s...\n', filename);
        data = load(file_path);
        
        % Select which path to use
        if use_curve && isfield(data, 'curve') && ~isempty(data.curve)
            path_to_use = data.curve;
            path_type = 'Bezier Curve';
        else
            path_to_use = data.path;
            path_type = 'A* Path';
        end
        
        fprintf('  Using: %s\n', path_type);
        
        % Calculate difficulty metrics
        if isfield(data, 'number_of_pairs')
            num_pairs = data.number_of_pairs;
        else
            num_pairs = pairs_number;
        end
        
        % Pass Start_points and End_points if available for better curvature calculation
        if isfield(data, 'Start_points') && isfield(data, 'End_points')
            metrics = calculate_game_difficulty(path_to_use, data.obstacle, ...
                data.obstacle_radious, data.X_s, data.X_e, ...
                data.x_range, data.y_range, num_pairs, data.Start_points, data.End_points);
        else
            metrics = calculate_game_difficulty(path_to_use, data.obstacle, ...
                data.obstacle_radious, data.X_s, data.X_e, ...
                data.x_range, data.y_range, num_pairs);
        end
        
        games_data.set_number(end+1) = set_num;
        games_data.file_path{end+1} = file_path;
        games_data.data{end+1} = data;
        games_data.metrics{end+1} = metrics;
        games_data.path_type{end+1} = path_type;
        
        % Display metrics
        fprintf('\n--- Set %d, %d pairs (%s) ---\n', set_num, pairs_number, path_type);
        display_game_metrics(metrics);
    end
    
    % Create comparison visualization if multiple games
    if length(set_numbers) > 1
        create_comparison_visualization(games_data);
    else
        create_single_game_visualization(games_data);
    end
    
    fprintf('\n=== Analysis Complete ===\n');
end

function display_game_metrics(metrics)
    % Display metrics for a single game
    
    fprintf('\n--- Overall ---\n');
    fprintf('Overall Difficulty:     %.4f (%s)\n', ...
        metrics.overall_difficulty, metrics.difficulty_category);
    
    fprintf('\n--- Path Metrics ---\n');
    fprintf('Path Length:            %.2f cm\n', metrics.path_length);
    fprintf('Straight Line Distance:  %.2f cm\n', metrics.straight_line_distance);
    fprintf('Path Length Factor:     %.4f\n', metrics.path_length_factor);
    fprintf('Curvature Factor (Orig): %.4f\n', metrics.curvature_factor_original);
    fprintf('Curvature Factor (Seg):  %.4f\n', metrics.curvature_factor_segmented);
    fprintf('Number of Segments:     %d\n', metrics.num_segments);
    
    fprintf('\n--- Obstacle Pairs ---\n');
    if isfinite(metrics.min_pair_distance)
        fprintf('Min Pair Distance:      %.2f cm\n', metrics.min_pair_distance);
    else
        fprintf('Min Pair Distance:      N/A\n');
    end
    if isfinite(metrics.avg_pair_distance)
        fprintf('Avg Pair Distance:      %.2f cm\n', metrics.avg_pair_distance);
    else
        fprintf('Avg Pair Distance:      N/A\n');
    end
    if isfinite(metrics.min_inter_pair_distance)
        fprintf('Min Inter-Pair Dist:    %.2f cm\n', metrics.min_inter_pair_distance);
    else
        fprintf('Min Inter-Pair Dist:    N/A\n');
    end
    
    fprintf('\n--- Clearance & Distance ---\n');
    fprintf('Min Clearance:           %.2f cm\n', metrics.min_clearance);
    fprintf('Avg Obstacle Distance:  %.2f cm\n', metrics.avg_obstacle_distance);
    if isfinite(metrics.min_start_distance)
        fprintf('Min Start Distance:      %.2f cm\n', metrics.min_start_distance);
    else
        fprintf('Min Start Distance:      N/A\n');
    end
    if isfinite(metrics.min_end_distance)
        fprintf('Min End Distance:        %.2f cm\n', metrics.min_end_distance);
    else
        fprintf('Min End Distance:        N/A\n');
    end
    
    fprintf('\n--- Obstacle Properties ---\n');
    fprintf('Avg Obstacle Size:      %.2f cm\n', metrics.avg_obstacle_size);
    fprintf('Obstacle Density:       %.4f\n', metrics.obstacle_density);
    
    fprintf('\n--- Constraint Tightness ---\n');
    fprintf('Overall Tightness:      %.4f\n', metrics.constraint_tightness);
    fprintf('Pair Tightness:         %.4f\n', metrics.pair_tightness);
    fprintf('Inter-Pair Tightness:   %.4f\n', metrics.inter_pair_tightness);
end

function create_comparison_visualization(games_data)
    % Create comparison visualization for multiple games
    
    num_games = length(games_data.set_number);
    
    figure('Position', [100, 100, 1600, 1000], 'Name', 'Game Comparison');
    
    % 1. Side-by-side game layouts
    for i = 1:num_games
        subplot(3, num_games, i);
        data = games_data.data{i};
        metrics = games_data.metrics{i};
        
        % Select path to plot
        if strcmp(games_data.path_type{i}, 'Bezier Curve') && isfield(data, 'curve') && ~isempty(data.curve)
            path_to_plot = data.curve;
        else
            path_to_plot = data.path;
        end
        
        % Plot obstacles
        hold on;
        for j = 1:size(data.obstacle, 1)
            viscircles(data.obstacle(j, :), data.obstacle_radious(j), ...
                'EdgeColor', 'k', 'LineWidth', 1.5);
        end
        
        % Plot path
        plot(path_to_plot(:, 1), path_to_plot(:, 2), 'b-', 'LineWidth', 2);
        
        % Plot start and end
        plot(data.X_s(1), data.X_s(2), 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g');
        plot(data.X_e(1), data.X_e(2), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
        
        title(sprintf('Set %d (%s)\nDifficulty: %.3f (%s)', ...
            games_data.set_number(i), games_data.path_type{i}, ...
            metrics.overall_difficulty, metrics.difficulty_category));
        xlabel('X (cm)');
        ylabel('Y (cm)');
        axis equal;
        grid on;
        xlim([0 data.x_range]);
        ylim([0 data.y_range]);
    end
    
    % 2. Metrics comparison bar chart
    subplot(3, num_games, num_games+1:2*num_games);
    metric_names = {'Overall', 'Path Len', 'Curv Orig', 'Curv Seg', 'Clearance', ...
                    'Pair Dist', 'Tightness'};
    metric_values = zeros(length(metric_names), num_games);
    
    for i = 1:num_games
        m = games_data.metrics{i};
        metric_values(1, i) = m.overall_difficulty;
        metric_values(2, i) = m.path_length_factor;
        metric_values(3, i) = m.curvature_factor_original;  % Original curvature
        metric_values(4, i) = m.curvature_factor_segmented;  % Segmented curvature
        metric_values(5, i) = m.min_clearance / 5;  % Normalize
        if isfinite(m.min_pair_distance)
            metric_values(6, i) = m.min_pair_distance / 5;  % Normalize
        else
            metric_values(6, i) = 0;
        end
        metric_values(7, i) = m.constraint_tightness;
    end
    
    x = 1:length(metric_names);
    bar_width = 0.8 / num_games;
    colors = lines(num_games);
    
    for i = 1:num_games
        offset = (i - (num_games+1)/2) * bar_width;
        bar(x + offset, metric_values(:, i), bar_width, ...
            'FaceColor', colors(i, :), ...
            'DisplayName', sprintf('Set %d', games_data.set_number(i)));
        hold on;
    end
    
    set(gca, 'XTick', x, 'XTickLabel', metric_names);
    ylabel('Normalized Value');
    title('Key Metrics Comparison');
    legend('Location', 'best');
    grid on;
    
    % 3. Detailed metrics table (expanded)
    subplot(3, num_games, 2*num_games+1:3*num_games);
    axis off;
    
    % Create comprehensive table text
    table_text = cell(25, num_games + 1);
    table_text{1, 1} = 'Metric';
    for i = 1:num_games
        table_text{1, i+1} = sprintf('Set %d', games_data.set_number(i));
    end
    
    row = 2;
    table_text{row, 1} = '=== OVERALL ===';
    for i = 1:num_games
        table_text{row, i+1} = '';
    end
    
    row = row + 1;
    table_text{row, 1} = 'Overall Difficulty';
    for i = 1:num_games
        table_text{row, i+1} = sprintf('%.4f', games_data.metrics{i}.overall_difficulty);
    end
    
    row = row + 1;
    table_text{row, 1} = 'Category';
    for i = 1:num_games
        table_text{row, i+1} = games_data.metrics{i}.difficulty_category;
    end
    
    row = row + 1;
    table_text{row, 1} = '=== PATH METRICS ===';
    for i = 1:num_games
        table_text{row, i+1} = '';
    end
    
    row = row + 1;
    table_text{row, 1} = 'Path Length (cm)';
    for i = 1:num_games
        table_text{row, i+1} = sprintf('%.2f', games_data.metrics{i}.path_length);
    end
    
    row = row + 1;
    table_text{row, 1} = 'Straight Line Dist (cm)';
    for i = 1:num_games
        table_text{row, i+1} = sprintf('%.2f', games_data.metrics{i}.straight_line_distance);
    end
    
    row = row + 1;
    table_text{row, 1} = 'Path Length Factor';
    for i = 1:num_games
        table_text{row, i+1} = sprintf('%.4f', games_data.metrics{i}.path_length_factor);
    end
    
    row = row + 1;
    table_text{row, 1} = 'Curvature Factor (Orig)';
    for i = 1:num_games
        table_text{row, i+1} = sprintf('%.4f', games_data.metrics{i}.curvature_factor_original);
    end
    
    row = row + 1;
    table_text{row, 1} = 'Curvature Factor (Seg)';
    for i = 1:num_games
        table_text{row, i+1} = sprintf('%.4f', games_data.metrics{i}.curvature_factor_segmented);
    end
    
    row = row + 1;
    table_text{row, 1} = 'Num Segments';
    for i = 1:num_games
        table_text{row, i+1} = sprintf('%d', games_data.metrics{i}.num_segments);
    end
    
    row = row + 1;
    table_text{row, 1} = '=== OBSTACLE PAIRS ===';
    for i = 1:num_games
        table_text{row, i+1} = '';
    end
    
    row = row + 1;
    table_text{row, 1} = 'Min Pair Distance (cm)';
    for i = 1:num_games
        if isfinite(games_data.metrics{i}.min_pair_distance)
            table_text{row, i+1} = sprintf('%.2f', games_data.metrics{i}.min_pair_distance);
        else
            table_text{row, i+1} = 'N/A';
        end
    end
    
    row = row + 1;
    table_text{row, 1} = 'Avg Pair Distance (cm)';
    for i = 1:num_games
        if isfinite(games_data.metrics{i}.avg_pair_distance)
            table_text{row, i+1} = sprintf('%.2f', games_data.metrics{i}.avg_pair_distance);
        else
            table_text{row, i+1} = 'N/A';
        end
    end
    
    row = row + 1;
    table_text{row, 1} = 'Min Inter-Pair Dist (cm)';
    for i = 1:num_games
        if isfinite(games_data.metrics{i}.min_inter_pair_distance)
            table_text{row, i+1} = sprintf('%.2f', games_data.metrics{i}.min_inter_pair_distance);
        else
            table_text{row, i+1} = 'N/A';
        end
    end
    
    row = row + 1;
    table_text{row, 1} = '=== CLEARANCE & DISTANCE ===';
    for i = 1:num_games
        table_text{row, i+1} = '';
    end
    
    row = row + 1;
    table_text{row, 1} = 'Min Clearance (cm)';
    for i = 1:num_games
        table_text{row, i+1} = sprintf('%.2f', games_data.metrics{i}.min_clearance);
    end
    
    row = row + 1;
    table_text{row, 1} = 'Avg Obstacle Distance (cm)';
    for i = 1:num_games
        table_text{row, i+1} = sprintf('%.2f', games_data.metrics{i}.avg_obstacle_distance);
    end
    
    row = row + 1;
    table_text{row, 1} = 'Min Start Distance (cm)';
    for i = 1:num_games
        if isfinite(games_data.metrics{i}.min_start_distance)
            table_text{row, i+1} = sprintf('%.2f', games_data.metrics{i}.min_start_distance);
        else
            table_text{row, i+1} = 'N/A';
        end
    end
    
    row = row + 1;
    table_text{row, 1} = 'Min End Distance (cm)';
    for i = 1:num_games
        if isfinite(games_data.metrics{i}.min_end_distance)
            table_text{row, i+1} = sprintf('%.2f', games_data.metrics{i}.min_end_distance);
        else
            table_text{row, i+1} = 'N/A';
        end
    end
    
    row = row + 1;
    table_text{row, 1} = '=== OBSTACLE PROPERTIES ===';
    for i = 1:num_games
        table_text{row, i+1} = '';
    end
    
    row = row + 1;
    table_text{row, 1} = 'Avg Obstacle Size (cm)';
    for i = 1:num_games
        table_text{row, i+1} = sprintf('%.2f', games_data.metrics{i}.avg_obstacle_size);
    end
    
    row = row + 1;
    table_text{row, 1} = 'Obstacle Density';
    for i = 1:num_games
        table_text{row, i+1} = sprintf('%.4f', games_data.metrics{i}.obstacle_density);
    end
    
    row = row + 1;
    table_text{row, 1} = '=== CONSTRAINT TIGHTNESS ===';
    for i = 1:num_games
        table_text{row, i+1} = '';
    end
    
    row = row + 1;
    table_text{row, 1} = 'Overall Tightness';
    for i = 1:num_games
        table_text{row, i+1} = sprintf('%.4f', games_data.metrics{i}.constraint_tightness);
    end
    
    row = row + 1;
    table_text{row, 1} = 'Pair Tightness';
    for i = 1:num_games
        table_text{row, i+1} = sprintf('%.4f', games_data.metrics{i}.pair_tightness);
    end
    
    row = row + 1;
    table_text{row, 1} = 'Inter-Pair Tightness';
    for i = 1:num_games
        table_text{row, i+1} = sprintf('%.4f', games_data.metrics{i}.inter_pair_tightness);
    end
    
    % Display table with smaller font to fit more
    text(0.05, 0.5, table_text, 'FontSize', 8, 'FontFamily', 'monospace', ...
         'VerticalAlignment', 'middle', 'HorizontalAlignment', 'left');
    
    % Show path type in title
    path_types = unique(games_data.path_type);
    if length(path_types) == 1
        path_type_str = path_types{1};
    else
        path_type_str = sprintf('%s/%s', path_types{1}, path_types{2});
    end
    
    sgtitle(sprintf('Comparison: Sets %s (%d pairs, %s)', ...
        mat2str(games_data.set_number), games_data.data{1}.number_of_pairs, path_type_str), ...
        'FontSize', 14, 'FontWeight', 'bold');
end

function create_single_game_visualization(games_data)
    % Create visualization for a single game
    
    data = games_data.data{1};
    metrics = games_data.metrics{1};
    set_num = games_data.set_number(1);
    path_type = games_data.path_type{1};
    
    figure('Position', [100, 100, 1200, 800], 'Name', sprintf('Set %d Analysis (%s)', set_num, path_type));
    
    % Select path to plot
    if strcmp(path_type, 'Bezier Curve') && isfield(data, 'curve') && ~isempty(data.curve)
        path_to_plot = data.curve;
    else
        path_to_plot = data.path;
    end
    
    % Game layout
    subplot(2, 2, 1);
    hold on;
    for j = 1:size(data.obstacle, 1)
        viscircles(data.obstacle(j, :), data.obstacle_radious(j), ...
            'EdgeColor', 'k', 'LineWidth', 1.5);
    end
    plot(path_to_plot(:, 1), path_to_plot(:, 2), 'b-', 'LineWidth', 2);
    plot(data.X_s(1), data.X_s(2), 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g');
    plot(data.X_e(1), data.X_e(2), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
    title(sprintf('Set %d - Difficulty: %.3f (%s)', ...
        set_num, metrics.overall_difficulty, metrics.difficulty_category));
    xlabel('X (cm)');
    ylabel('Y (cm)');
    axis equal;
    grid on;
    xlim([0 data.x_range]);
    ylim([0 data.y_range]);
    
    % Metrics bar chart
    subplot(2, 2, 2);
    metric_names = {'Overall', 'Path Len', 'Curv Orig', 'Curv Seg', 'Clearance', 'Pair Dist', 'Tightness'};
    if isfinite(metrics.min_pair_distance)
        pair_dist_norm = metrics.min_pair_distance / 5;
    else
        pair_dist_norm = 0;
    end
    metric_vals = [
        metrics.overall_difficulty;
        metrics.path_length_factor;
        metrics.curvature_factor_original;
        metrics.curvature_factor_segmented;
        metrics.min_clearance / 5;
        pair_dist_norm;
        metrics.constraint_tightness
    ];
    bar(metric_vals);
    set(gca, 'XTickLabel', metric_names);
    ylabel('Normalized Value');
    title('Key Metrics');
    grid on;
    xtickangle(45);
    
    % Path analysis
    subplot(2, 2, 3);
    path_distances = sqrt(sum(diff(path_to_plot).^2, 2));
    cumulative_distance = [0; cumsum(path_distances)];
    plot(cumulative_distance, 'b-', 'LineWidth', 2);
    xlabel('Path Point Index');
    ylabel('Cumulative Distance (cm)');
    title(sprintf('Path Length: %.2f cm (%s)', metrics.path_length, path_type));
    grid on;
    
    % Detailed metrics text
    subplot(2, 2, 4);
    axis off;
    info_text = {
        sprintf('=== Set %d, %d pairs ===', set_num, data.number_of_pairs);
        '';
        sprintf('Overall Difficulty: %.4f (%s)', metrics.overall_difficulty, metrics.difficulty_category);
        '';
        sprintf('=== PATH ===');
        sprintf('Path Length: %.2f cm', metrics.path_length);
        sprintf('Straight Distance: %.2f cm', metrics.straight_line_distance);
        sprintf('Path Factor: %.4f', metrics.path_length_factor);
        sprintf('Curvature Factor (Orig): %.4f', metrics.curvature_factor_original);
        sprintf('Curvature Factor (Seg): %.4f', metrics.curvature_factor_segmented);
        sprintf('Num Segments: %d', metrics.num_segments);
        '';
        sprintf('=== OBSTACLE PAIRS ===');
        sprintf('Min Pair Dist: %.2f cm', metrics.min_pair_distance);
        sprintf('Avg Pair Dist: %.2f cm', metrics.avg_pair_distance);
        sprintf('Min Inter-Pair: %.2f cm', metrics.min_inter_pair_distance);
        '';
        sprintf('=== CLEARANCE ===');
        sprintf('Min Clearance: %.2f cm', metrics.min_clearance);
        sprintf('Avg Obstacle Dist: %.2f cm', metrics.avg_obstacle_distance);
        sprintf('Min Start Dist: %.2f cm', metrics.min_start_distance);
        sprintf('Min End Dist: %.2f cm', metrics.min_end_distance);
        '';
        sprintf('=== OBSTACLES ===');
        sprintf('Avg Size: %.2f cm', metrics.avg_obstacle_size);
        sprintf('Density: %.4f', metrics.obstacle_density);
        '';
        sprintf('=== TIGHTNESS ===');
        sprintf('Overall: %.4f', metrics.constraint_tightness);
        sprintf('Pair: %.4f', metrics.pair_tightness);
        sprintf('Inter-Pair: %.4f', metrics.inter_pair_tightness);
    };
    text(0.1, 0.5, info_text, 'FontSize', 9, 'FontFamily', 'monospace', ...
         'VerticalAlignment', 'middle', 'HorizontalAlignment', 'left');
end

