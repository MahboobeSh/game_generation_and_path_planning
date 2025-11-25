function visualize_rehab_metrics(set_numbers, pairs_numbers)
    % Visualize rehabilitation/bio-motor difficulty metrics for games
    %
    % Usage:
    %   visualize_rehab_metrics([2, 9, 7, 6], [4, 3, 3, 3])
    %   visualize_rehab_metrics([1, 2, 3], [3, 3, 3])
    
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
    fprintf('REHABILITATION METRICS VISUALIZATION\n');
    fprintf('========================================\n');
    
    % Load games and calculate rehab metrics
    games_data = struct();
    games_data.rehab_metrics = {};
    games_data.names = {};
    games_data.data = {};
    games_data.path = {};
    games_data.path_type = {};
    
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
            path_type = 'Bezier Curve';
        elseif isfield(data, 'path') && ~isempty(data.path)
            path_to_use = data.path;
            path_type = 'A* Path';
        else
            fprintf('Warning: %s has no path, skipping\n', file_name);
            continue;
        end
        
        % Calculate rehab metrics
        % Pass num_samples_list if available, otherwise use empty array
        if isfield(data, 'num_samples_list') && ~isempty(data.num_samples_list)
            rehab_metrics = calculate_rehab_metrics(path_to_use, data.obstacle, ...
                data.obstacle_radious, data.x_range, data.y_range, data.num_samples_list);
        else
            rehab_metrics = calculate_rehab_metrics(path_to_use, data.obstacle, ...
                data.obstacle_radious, data.x_range, data.y_range, []);
        end
        
        games_data.rehab_metrics{end+1} = rehab_metrics;
        games_data.names{end+1} = sprintf('Set %d (%dp)', set_num, num_pairs);
        games_data.data{end+1} = data;
        games_data.path{end+1} = path_to_use;
        games_data.path_type{end+1} = path_type;
    end
    
    num_games = length(games_data.rehab_metrics);
    if num_games == 0
        error('No games loaded successfully');
    end
    
    % Print metrics for each game
    for i = 1:num_games
        print_rehab_metrics(games_data.names{i}, games_data.rehab_metrics{i});
    end
    
    % Create visualization
    create_rehab_visualization(games_data);
    
    fprintf('\n========================================\n');
    fprintf('Visualization complete!\n');
    fprintf('========================================\n');
end

function print_rehab_metrics(name, m)
    % Print rehab metrics for a game
    
    fprintf('\n----------------------------------------\n');
    fprintf('%s\n', name);
    fprintf('----------------------------------------\n');
    
    fprintf('Steering Index:         %.4f\n', m.SteeringIndex);
    fprintf('Inflection Counts:      %d\n', m.InflectionCounts);
    fprintf('Goal Alignment (deg):   %.4f\n', m.GoalAlignmentAvgDeg);
    fprintf('Y-Axis Reversals:       %d\n', m.Y_Reversals);
    fprintf('Verticality Ratio:      %.4f\n', m.Verticality);
    fprintf('Total Rotation (deg):   %.4f\n', m.TotalRotation);
    fprintf('Gate Rotation:          %.4f\n', m.GateRotation);
    fprintf('Composite Score:        %.4f\n', m.CompositeScore);
    fprintf('\n');
    fprintf('Composite Breakdown:\n');
    fprintf('  Steering (×1.0):      %.4f\n', m.SteeringIndex * 1.0);
    fprintf('  Goal Align (×0.5):    %.4f\n', m.GoalAlignmentAvgDeg * 0.5);
    fprintf('  Inflections (×0.5):   %.4f\n', m.InflectionCounts * 0.5);
    fprintf('  Y Reversals (×2.0):   %.4f\n', m.Y_Reversals * 2.0);
    fprintf('  Gate Rotation (×2.0): %.4f\n', m.GateRotation * 2.0);
end

function create_rehab_visualization(games_data)
    % Create visualization of rehab metrics
    
    num_games = length(games_data.rehab_metrics);
    
    figure('Name', 'Rehabilitation Metrics Visualization', 'Position', [50 50 1400 900]);
    
    % Row 1: Game layouts with path colored by difficulty (inverse clearance)
    for i = 1:num_games
        subplot(3, num_games, i);
        data = games_data.data{i};
        path = games_data.path{i};
        m = games_data.rehab_metrics{i};
        
        hold on;
        
        % Draw obstacles
        for j = 1:size(data.obstacle, 1)
            viscircles(data.obstacle(j, :), data.obstacle_radious(j), ...
                'Color', [0.3 0.3 0.3], 'LineWidth', 1.5);
        end
        
        % Calculate inverse clearance for each path point (difficulty map)
        path_pts = path;
        dists = zeros(size(path_pts, 1), 1);
        for k = 1:size(path_pts, 1)
            % Calculate distance from path point to each obstacle center
            obstacle_dists = sqrt(sum((data.obstacle - path_pts(k,:)).^2, 2));
            % Subtract obstacle radii to get clearance (gap distance)
            clearances = obstacle_dists - data.obstacle_radious(:);
            % Find minimum clearance (narrowest gap)
            d = min(clearances);
            % Inverse clearance (higher = harder/narrower)
            dists(k) = 1 ./ max(d, 0.1);
        end
        
        % Plot path with color mapped to difficulty
        scatter(path_pts(:,1), path_pts(:,2), 20, dists, 'filled');
        colormap(gca, 'jet'); % Red = Hard (narrow), Blue = Easy (wide)
        colorbar;
        
        % Draw start and end
        plot(data.X_s(1), data.X_s(2), 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
        plot(data.X_e(1), data.X_e(2), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
        
        % Draw workspace center (for reach strain reference)
        center = [data.x_range/2, data.y_range/2];
        plot(center(1), center(2), 'k+', 'MarkerSize', 12, 'LineWidth', 2);
        
        hold off;
        
        title(sprintf('%s\nSteering: %.2f | Y-Rev: %d | Gate Rot: %.2f', ...
            games_data.names{i}, m.SteeringIndex, m.Y_Reversals, m.GateRotation), 'FontSize', 9);
        xlabel('X (cm)');
        ylabel('Y (cm)');
        axis equal;
        grid on;
        xlim([0 data.x_range]);
        ylim([0 data.y_range]);
    end
    
    % Row 2: Rehab metrics comparison bar chart
    subplot(3, num_games, num_games+1:2*num_games);
    
    % Prepare data for bar chart
    metric_names = {'Steering Index', 'Inflection Counts', 'Goal Align (deg)', ...
                    'Y Reversals', 'Verticality', 'Total Rotation (deg)', ...
                    'Gate Rotation', 'Composite Score'};
    metric_values = zeros(length(metric_names), num_games);
    
    for i = 1:num_games
        m = games_data.rehab_metrics{i};
        metric_values(1, i) = m.SteeringIndex;
        metric_values(2, i) = m.InflectionCounts;
        metric_values(3, i) = m.GoalAlignmentAvgDeg;
        metric_values(4, i) = m.Y_Reversals;
        metric_values(5, i) = m.Verticality;
        metric_values(6, i) = m.TotalRotation;
        metric_values(7, i) = m.GateRotation;
        metric_values(8, i) = m.CompositeScore;
    end
    
    % Create grouped bar chart
    bar(metric_values');
    legend(metric_names, 'Location', 'eastoutside', 'FontSize', 8);
    set(gca, 'XTickLabel', games_data.names);
    ylabel('Metric Value');
    title('Rehabilitation Metrics Comparison', 'FontSize', 11);
    grid on;
    xtickangle(45);
    
    % Row 3: Detailed metrics table
    subplot(3, num_games, 2*num_games+1:3*num_games);
    axis off;
    
    % Create table data
    row_labels = {
        'Steering Index';
        'Inflection Counts';
        'Goal Alignment (deg)';
        'Y-Axis Reversals';
        'Verticality Ratio';
        'Total Rotation (deg)';
        'Gate Rotation';
        'Composite Score';
        '--- Breakdown ---';
        'Steering (×1.0)';
        'Goal Align (×0.5)';
        'Inflections (×0.5)';
        'Y Reversals (×2.0)';
        'Gate Rotation (×2.0)';
    };
    
    col_labels = games_data.names;
    table_data = cell(length(row_labels), num_games);
    
    for i = 1:num_games
        m = games_data.rehab_metrics{i};
        table_data{1, i} = sprintf('%.4f', m.SteeringIndex);
        table_data{2, i} = sprintf('%d', m.InflectionCounts);
        table_data{3, i} = sprintf('%.2f', m.GoalAlignmentAvgDeg);
        table_data{4, i} = sprintf('%d', m.Y_Reversals);
        table_data{5, i} = sprintf('%.4f', m.Verticality);
        table_data{6, i} = sprintf('%.2f', m.TotalRotation);
        table_data{7, i} = sprintf('%.4f', m.GateRotation);
        table_data{8, i} = sprintf('%.4f', m.CompositeScore);
        table_data{9, i} = '';  % Separator
        table_data{10, i} = sprintf('%.4f', m.SteeringIndex * 1.0);
        table_data{11, i} = sprintf('%.4f', m.GoalAlignmentAvgDeg * 0.5);
        table_data{12, i} = sprintf('%.4f', m.InflectionCounts * 0.5);
        table_data{13, i} = sprintf('%.4f', m.Y_Reversals * 2.0);
        table_data{14, i} = sprintf('%.4f', m.GateRotation * 2.0);
    end
    
    % Create uitable
    t = uitable('Data', table_data, ...
        'ColumnName', col_labels, ...
        'RowName', row_labels, ...
        'Units', 'normalized', ...
        'Position', [0.1 0.05 0.8 0.25], ...
        'FontSize', 10);
    t.ColumnWidth = 'auto';
    
    sgtitle('Rehabilitation/Bio-Motor Difficulty Metrics', 'FontSize', 13);
end

