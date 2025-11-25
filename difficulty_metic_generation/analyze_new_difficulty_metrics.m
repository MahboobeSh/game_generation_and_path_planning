function analyze_new_difficulty_metrics(set_numbers, pairs_numbers)
    % Analyze games with new difficulty metrics (v2)
    % Shows detailed breakdown of direction changes, slopes, and positioning
    %
    % Usage:
    %   analyze_new_difficulty_metrics([2, 9, 7, 6], [4, 3, 3, 3])
    %   analyze_new_difficulty_metrics([1, 2, 3], [3, 3, 3])
    
    if nargin < 2
        % Default: compare some games
        set_numbers = [2, 9, 7, 6];
        pairs_numbers = [4, 3, 3, 3];
    end
    
    if length(set_numbers) ~= length(pairs_numbers)
        error('set_numbers and pairs_numbers must have the same length');
    end
    
    base_path = '/home/mahboobe/Desktop/game_generation_and_path_planning/game';
    
    fprintf('\n========================================\n');
    fprintf('ENHANCED DIFFICULTY ANALYSIS (v2)\n');
    fprintf('========================================\n');
    
    % Load games and calculate metrics
    games_data = struct();
    games_data.metrics = {};
    games_data.names = {};
    games_data.data = {};
    games_data.path = {};
    
    for i = 1:length(set_numbers)
        set_num = set_numbers(i);
        num_pairs = pairs_numbers(i);
        
        folder_path = fullfile(base_path, sprintf('%dpairs', num_pairs), 'fit');
        file_name = sprintf('set_%d_%dpairs.mat', set_num, num_pairs);
        file_path = fullfile(folder_path, file_name);
        
        if ~exist(file_path, 'file')
            fprintf('Warning: %s not found, skipping\n', file_path);
            continue;
        end
        
        data = load(file_path);
        
        % Select path (prefer curve)
        if isfield(data, 'curve') && ~isempty(data.curve)
            path_to_use = data.curve;
        elseif isfield(data, 'path') && ~isempty(data.path)
            path_to_use = data.path;
        else
            fprintf('Warning: %s has no path, skipping\n', file_name);
            continue;
        end
        
        % Calculate enhanced metrics
        if isfield(data, 'Start_points') && isfield(data, 'End_points')
            metrics = calculate_game_difficulty_v2(path_to_use, data.obstacle, ...
                data.obstacle_radious, data.X_s, data.X_e, ...
                data.x_range, data.y_range, num_pairs, data.Start_points, data.End_points);
        else
            metrics = calculate_game_difficulty_v2(path_to_use, data.obstacle, ...
                data.obstacle_radious, data.X_s, data.X_e, ...
                data.x_range, data.y_range, num_pairs);
        end
        
        games_data.metrics{end+1} = metrics;
        games_data.names{end+1} = sprintf('Set %d (%dp)', set_num, num_pairs);
        games_data.data{end+1} = data;
        games_data.path{end+1} = path_to_use;
    end
    
    num_games = length(games_data.metrics);
    if num_games == 0
        error('No games loaded successfully');
    end
    
    % Print detailed metrics for each game
    for i = 1:num_games
        print_detailed_metrics(games_data.names{i}, games_data.metrics{i});
    end
    
    % Create visualization
    create_enhanced_visualization(games_data);
    
    fprintf('\n========================================\n');
    fprintf('Analysis complete!\n');
    fprintf('========================================\n');
end

function print_detailed_metrics(name, m)
    % Print detailed metrics for a game
    
    fprintf('\n----------------------------------------\n');
    fprintf('%s\n', name);
    fprintf('----------------------------------------\n');
    
    fprintf('\n=== OVERALL ===\n');
    fprintf('Difficulty Score:    %.4f (%s)\n', m.overall_difficulty, m.difficulty_category);
    
    fprintf('\n=== PATH METRICS ===\n');
    fprintf('Path Length:         %.2f cm\n', m.path_length);
    fprintf('Straight Distance:   %.2f cm\n', m.straight_line_distance);
    fprintf('Path Length Factor:  %.4f\n', m.path_length_factor);
    fprintf('Curvature (Orig):    %.4f\n', m.curvature_factor_original);
    fprintf('Curvature (Seg):     %.4f\n', m.curvature_factor_segmented);
    
    fprintf('\n=== DIRECTION CHANGES (NEW) ===\n');
    fprintf('Total Angular Change: %.1f deg\n', m.total_angular_change_deg);
    fprintf('Max Turn Angle:       %.1f deg\n', m.max_turn_angle_deg);
    fprintf('Avg Turn Angle:       %.1f deg\n', m.avg_turn_angle_deg);
    fprintf('Sharp Turns (>45°):   %d\n', m.num_sharp_turns);
    fprintf('Very Sharp (>90°):    %d\n', m.num_very_sharp_turns);
    fprintf('Turn Rate:            %.4f rad/cm\n', m.turn_rate);
    
    fprintf('\n=== PATH SHAPE (NEW) ===\n');
    fprintf('X Reversals:         %d\n', m.direction_reversals_x);
    fprintf('Y Reversals:         %d\n', m.direction_reversals_y);
    fprintf('Slope Variance:      %.4f\n', m.slope_variance);
    fprintf('Path Waviness:       %.4f\n', m.path_waviness);
    
    fprintf('\n=== CLEARANCE ===\n');
    fprintf('Min Clearance:       %.2f cm\n', m.min_clearance);
    fprintf('Avg Distance:        %.2f cm\n', m.avg_obstacle_distance);
    fprintf('Bottleneck Count:    %d\n', m.bottleneck_count);
    
    fprintf('\n=== POSITIONING (NEW) ===\n');
    fprintf('Vertical Spread:     %.4f (0-1)\n', m.vertical_spread);
    fprintf('Horizontal Coverage: %.4f (0-1)\n', m.horizontal_coverage);
    fprintf('Alignment Score:     %.4f (0-1)\n', m.obstacle_alignment_score);
    fprintf('Position Difficulty: %.4f (0-1)\n', m.position_difficulty);
    
    fprintf('\n=== OBSTACLE PAIRS ===\n');
    fprintf('Min Pair Distance:   %.2f cm\n', m.min_pair_distance);
    fprintf('Avg Pair Distance:   %.2f cm\n', m.avg_pair_distance);
    fprintf('Num Segments:        %d\n', m.num_segments);
end

function create_enhanced_visualization(games_data)
    % Create visualization with new metrics
    
    num_games = length(games_data.metrics);
    
    figure('Name', 'Enhanced Difficulty Analysis (v2)', 'Position', [50 50 1400 900]);
    
    % Row 1: Game layouts
    for i = 1:num_games
        subplot(4, num_games, i);
        data = games_data.data{i};
        path = games_data.path{i};
        m = games_data.metrics{i};
        
        hold on;
        
        % Draw obstacles
        for j = 1:size(data.obstacle, 1)
            viscircles(data.obstacle(j, :), data.obstacle_radious(j), ...
                'Color', [0.3 0.3 0.3], 'LineWidth', 1.5);
        end
        
        % Draw path
        plot(path(:, 1), path(:, 2), 'b-', 'LineWidth', 2);
        
        % Draw start and end
        plot(data.X_s(1), data.X_s(2), 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g');
        plot(data.X_e(1), data.X_e(2), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
        
        hold off;
        
        title(sprintf('%s\nDiff: %.3f (%s)', games_data.names{i}, ...
            m.overall_difficulty, m.difficulty_category), 'FontSize', 9);
        xlabel('X (cm)');
        ylabel('Y (cm)');
        axis equal;
        grid on;
        xlim([0 data.x_range]);
        ylim([0 data.y_range]);
    end
    
    % Row 2: Direction Change Metrics Comparison
    subplot(4, num_games, num_games+1:2*num_games);
    
    direction_metrics = zeros(6, num_games);
    direction_labels = {'Total Ang (°/100)', 'Max Turn (°/100)', 'Avg Turn (°/100)', ...
                        'Sharp Turns', 'Turn Rate×10', 'Reversals'};
    
    for i = 1:num_games
        m = games_data.metrics{i};
        direction_metrics(1, i) = m.total_angular_change_deg / 100;
        direction_metrics(2, i) = m.max_turn_angle_deg / 100;
        direction_metrics(3, i) = m.avg_turn_angle_deg / 100;
        direction_metrics(4, i) = m.num_sharp_turns;
        direction_metrics(5, i) = m.turn_rate * 10;
        direction_metrics(6, i) = m.direction_reversals_x + m.direction_reversals_y;
    end
    
    bar(direction_metrics');
    legend(direction_labels, 'Location', 'eastoutside', 'FontSize', 8);
    set(gca, 'XTickLabel', games_data.names);
    ylabel('Value');
    title('Direction Change Metrics', 'FontSize', 11);
    grid on;
    
    % Row 3: Path Shape and Positioning Metrics
    subplot(4, num_games, 2*num_games+1:3*num_games);
    
    shape_metrics = zeros(6, num_games);
    shape_labels = {'Slope Var', 'Waviness', 'Vert Spread', 'Horiz Cover', 'Alignment', 'Pos Diff'};
    
    for i = 1:num_games
        m = games_data.metrics{i};
        shape_metrics(1, i) = min(m.slope_variance, 2);  % Cap for display
        shape_metrics(2, i) = min(m.path_waviness, 5);   % Cap for display
        shape_metrics(3, i) = m.vertical_spread;
        shape_metrics(4, i) = m.horizontal_coverage;
        shape_metrics(5, i) = m.obstacle_alignment_score;
        shape_metrics(6, i) = m.position_difficulty;
    end
    
    bar(shape_metrics');
    legend(shape_labels, 'Location', 'eastoutside', 'FontSize', 8);
    set(gca, 'XTickLabel', games_data.names);
    ylabel('Value');
    title('Path Shape & Positioning Metrics', 'FontSize', 11);
    grid on;
    
    % Row 4: Overall comparison and breakdown
    subplot(4, num_games, 3*num_games+1:3*num_games+floor(num_games/2)+1);
    
    % Stacked bar showing contribution of each category
    category_contributions = zeros(5, num_games);
    category_names = {'Path Complexity', 'Direction Changes', 'Clearance', 'Positioning', 'Other'};
    
    for i = 1:num_games
        m = games_data.metrics{i};
        n = m.normalized;
        w = m.weights;
        
        % Path complexity contribution
        category_contributions(1, i) = w.path_length * n.path_length + ...
            w.curvature * n.curvature + w.slope_variance * n.slope_variance + ...
            w.waviness * n.waviness;
        
        % Direction changes contribution
        category_contributions(2, i) = w.total_angular * n.total_angular + ...
            w.max_turn * n.max_turn + w.sharp_turns * n.sharp_turns + ...
            w.reversals * n.reversals;
        
        % Clearance contribution
        category_contributions(3, i) = w.clearance * n.clearance + ...
            w.avg_distance * n.avg_distance + w.bottlenecks * n.bottlenecks;
        
        % Positioning contribution
        category_contributions(4, i) = w.horizontal_coverage * n.horizontal_coverage + ...
            w.alignment * n.alignment + w.position_diff * n.position_diff;
        
        % Other contribution
        category_contributions(5, i) = w.pair_distance * n.pair_distance + ...
            w.constraint * n.constraint + w.density * n.density;
    end
    
    bar(category_contributions', 'stacked');
    legend(category_names, 'Location', 'eastoutside', 'FontSize', 8);
    set(gca, 'XTickLabel', games_data.names);
    ylabel('Difficulty Contribution');
    title('Difficulty Breakdown by Category', 'FontSize', 11);
    grid on;
    
    % Detailed metrics table
    subplot(4, num_games, 3*num_games+floor(num_games/2)+2:4*num_games);
    axis off;
    
    % Create table data
    row_labels = {
        'Overall Difficulty';
        'Category';
        '--- Direction ---';
        'Total Angular (°)';
        'Max Turn (°)';
        'Sharp Turns';
        '--- Shape ---';
        'Slope Variance';
        'Waviness';
        '--- Clearance ---';
        'Min Clearance';
        'Bottlenecks';
        '--- Position ---';
        'Horiz Coverage';
        'Alignment';
    };
    
    col_labels = games_data.names;
    table_data = cell(length(row_labels), num_games);
    
    for i = 1:num_games
        m = games_data.metrics{i};
        row = 1;
        table_data{row, i} = sprintf('%.4f', m.overall_difficulty); row = row + 1;
        table_data{row, i} = m.difficulty_category; row = row + 1;
        table_data{row, i} = ''; row = row + 1;
        table_data{row, i} = sprintf('%.1f', m.total_angular_change_deg); row = row + 1;
        table_data{row, i} = sprintf('%.1f', m.max_turn_angle_deg); row = row + 1;
        table_data{row, i} = sprintf('%d', m.num_sharp_turns); row = row + 1;
        table_data{row, i} = ''; row = row + 1;
        table_data{row, i} = sprintf('%.2f', m.slope_variance); row = row + 1;
        table_data{row, i} = sprintf('%.2f', m.path_waviness); row = row + 1;
        table_data{row, i} = ''; row = row + 1;
        table_data{row, i} = sprintf('%.2f', m.min_clearance); row = row + 1;
        table_data{row, i} = sprintf('%d', m.bottleneck_count); row = row + 1;
        table_data{row, i} = ''; row = row + 1;
        table_data{row, i} = sprintf('%.2f', m.horizontal_coverage); row = row + 1;
        table_data{row, i} = sprintf('%.2f', m.obstacle_alignment_score);
    end
    
    % Create uitable
    col_widths = repmat({'auto'}, 1, num_games);
    t = uitable('Data', table_data, ...
        'ColumnName', col_labels, ...
        'RowName', row_labels, ...
        'Units', 'normalized', ...
        'Position', [0.52 0.02 0.46 0.22], ...
        'FontSize', 9);
    t.ColumnWidth = 'auto';
    
    sgtitle('Enhanced Difficulty Analysis with Direction Change & Positioning Metrics', 'FontSize', 13);
end

