function visualize_rehab_metrics(set_numbers, pairs_numbers, comparison_mode)
    % Visualize rehabilitation/bio-motor difficulty metrics for games
    % Updated to compare original curve vs equalized curve
    % Step size is automatically read from game data files
    %
    % Usage:
    %   visualize_rehab_metrics([2, 9, 7, 6], [4, 3, 3, 3])
    %   visualize_rehab_metrics([1, 2, 3], [3, 3, 3], 1)  % both
    %   visualize_rehab_metrics([1, 2, 3], [3, 3, 3], 2)  % original
    %   visualize_rehab_metrics([1, 2, 3], [3, 3, 3], 3)  % equalized
    %   visualize_rehab_metrics([1, 2, 3], [3, 3, 3], 'both')
    %   visualize_rehab_metrics([1, 2, 3], [3, 3, 3], 'original')
    %   visualize_rehab_metrics([1, 2, 3], [3, 3, 3], 'equalized')
    %
    % Inputs:
    %   set_numbers      - Array of game set numbers
    %   pairs_numbers    - Array of number of pairs for each set
    %   comparison_mode  - 1/'both' (default), 2/'original', or 3/'equalized'
    
    if nargin < 2
        % Default: compare some games
        set_numbers = [2, 9, 7, 6];
        pairs_numbers = [4, 3, 3, 3];
    end
    
    if nargin < 3
        comparison_mode = 1;  % Default: show both original and equalized
    end
    
    % Convert numeric mode to string
    if isnumeric(comparison_mode)
        switch comparison_mode
            case 1
                comparison_mode = 'both';
            case 2
                comparison_mode = 'original';
            case 3
                comparison_mode = 'equalized';
            otherwise
                error('comparison_mode must be 1 (both), 2 (original), or 3 (equalized)');
        end
    else
        % Validate string mode
        valid_modes = {'both', 'original', 'equalized'};
        if ~ismember(lower(comparison_mode), valid_modes)
            error('comparison_mode must be ''both'', ''original'', ''equalized'', or 1, 2, 3');
        end
        comparison_mode = lower(comparison_mode);
    end
    
    if length(set_numbers) ~= length(pairs_numbers)
        error('set_numbers and pairs_numbers must have the same length');
    end
    
    base_path = 'C:\Users\Mahboobe\OneDrive - University of Calgary\code\game_creation_and_fits\new_games\new_games\';
    base_path = '/home/mahboobe/Desktop/game_generation_and_path_planning/new_games/selected_games_2';
    
    fprintf('\n========================================\n');
    fprintf('REHABILITATION METRICS VISUALIZATION\n');
    if strcmp(comparison_mode, 'both')
        fprintf('Original Curve vs Equalized Curve\n');
    elseif strcmp(comparison_mode, 'original')
        fprintf('Original Curve Only\n');
    else
        fprintf('Equalized Curve Only\n');
    end
    fprintf('(Extended Steering Law - Minimal Version)\n');
    fprintf('========================================\n');
    
    % Load games and calculate rehab metrics for BOTH curves
    games_data = struct();
    games_data.rehab_metrics_original = {};
    games_data.rehab_metrics_equalized = {};
    games_data.names = {};
    games_data.data = {};
    games_data.path_original = {};
    games_data.path_equalized = {};
    games_data.path_type = {};
    games_data.step_sizes = [];  % Store step size for each game
    
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
        
        % Get step size from data file
        if isfield(data, 'step_size') && ~isempty(data.step_size)
            step_size = data.step_size;
            
        else
            step_size = 0.25;  % Default fallback
            fprintf('  Warning: step_size not found in data, using default %.2f cm\n', step_size);
        end
        
        % Select path (prefer curve)
        if isfield(data, 'curve') && ~isempty(data.curve)
            path_original = data.curve;
            path_type = 'Bezier Curve';
            
            % Generate equalized curve if needed
            if strcmp(comparison_mode, 'equalized') || strcmp(comparison_mode, 'both')
                % Generate equalized curve if control points are available
                if isfield(data, 'curve_equalized') 
                    path_equalized = data.curve_equalized;
                
                elseif isfield(data, 'curve_segment_points') && ~isempty(data.curve_segment_points)
                    [path_equalized, ~] = generate_equalized_bezier_curve(data.curve_segment_points, step_size);
                else
                    % If no control points, generate them
                    fprintf('  Generating control points for set %d...\n', set_num);
                    variables_matrix = data.variables_matrix;
                    Start_points = data.Start_points;
                    End_points = data.End_points;
                    num_segments = size(Start_points, 1);
                    
                    % Determine n_d and n_phi from variables_matrix structure
                    n_cols = size(variables_matrix, 2);
                    if n_cols == 5
                        n_d = 2;
                        n_phi = 1;
                    else
                        n_d = 3;
                        n_phi = 2;
                    end
                    
                    curve_segment_points = calculate_curve_segment_points(variables_matrix, ...
                        Start_points, End_points, num_segments, n_d, n_phi);
                    [path_equalized, ~] = generate_equalized_bezier_curve(curve_segment_points, step_size);
                end
            else
                path_equalized = [];
            end
        elseif isfield(data, 'path') && ~isempty(data.path)
            path_original = data.path;
            path_equalized = data.path;  % A* path is already discrete
            path_type = 'A* Path';
        else
            fprintf('Warning: %s has no path, skipping\n', file_name);
            continue;
        end
        
        % Calculate rehab metrics based on mode
        if strcmp(comparison_mode, 'original')
            % Only calculate original
            rehab_metrics_original = calculate_rehab_metrics_minimal(path_original, data.obstacle, ...
                data.obstacle_radious);
            rehab_metrics_equalized = [];
        elseif strcmp(comparison_mode, 'equalized')
            % Only calculate equalized
            rehab_metrics_original = [];
            rehab_metrics_equalized = calculate_rehab_metrics_minimal(path_equalized, data.obstacle, ...
                data.obstacle_radious);
        else
            % Calculate both
            rehab_metrics_original = calculate_rehab_metrics_minimal(path_original, data.obstacle, ...
                data.obstacle_radious);
            rehab_metrics_equalized = calculate_rehab_metrics_minimal(path_equalized, data.obstacle, ...
                data.obstacle_radious);
        end
        
        games_data.rehab_metrics_original{end+1} = rehab_metrics_original;
        games_data.rehab_metrics_equalized{end+1} = rehab_metrics_equalized;
        games_data.names{end+1} = sprintf('Set %d (%dp)', set_num, num_pairs);
        games_data.data{end+1} = data;
        games_data.path_original{end+1} = path_original;
        games_data.path_equalized{end+1} = path_equalized;
        games_data.path_type{end+1} = path_type;
        games_data.step_sizes(end+1) = step_size;
    end
    
    num_games = length(games_data.names);
    if num_games == 0
        error('No games loaded successfully');
    end
    
    % Print metrics comparison based on mode
    if strcmp(comparison_mode, 'both')
        for i = 1:num_games
            print_rehab_metrics_comparison(games_data.names{i}, ...
                games_data.rehab_metrics_original{i}, ...
                games_data.rehab_metrics_equalized{i});
        end
    elseif strcmp(comparison_mode, 'original')
        for i = 1:num_games
            print_rehab_metrics_single(games_data.names{i}, ...
                games_data.rehab_metrics_original{i}, 'Original');
        end
    else
        for i = 1:num_games
            print_rehab_metrics_single(games_data.names{i}, ...
                games_data.rehab_metrics_equalized{i}, 'Equalized');
        end
    end
    
    % Create visualization based on mode
    create_rehab_visualization(games_data, comparison_mode);
    
    fprintf('\n========================================\n');
    fprintf('Visualization complete!\n');
    fprintf('========================================\n');
end

function print_rehab_metrics_single(name, m, curve_type)
    % Print rehab metrics for a single curve type
    
    fprintf('\n========================================\n');
    fprintf('%s - %s\n', name, curve_type);
    fprintf('========================================\n');
    
    fprintf('PRIMARY DIFFICULTY METRICS:\n');
    fprintf('  Steering Index:       %.4f\n', m.SteeringIndex);
    fprintf('  K (Total Rotation):   %.4f rad\n', m.K_TotalRotation);
    fprintf('  Curvature Term:       %.4f (alpha*log(1+K))\n', m.CurvatureTerm);
    fprintf('  Composite Score:      %.4f\n', m.CompositeScore);
    fprintf('\n');
    fprintf('METADATA:\n');
    fprintf('  Path Length (cm):     %.4f\n', m.PathLength);
    fprintf('  Avg Path Slope (deg): %.4f\n', m.AvgPathSlope);
    fprintf('\n');
    fprintf('COMPOSITE BREAKDOWN:\n');
    fprintf('  ID = Steering + alpha*log(1+K)\n');
    fprintf('  ID = %.4f + %.4f = %.4f\n', m.SteeringIndex, m.CurvatureTerm, m.CompositeScore);
end

function print_rehab_metrics_comparison(name, m_orig, m_equal)
    % Print rehab metrics comparison (Original vs Equalized)
    
    fprintf('\n========================================\n');
    fprintf('%s\n', name);
    fprintf('========================================\n');
    
    fprintf('PRIMARY DIFFICULTY METRICS:\n');
    fprintf('                          ORIGINAL    EQUALIZED   DIFFERENCE   %%CHANGE\n');
    fprintf('------------------------------------------------------------------------\n');
    fprintf('Steering Index:          %8.4f    %8.4f    %8.4f   %7.2f%%\n', ...
        m_orig.SteeringIndex, m_equal.SteeringIndex, ...
        m_equal.SteeringIndex - m_orig.SteeringIndex, ...
        ((m_equal.SteeringIndex - m_orig.SteeringIndex) / m_orig.SteeringIndex) * 100);
    
    fprintf('K (Total Rotation):      %8.4f    %8.4f    %8.4f   %7.2f%%\n', ...
        m_orig.K_TotalRotation, m_equal.K_TotalRotation, ...
        m_equal.K_TotalRotation - m_orig.K_TotalRotation, ...
        ((m_equal.K_TotalRotation - m_orig.K_TotalRotation) / m_orig.K_TotalRotation) * 100);
    
    fprintf('Curvature Term:          %8.4f    %8.4f    %8.4f   %7.2f%%\n', ...
        m_orig.CurvatureTerm, m_equal.CurvatureTerm, ...
        m_equal.CurvatureTerm - m_orig.CurvatureTerm, ...
        ((m_equal.CurvatureTerm - m_orig.CurvatureTerm) / m_orig.CurvatureTerm) * 100);
    
    fprintf('Composite Score (ID):    %8.4f    %8.4f    %8.4f   %7.2f%%\n', ...
        m_orig.CompositeScore, m_equal.CompositeScore, ...
        m_equal.CompositeScore - m_orig.CompositeScore, ...
        ((m_equal.CompositeScore - m_orig.CompositeScore) / m_orig.CompositeScore) * 100);
    
    fprintf('\nMETADATA METRICS:\n');
    fprintf('                          ORIGINAL    EQUALIZED   DIFFERENCE   %%CHANGE\n');
    fprintf('------------------------------------------------------------------------\n');
    fprintf('Path Length (cm):        %8.2f    %8.2f    %8.2f   %7.2f%%\n', ...
        m_orig.PathLength, m_equal.PathLength, ...
        m_equal.PathLength - m_orig.PathLength, ...
        ((m_equal.PathLength - m_orig.PathLength) / m_orig.PathLength) * 100);
    
    fprintf('Avg Path Slope (deg):    %8.2f    %8.2f    %8.2f   %7.2f%%\n', ...
        m_orig.AvgPathSlope, m_equal.AvgPathSlope, ...
        m_equal.AvgPathSlope - m_orig.AvgPathSlope, ...
        ((m_equal.AvgPathSlope - m_orig.AvgPathSlope) / m_orig.AvgPathSlope) * 100);
end

function create_rehab_visualization(games_data, comparison_mode)
    % Create visualization based on comparison mode
    
    if strcmp(comparison_mode, 'both')
        create_rehab_comparison_visualization(games_data);
    elseif strcmp(comparison_mode, 'original')
        create_rehab_single_visualization(games_data, 'original');
    else
        create_rehab_single_visualization(games_data, 'equalized');
    end
end

function create_rehab_single_visualization(games_data, mode)
    % Create visualization for single curve type (original or equalized)
    
    num_games = length(games_data.names);
    
    if strcmp(mode, 'original')
        title_suffix = 'Original Curves';
        metrics_list = games_data.rehab_metrics_original;
        path_list = games_data.path_original;
    else
        % Get unique step sizes
        unique_steps = unique(games_data.step_sizes);
        if length(unique_steps) == 1
            title_suffix = sprintf('Equalized Curves (%.2f cm step)', unique_steps(1));
        else
            title_suffix = 'Equalized Curves (variable steps)';
        end
        metrics_list = games_data.rehab_metrics_equalized;
        path_list = games_data.path_equalized;
    end
    
    figure('Name', sprintf('Rehab Metrics: %s', title_suffix), ...
           'Position', [50 50 1400 900]);
    
    % Row 1: Game layouts with difficulty coloring
    for i = 1:num_games
        subplot(3, num_games, i);
        data = games_data.data{i};
        path = path_list{i};
        m = metrics_list{i};
        
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
            obstacle_dists = sqrt(sum((data.obstacle - path_pts(k,:)).^2, 2));
            clearances = obstacle_dists - data.obstacle_radious(:);
            d = min(clearances);
            dists(k) = 1 ./ max(d, 0.1);
        end
        
        % Plot path with color mapped to difficulty
        scatter(path_pts(:,1), path_pts(:,2), 30, dists, 'filled');
        colormap(gca, 'jet');
        c = colorbar;
        c.Label.String = 'Difficulty';
        
        % Draw start and end
        plot(data.X_s(1), data.X_s(2), 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
        plot(data.X_e(1), data.X_e(2), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
        
        hold off;
        
        if strcmp(mode, 'equalized')
            title(sprintf('%s (%.2f cm step)\nID: %.2f | Steering: %.2f | Pts: %d', ...
                games_data.names{i}, games_data.step_sizes(i), m.CompositeScore, m.SteeringIndex, size(path, 1)), 'FontSize', 9);
        else
            title(sprintf('%s\nID: %.2f | Steering: %.2f | Pts: %d', ...
                games_data.names{i}, m.CompositeScore, m.SteeringIndex, size(path, 1)), 'FontSize', 9);
        end
        xlabel('X (cm)');
        ylabel('Y (cm)');
        axis equal;
        grid on;
        xlim([0 data.x_range]);
        ylim([0 data.y_range]);
    end
    
    % Row 2: Primary metrics comparison bar chart
    subplot(3, num_games, num_games+1:2*num_games);
    
    metric_names = {'Steering Index', 'K (Total Rotation)', 'Curvature Term', 'Composite Score'};
    metric_values = zeros(length(metric_names), num_games);
    
    for i = 1:num_games
        m = metrics_list{i};
        metric_values(1, i) = m.SteeringIndex;
        metric_values(2, i) = m.K_TotalRotation;
        metric_values(3, i) = m.CurvatureTerm;
        metric_values(4, i) = m.CompositeScore;
    end
    
    bar(metric_values');
    legend(metric_names, 'Location', 'eastoutside', 'FontSize', 8);
    set(gca, 'XTickLabel', games_data.names);
    ylabel('Metric Value');
    title('Primary Difficulty Metrics (Extended Steering Law)', 'FontSize', 11);
    grid on;
    
    % Row 3: Detailed metrics table
    subplot(3, num_games, 2*num_games+1:3*num_games);
    axis off;
    
    row_labels = {
        '--- PRIMARY METRICS ---';
        'Steering Index';
        'K (Total Rotation, rad)';
        'Curvature Term';
        'Composite Score (ID)';
        '--- METADATA ---';
        'Path Length (cm)';
        'Avg Path Slope (deg)';
        '--- FORMULA ---';
        'ID = Steering + alpha*log(1+K)';
    };
    
    col_labels = games_data.names;
    table_data = cell(length(row_labels), num_games);
    
    for i = 1:num_games
        m = metrics_list{i};
        table_data{1, i} = '';
        table_data{2, i} = sprintf('%.4f', m.SteeringIndex);
        table_data{3, i} = sprintf('%.4f', m.K_TotalRotation);
        table_data{4, i} = sprintf('%.4f', m.CurvatureTerm);
        table_data{5, i} = sprintf('%.4f', m.CompositeScore);
        table_data{6, i} = '';
        table_data{7, i} = sprintf('%.2f', m.PathLength);
        table_data{8, i} = sprintf('%.2f', m.AvgPathSlope);
        table_data{9, i} = '';
        table_data{10, i} = sprintf('%.2f + %.2f = %.2f', m.SteeringIndex, m.CurvatureTerm, m.CompositeScore);
    end
    
    t = uitable('Data', table_data, ...
        'ColumnName', col_labels, ...
        'RowName', row_labels, ...
        'Units', 'normalized', ...
        'Position', [0.1 0.02 0.8 0.3], ...
        'FontSize', 10);
    t.ColumnWidth = 'auto';
    
    sgtitle(sprintf('Rehabilitation Metrics: %s', title_suffix), 'FontSize', 13);
end

function create_rehab_comparison_visualization(games_data)
    % Create visualization comparing original vs equalized curves
    
    num_games = length(games_data.names);
    
    figure('Name', 'Rehab Metrics: Original vs Equalized Comparison', ...
           'Position', [50 50 1600 1000]);
    
    % Row 1: Game layouts - Original curves
    for i = 1:num_games
        subplot(4, num_games, i);
        data = games_data.data{i};
        path = games_data.path_original{i};
        m = games_data.rehab_metrics_original{i};
        
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
        scatter(path_pts(:,1), path_pts(:,2), 30, dists, 'filled');
        colormap(gca, 'jet'); % Red = Hard (narrow), Blue = Easy (wide)
        c = colorbar;
        c.Label.String = 'Difficulty';
        
        % Draw start and end
        plot(data.X_s(1), data.X_s(2), 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
        plot(data.X_e(1), data.X_e(2), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
        
        hold off;
        
        title(sprintf('%s - ORIGINAL\nID: %.2f | Steering: %.2f | Pts: %d', ...
            games_data.names{i}, m.CompositeScore, m.SteeringIndex, size(path, 1)), 'FontSize', 9);
        xlabel('X (cm)');
        ylabel('Y (cm)');
        axis equal;
        grid on;
        xlim([0 data.x_range]);
        ylim([0 data.y_range]);
    end
    
    % Row 2: Game layouts - Equalized curves
    for i = 1:num_games
        subplot(4, num_games, num_games + i);
        data = games_data.data{i};
        path = games_data.path_equalized{i};
        m = games_data.rehab_metrics_equalized{i};
        
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
        scatter(path_pts(:,1), path_pts(:,2), 30, dists, 'filled');
        colormap(gca, 'jet'); % Red = Hard (narrow), Blue = Easy (wide)
        c = colorbar;
        c.Label.String = 'Difficulty';
        
        % Draw start and end
        plot(data.X_s(1), data.X_s(2), 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
        plot(data.X_e(1), data.X_e(2), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
        
        hold off;
        
        title(sprintf('%s - EQUALIZED (%.2f cm)\nID: %.2f | Steering: %.2f | Pts: %d', ...
            games_data.names{i}, games_data.step_sizes(i), m.CompositeScore, m.SteeringIndex, size(path, 1)), 'FontSize', 9);
        xlabel('X (cm)');
        ylabel('Y (cm)');
        axis equal;
        grid on;
        xlim([0 data.x_range]);
        ylim([0 data.y_range]);
    end
    
    % Row 3: Metrics comparison bar chart
    subplot(4, num_games, 2*num_games+1:3*num_games);
    
    % Prepare data for grouped bar chart
    metric_names = {'Steering Index', 'K (Total Rotation)', 'Curvature Term', 'Composite Score'};
    
    % Create data matrix: each row is a game, columns alternate original/equalized
    bar_data = zeros(num_games * 2, length(metric_names));
    bar_labels = cell(num_games * 2, 1);
    
    for i = 1:num_games
        m_orig = games_data.rehab_metrics_original{i};
        m_equal = games_data.rehab_metrics_equalized{i};
        
        % Original metrics (odd rows)
        bar_data(2*i-1, 1) = m_orig.SteeringIndex;
        bar_data(2*i-1, 2) = m_orig.K_TotalRotation;
        bar_data(2*i-1, 3) = m_orig.CurvatureTerm;
        bar_data(2*i-1, 4) = m_orig.CompositeScore;
        bar_labels{2*i-1} = sprintf('%s (Orig)', games_data.names{i});
        
        % Equalized metrics (even rows)
        bar_data(2*i, 1) = m_equal.SteeringIndex;
        bar_data(2*i, 2) = m_equal.K_TotalRotation;
        bar_data(2*i, 3) = m_equal.CurvatureTerm;
        bar_data(2*i, 4) = m_equal.CompositeScore;
        bar_labels{2*i} = sprintf('%s (Equal)', games_data.names{i});
    end
    
    % Create grouped bar chart
    b = bar(bar_data);
    % Color original bars blue, equalized bars red
    for i = 1:length(metric_names)
        b(i).FaceColor = 'flat';
    end
    
    legend(metric_names, 'Location', 'eastoutside', 'FontSize', 8);
    set(gca, 'XTickLabel', bar_labels, 'XTickLabelRotation', 45);
    ylabel('Metric Value');
    title('Primary Difficulty Metrics: Original vs Equalized', 'FontSize', 11);
    grid on;
    
    % Row 4: Detailed comparison table
    subplot(4, num_games, 3*num_games+1:4*num_games);
    axis off;
    
    % Create table data - show both original and equalized for each game
    row_labels = {
        '--- PRIMARY METRICS ---';
        'Steering Index (Orig)';
        'Steering Index (Equal)';
        'K Total Rotation (Orig)';
        'K Total Rotation (Equal)';
        'Curvature Term (Orig)';
        'Curvature Term (Equal)';
        'Composite Score (Orig)';
        'Composite Score (Equal)';
        '--- METADATA ---';
        'Path Length cm (Orig)';
        'Path Length cm (Equal)';
        'Avg Slope deg (Orig)';
        'Avg Slope deg (Equal)';
        '--- DIFFERENCE (%) ---';
        'Steering Δ%';
        'K Rotation Δ%';
        'Composite Δ%';
        'Path Length Δ%';
        'Avg Slope Δ%';
    };
    
    col_labels = games_data.names;
    table_data = cell(length(row_labels), num_games);
    
    for i = 1:num_games
        m_orig = games_data.rehab_metrics_original{i};
        m_equal = games_data.rehab_metrics_equalized{i};
        
        table_data{1, i} = '';  % Separator
        table_data{2, i} = sprintf('%.4f', m_orig.SteeringIndex);
        table_data{3, i} = sprintf('%.4f', m_equal.SteeringIndex);
        table_data{4, i} = sprintf('%.4f', m_orig.K_TotalRotation);
        table_data{5, i} = sprintf('%.4f', m_equal.K_TotalRotation);
        table_data{6, i} = sprintf('%.4f', m_orig.CurvatureTerm);
        table_data{7, i} = sprintf('%.4f', m_equal.CurvatureTerm);
        table_data{8, i} = sprintf('%.4f', m_orig.CompositeScore);
        table_data{9, i} = sprintf('%.4f', m_equal.CompositeScore);
        table_data{10, i} = '';  % Separator
        table_data{11, i} = sprintf('%.2f', m_orig.PathLength);
        table_data{12, i} = sprintf('%.2f', m_equal.PathLength);
        table_data{13, i} = sprintf('%.2f', m_orig.AvgPathSlope);
        table_data{14, i} = sprintf('%.2f', m_equal.AvgPathSlope);
        table_data{15, i} = '';  % Separator
        
        % Calculate percentage changes
        steering_pct = ((m_equal.SteeringIndex - m_orig.SteeringIndex) / m_orig.SteeringIndex) * 100;
        k_pct = ((m_equal.K_TotalRotation - m_orig.K_TotalRotation) / m_orig.K_TotalRotation) * 100;
        composite_pct = ((m_equal.CompositeScore - m_orig.CompositeScore) / m_orig.CompositeScore) * 100;
        length_pct = ((m_equal.PathLength - m_orig.PathLength) / m_orig.PathLength) * 100;
        slope_pct = ((m_equal.AvgPathSlope - m_orig.AvgPathSlope) / m_orig.AvgPathSlope) * 100;
        
        table_data{16, i} = sprintf('%.2f%%', steering_pct);
        table_data{17, i} = sprintf('%.2f%%', k_pct);
        table_data{18, i} = sprintf('%.2f%%', composite_pct);
        table_data{19, i} = sprintf('%.2f%%', length_pct);
        table_data{20, i} = sprintf('%.2f%%', slope_pct);
    end
    
    % Create uitable
    t = uitable('Data', table_data, ...
        'ColumnName', col_labels, ...
        'RowName', row_labels, ...
        'Units', 'normalized', ...
        'Position', [0.05 0.02 0.9 0.22], ...
        'FontSize', 9);
    t.ColumnWidth = 'auto';
    
    % Create title based on step sizes
    unique_steps = unique(games_data.step_sizes);
    if length(unique_steps) == 1
        step_text = sprintf('%.2f cm step', unique_steps(1));
    else
        step_text = 'variable steps';
    end
    
    sgtitle(sprintf('Rehabilitation Metrics Comparison: Original vs Equalized (%s)', step_text), ...
        'FontSize', 14, 'FontWeight', 'bold');
end
