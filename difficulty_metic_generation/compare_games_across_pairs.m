function compare_games_across_pairs(set_numbers, pairs_numbers)
    % COMPARE_GAMES_ACROSS_PAIRS - Compare games across different pair numbers
    %
    % This function allows comparing games from different pair numbers (2, 3, 4)
    % with adjusted difficulty metrics that account for the inherent difficulty
    % of having more obstacle pairs.
    %
    % Usage:
    %   compare_games_across_pairs([9, 6], [3, 3])  % Compare set 9 and 6, both 3 pairs
    %   compare_games_across_pairs([1, 9], [2, 3])  % Compare set 1 (2 pairs) vs set 9 (3 pairs)
    %   compare_games_across_pairs([1, 9, 10], [2, 3, 4])  % Compare across all pair numbers
    %
    % Inputs:
    %   set_numbers - array of set numbers to compare
    %   pairs_numbers - array of pair numbers corresponding to each set
    
    if length(set_numbers) ~= length(pairs_numbers)
        error('set_numbers and pairs_numbers must have the same length');
    end
    
    base_folder = '/home/mahboobe/Desktop/game_generation_and_path_planning/game/';
    
    fprintf('=== Comparing Games Across Different Pair Numbers ===\n\n');
    
    % Load and analyze each game
    games_data = struct();
    games_data.set_number = [];
    games_data.pairs_number = [];
    games_data.file_path = {};
    games_data.data = {};
    games_data.metrics = {};
    games_data.path_type = {};
    games_data.adjusted_difficulty = [];
    games_data.adjusted_category = {};
    
    for i = 1:length(set_numbers)
        set_num = set_numbers(i);
        pairs_num = pairs_numbers(i);
        
        folder_path = fullfile(base_folder, sprintf('%dpairs/fit', pairs_num));
        filename = sprintf('set_%d_%dpairs.mat', set_num, pairs_num);
        file_path = fullfile(folder_path, filename);
        
        if ~exist(file_path, 'file')
            fprintf('Warning: File not found: %s\n', filename);
            continue;
        end
        
        fprintf('Loading %s...\n', filename);
        data = load(file_path);
        
        % Select path - prefer curve
        if isfield(data, 'curve') && ~isempty(data.curve)
            path_to_use = data.curve;
            path_type = 'Bezier Curve';
        elseif isfield(data, 'path') && ~isempty(data.path)
            path_to_use = data.path;
            path_type = 'A* Path';
        else
            fprintf('  Warning: No path or curve found, skipping\n');
            continue;
        end
        
        fprintf('  Using: %s\n', path_type);
        
        % Calculate difficulty metrics
        if isfield(data, 'number_of_pairs')
            num_pairs = data.number_of_pairs;
        else
            num_pairs = pairs_num;
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
        
        % Calculate adjusted difficulty that accounts for number of pairs
        [adjusted_difficulty, adjusted_category] = calculate_adjusted_difficulty(metrics, num_pairs);
        
        games_data.set_number(end+1) = set_num;
        games_data.pairs_number(end+1) = pairs_num;
        games_data.file_path{end+1} = file_path;
        games_data.data{end+1} = data;
        games_data.metrics{end+1} = metrics;
        games_data.path_type{end+1} = path_type;
        games_data.adjusted_difficulty(end+1) = adjusted_difficulty;
        games_data.adjusted_category{end+1} = adjusted_category;
        
        % Display metrics
        fprintf('\n--- Set %d, %d pairs (%s) ---\n', set_num, pairs_num, path_type);
        fprintf('Overall Difficulty:     %.4f (%s)\n', ...
            metrics.overall_difficulty, metrics.difficulty_category);
        fprintf('Adjusted Difficulty:     %.4f\n', adjusted_difficulty);
        fprintf('Path Length:            %.2f cm\n', metrics.path_length);
        fprintf('Min Clearance:          %.2f cm\n', metrics.min_clearance);
        fprintf('Min Pair Distance:      %.2f cm\n', metrics.min_pair_distance);
    end
    
    % Create comprehensive comparison visualization
    create_cross_pair_comparison(games_data);
    
    fprintf('\n=== Comparison Complete ===\n');
end

function [adjusted_difficulty, adjusted_category] = calculate_adjusted_difficulty(metrics, number_of_pairs)
    % Calculate adjusted difficulty that accounts for number of pairs
    % This makes comparisons across different pair numbers more fair
    %
    % Outputs:
    %   adjusted_difficulty - difficulty score adjusted for pair number
    %   adjusted_category - 'Easy', 'Medium', or 'Hard' based on adjusted difficulty
    
    % Base difficulty from the original calculation
    base_difficulty = metrics.overall_difficulty;
    
    % Pair number factor: games with more pairs are inherently harder
    % This factor scales the difficulty to account for the complexity
    % of navigating through more obstacle pairs
    pair_complexity_factor = 1.0 + (number_of_pairs - 2) * 0.15;  % 2 pairs = 1.0, 3 pairs = 1.15, 4 pairs = 1.30
    
    % Adjust for path complexity relative to number of pairs
    % More pairs should require more segments, so normalize by expected segments
    expected_segments = number_of_pairs + 1;  % Roughly one segment per pair plus one
    segment_factor = metrics.num_segments / expected_segments;
    
    % Adjust for obstacle density - more pairs means more obstacles
    % Normalize density by pair number
    density_per_pair = metrics.obstacle_density / number_of_pairs;
    density_factor = 1.0 + (density_per_pair - 0.01) * 10;  % Adjust based on density per pair
    density_factor = max(0.5, min(1.5, density_factor));  % Limit the factor
    
    % Combine adjustments
    adjusted_difficulty = base_difficulty * pair_complexity_factor * ...
                         (0.7 + 0.3 * segment_factor) * ...
                         (0.8 + 0.2 * density_factor);
    
    % Normalize to 0-1 range
    adjusted_difficulty = min(1.0, adjusted_difficulty);
    
    % Categorize based on adjusted difficulty
    if adjusted_difficulty < 0.33
        adjusted_category = 'Easy';
    elseif adjusted_difficulty < 0.67
        adjusted_category = 'Medium';
    else
        adjusted_category = 'Hard';
    end
end

function create_cross_pair_comparison(games_data)
    % Create comprehensive comparison visualization across different pair numbers
    % Uses the same style as examine_specific_games for consistency
    
    num_games = length(games_data.set_number);
    
    figure('Position', [100, 100, 1600, 1000], 'Name', 'Cross-Pair Game Comparison');
    
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
        plot(data.X_s(1), data.X_s(2), 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g');
        plot(data.X_e(1), data.X_e(2), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
        
        title(sprintf('Set %d (%d pairs)\nOrig: %.3f | Adj: %.3f (%s)', ...
            games_data.set_number(i), games_data.pairs_number(i), ...
            metrics.overall_difficulty, games_data.adjusted_difficulty(i), ...
            games_data.adjusted_category{i}));
        xlabel('X (cm)');
        ylabel('Y (cm)');
        axis equal;
        grid on;
        xlim([0 data.x_range]);
        ylim([0 data.y_range]);
    end
    
    % 2. Metrics comparison bar chart (same style as original)
    subplot(3, num_games, num_games+1:2*num_games);
    metric_names = {'Orig Diff', 'Adj Diff', 'Path Len', 'Curv Orig', 'Curv Seg', 'Clearance', ...
                    'Pair Dist', 'Tightness'};
    metric_values = zeros(length(metric_names), num_games);
    
    for i = 1:num_games
        m = games_data.metrics{i};
        metric_values(1, i) = m.overall_difficulty;  % Original difficulty
        metric_values(2, i) = games_data.adjusted_difficulty(i);  % Adjusted difficulty
        metric_values(3, i) = m.path_length_factor;
        metric_values(4, i) = m.curvature_factor_original;  % Original curvature
        metric_values(5, i) = m.curvature_factor_segmented;  % Segmented curvature
        metric_values(6, i) = m.min_clearance / 5;  % Normalize
        if isfinite(m.min_pair_distance)
            metric_values(7, i) = m.min_pair_distance / 5;  % Normalize
        else
            metric_values(7, i) = 0;
        end
        metric_values(8, i) = m.constraint_tightness;
    end
    
    x = 1:length(metric_names);
    bar_width = 0.8 / num_games;
    colors = lines(num_games);
    
    for i = 1:num_games
        offset = (i - (num_games+1)/2) * bar_width;
        bar(x + offset, metric_values(:, i), bar_width, ...
            'FaceColor', colors(i, :), ...
            'DisplayName', sprintf('Set %d (%dpairs)', games_data.set_number(i), games_data.pairs_number(i)));
        hold on;
    end
    
    set(gca, 'XTick', x, 'XTickLabel', metric_names);
    ylabel('Normalized Value');
    title('Key Metrics Comparison');
    legend('Location', 'best');
    grid on;
    
    % 3. Detailed metrics table (in same figure) - using uitable
    subplot(3, num_games, 2*num_games+1:3*num_games);
    axis off;
    
    % Prepare table data
    metric_labels = {
        'Original Difficulty';
        'Adjusted Difficulty';
        'Category';
        'Path Length (cm)';
        'Path Length Factor';
        'Curvature Factor (Orig)';
        'Curvature Factor (Seg)';
        'Num Segments';
        'Min Pair Dist (cm)';
        'Min Clearance (cm)';
        'Constraint Tightness';
    };
    
    table_data = cell(length(metric_labels), num_games);
    for i = 1:num_games
        m = games_data.metrics{i};
        table_data{1, i} = sprintf('%.4f', m.overall_difficulty);
        table_data{2, i} = sprintf('%.4f', games_data.adjusted_difficulty(i));
        table_data{3, i} = games_data.adjusted_category{i};
        table_data{4, i} = sprintf('%.2f', m.path_length);
        table_data{5, i} = sprintf('%.4f', m.path_length_factor);
        table_data{6, i} = sprintf('%.4f', m.curvature_factor_original);
        table_data{7, i} = sprintf('%.4f', m.curvature_factor_segmented);
        table_data{8, i} = sprintf('%d', m.num_segments);
        if isfinite(m.min_pair_distance)
            table_data{9, i} = sprintf('%.2f', m.min_pair_distance);
        else
            table_data{9, i} = 'N/A';
        end
        table_data{10, i} = sprintf('%.2f', m.min_clearance);
        table_data{11, i} = sprintf('%.4f', m.constraint_tightness);
    end
    
    % Create column headers
    column_names = cell(1, num_games);
    for i = 1:num_games
        column_names{i} = sprintf('Set %d (%dpairs)', games_data.set_number(i), games_data.pairs_number(i));
    end
    
    % Get current axes position for table placement
    ax = gca;
    pos = ax.Position;
    
    % Create uitable
    t = uitable('Parent', gcf, ...
                'Data', table_data, ...
                'ColumnName', column_names, ...
                'RowName', metric_labels, ...
                'Units', 'normalized', ...
                'Position', [pos(1), pos(2), pos(3), pos(4)], ...
                'FontSize', 9);
    
    % Adjust column widths - only for data columns (row names are separate)
    % Use 'auto' for automatic sizing or set specific widths
    t.ColumnWidth = repmat({'auto'}, 1, num_games);
    
    sgtitle('Cross-Pair Game Comparison (Adjusted for Pair Number Complexity)', ...
        'FontSize', 14, 'FontWeight', 'bold');
end

