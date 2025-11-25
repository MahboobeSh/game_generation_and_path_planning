function analyze_game_difficulty_metrics(custom_weights)
    % ANALYZE_GAME_DIFFICULTY_METRICS - Analyze difficulty metrics across all games
    %
    % This script loads all games from game/2pairs/fit/, game/3pairs/fit/, 
    % and game/4pairs/fit/ folders, calculates difficulty metrics, and provides
    % comprehensive visualizations and statistics.
    %
    % Usage:
    %   analyze_game_difficulty_metrics()  % Use default weights
    %   analyze_game_difficulty_metrics(weights_struct)  % Use custom weights
    %
    % Custom weights structure example:
    %   weights.path_length = 0.10;
    %   weights.curvature = 0.12;
    %   weights.clearance = 0.18;
    %   weights.pair_distance = 0.18;
    %   weights.constraint_tightness = 0.15;
    %   weights.distance = 0.10;
    %   weights.density = 0.07;
    %   weights.segments = 0.07;
    %   weights.size = 0.03;
    
    % Base folder for games
    base_folder = '/home/mahboobe/Desktop/game_generation_and_path_planning/game/';
    
    % Folders to analyze
    folders_to_analyze = {'2pairs/fit', '3pairs/fit', '4pairs/fit'};
    
    % Initialize storage for all metrics
    all_results = struct();
    all_results.game_info = {};
    all_results.metrics = [];
    all_results.overall_difficulty = [];
    all_results.number_of_pairs = [];
    
    fprintf('Loading games and calculating difficulty metrics...\n');
    
    % Process each folder
    for folder_idx = 1:length(folders_to_analyze)
        folder_path = fullfile(base_folder, folders_to_analyze{folder_idx});
        
        % Extract number of pairs from folder name
        folder_name = folders_to_analyze{folder_idx};
        slash_idx = strfind(folder_name, '/');
        if ~isempty(slash_idx)
            pairs_str = folder_name(1:slash_idx(1)-1);
        else
            pairs_str = folder_name;
        end
        pairs_idx = strfind(pairs_str, 'pairs');
        if ~isempty(pairs_idx)
            number_of_pairs = str2double(pairs_str(1:pairs_idx(1)-1));
        else
            number_of_pairs = 2; % default
        end
        
        % Get all .mat files in the folder
        mat_files = dir(fullfile(folder_path, '*.mat'));
        
        fprintf('  Processing %s: %d games found\n', folders_to_analyze{folder_idx}, length(mat_files));
        
        % Process each game file
        for file_idx = 1:length(mat_files)
            file_path = fullfile(folder_path, mat_files(file_idx).name);
            
            try
                % Load game data
                data = load(file_path);
                
                % Extract required variables - prefer curve over path
                if isfield(data, 'curve') && ~isempty(data.curve)
                    path = data.curve;
                    path_type = 'Bezier Curve';
                elseif isfield(data, 'path') && ~isempty(data.path)
                    path = data.path;
                    path_type = 'A* Path';
                else
                    fprintf('    Warning: %s has no path or curve, skipping\n', mat_files(file_idx).name);
                    continue;
                end
                obstacles = data.obstacle;
                obstacle_radii = data.obstacle_radious;
                X_s = data.X_s;
                X_e = data.X_e;
                x_range = data.x_range;
                y_range = data.y_range;
                
                % Use number_of_pairs from file if available, otherwise from folder
                if isfield(data, 'number_of_pairs')
                    num_pairs = data.number_of_pairs;
                else
                    num_pairs = number_of_pairs;
                end
                
                % Calculate difficulty metrics
                % Pass Start_points and End_points if available for better curvature calculation
                if isfield(data, 'Start_points') && isfield(data, 'End_points')
                    if nargin > 0 && ~isempty(custom_weights)
                        difficulty_metrics = calculate_game_difficulty_with_weights(...
                            path, obstacles, obstacle_radii, X_s, X_e, x_range, y_range, num_pairs, custom_weights, data.Start_points, data.End_points);
                    else
                        difficulty_metrics = calculate_game_difficulty(...
                            path, obstacles, obstacle_radii, X_s, X_e, x_range, y_range, num_pairs, data.Start_points, data.End_points);
                    end
                else
                    if nargin > 0 && ~isempty(custom_weights)
                        difficulty_metrics = calculate_game_difficulty_with_weights(...
                            path, obstacles, obstacle_radii, X_s, X_e, x_range, y_range, num_pairs, custom_weights);
                    else
                        difficulty_metrics = calculate_game_difficulty(...
                            path, obstacles, obstacle_radii, X_s, X_e, x_range, y_range, num_pairs);
                    end
                end
                
                % Calculate adjusted difficulty for cross-pair comparison
                [difficulty_metrics.adjusted_difficulty, difficulty_metrics.adjusted_category] = calculate_adjusted_difficulty(difficulty_metrics, num_pairs);
                
                % Store results
                game_name = mat_files(file_idx).name;
                all_results.game_info{end+1} = game_name;
                all_results.metrics = [all_results.metrics; difficulty_metrics];
                all_results.overall_difficulty(end+1) = difficulty_metrics.overall_difficulty;
                all_results.number_of_pairs(end+1) = num_pairs;
                
            catch ME
                fprintf('    Error processing %s: %s\n', mat_files(file_idx).name, ME.message);
                continue;
            end
        end
    end
    
    fprintf('\nTotal games analyzed: %d\n', length(all_results.overall_difficulty));
    
    % Create comprehensive visualizations
    create_visualizations(all_results);
    
    % Display summary statistics
    display_summary_statistics(all_results);
    
    % Save results
    save_results(all_results);
    
    fprintf('\nAnalysis complete! Results saved to difficulty_analysis_results.mat\n');
end

function difficulty_metrics = calculate_game_difficulty_with_weights(path, obstacles, obstacle_radii, X_s, X_e, x_range, y_range, number_of_pairs, custom_weights, Start_points, End_points)
    % Calculate difficulty with custom weights
    % First get all metrics using the original function
    if nargin >= 10 && exist('Start_points', 'var') && exist('End_points', 'var')
        difficulty_metrics = calculate_game_difficulty(path, obstacles, obstacle_radii, X_s, X_e, x_range, y_range, number_of_pairs, Start_points, End_points);
    else
        difficulty_metrics = calculate_game_difficulty(path, obstacles, obstacle_radii, X_s, X_e, x_range, y_range, number_of_pairs);
    end
    
    % Recalculate overall_difficulty with custom weights
    % Normalize each factor to 0-1 range (same as in original function)
    path_length_norm = min(difficulty_metrics.path_length_factor / 2, 1);
    curvature_norm = min(difficulty_metrics.curvature_factor / 0.5, 1);
    clearance_norm = 1 - min(difficulty_metrics.min_clearance / 5, 1);
    distance_norm = 1 - min(difficulty_metrics.avg_obstacle_distance / 10, 1);
    density_norm = min(difficulty_metrics.obstacle_density * 100, 1);
    segments_norm = min(difficulty_metrics.num_segments / 10, 1);
    size_norm = min((difficulty_metrics.avg_obstacle_size / (min(x_range, y_range) / 10)), 1);
    
    if isfinite(difficulty_metrics.min_pair_distance)
        pair_distance_norm = 1 - min(difficulty_metrics.min_pair_distance / 5, 1);
    else
        pair_distance_norm = 0;
    end
    
    constraint_tightness_norm = difficulty_metrics.constraint_tightness;
    
    % Use custom weights
    weights = custom_weights;
    
    % Recalculate overall difficulty
    difficulty_metrics.overall_difficulty = weights.path_length * path_length_norm + ...
                                            weights.curvature * curvature_norm + ...
                                            weights.clearance * clearance_norm + ...
                                            weights.pair_distance * pair_distance_norm + ...
                                            weights.constraint_tightness * constraint_tightness_norm + ...
                                            weights.distance * distance_norm + ...
                                            weights.density * density_norm + ...
                                            weights.segments * segments_norm + ...
                                            weights.size * size_norm;
    
    % Update category
    if difficulty_metrics.overall_difficulty < 0.33
        difficulty_metrics.difficulty_category = 'Easy';
    elseif difficulty_metrics.overall_difficulty < 0.67
        difficulty_metrics.difficulty_category = 'Medium';
    else
        difficulty_metrics.difficulty_category = 'Hard';
    end
end

function create_visualizations(all_results)
    % Create comprehensive visualizations
    
    num_games = length(all_results.overall_difficulty);
    metrics = all_results.metrics;
    
    % Create figure with multiple subplots
    figure('Position', [100, 100, 1600, 1200], 'Name', 'Game Difficulty Analysis');
    
    % 1. Overall Difficulty Distribution
    subplot(3, 3, 1);
    histogram(all_results.overall_difficulty, 20, 'FaceColor', [0.2 0.6 0.8]);
    xlabel('Overall Difficulty Score');
    ylabel('Number of Games');
    title('Distribution of Overall Difficulty');
    grid on;
    
    % 2. Difficulty by Number of Pairs
    subplot(3, 3, 2);
    unique_pairs = unique(all_results.number_of_pairs);
    % Create grouping vector that matches each data point
    group_vector = [];
    data_vector = [];
    for i = 1:length(unique_pairs)
        idx = all_results.number_of_pairs == unique_pairs(i);
        group_data = all_results.overall_difficulty(idx);
        data_vector = [data_vector; group_data(:)];
        group_vector = [group_vector; repmat(unique_pairs(i), length(group_data), 1)];
    end
    boxplot(data_vector, group_vector);
    xlabel('Number of Pairs');
    ylabel('Overall Difficulty');
    title('Difficulty by Number of Pairs');
    grid on;
    
    % 3. Difficulty Categories
    subplot(3, 3, 3);
    categories = {metrics.difficulty_category};
    easy_count = sum(strcmp(categories, 'Easy'));
    medium_count = sum(strcmp(categories, 'Medium'));
    hard_count = sum(strcmp(categories, 'Hard'));
    pie([easy_count, medium_count, hard_count], {'Easy', 'Medium', 'Hard'});
    title('Difficulty Category Distribution');
    
    % 4. Path Length Factor
    subplot(3, 3, 4);
    path_lengths = [metrics.path_length_factor];
    histogram(path_lengths, 15, 'FaceColor', [0.8 0.4 0.2]);
    xlabel('Path Length Factor');
    ylabel('Frequency');
    title('Path Length Factor Distribution');
    grid on;
    
    % 5. Minimum Clearance
    subplot(3, 3, 5);
    clearances = [metrics.min_clearance];
    histogram(clearances, 15, 'FaceColor', [0.2 0.8 0.4]);
    xlabel('Minimum Clearance (cm)');
    ylabel('Frequency');
    title('Minimum Clearance Distribution');
    grid on;
    
    % 6. Curvature Factor
    subplot(3, 3, 6);
    curvatures = [metrics.curvature_factor];
    histogram(curvatures, 15, 'FaceColor', [0.8 0.2 0.6]);
    xlabel('Curvature Factor');
    ylabel('Frequency');
    title('Curvature Factor Distribution');
    grid on;
    
    % 7. Pair Distance vs Overall Difficulty
    subplot(3, 3, 7);
    pair_distances = [metrics.min_pair_distance];
    valid_idx = isfinite(pair_distances);
    scatter(pair_distances(valid_idx), all_results.overall_difficulty(valid_idx), 50, 'filled', 'MarkerFaceAlpha', 0.6);
    xlabel('Minimum Pair Distance (cm)');
    ylabel('Overall Difficulty');
    title('Pair Distance vs Difficulty');
    grid on;
    
    % 8. Constraint Tightness vs Overall Difficulty
    subplot(3, 3, 8);
    tightness = [metrics.constraint_tightness];
    scatter(tightness, all_results.overall_difficulty, 50, 'filled', 'MarkerFaceAlpha', 0.6);
    xlabel('Constraint Tightness');
    ylabel('Overall Difficulty');
    title('Constraint Tightness vs Difficulty');
    grid on;
    
    % 9. Correlation Matrix of Key Metrics
    subplot(3, 3, 9);
    key_metrics = [
        all_results.overall_difficulty';
        [metrics.path_length_factor]';
        [metrics.curvature_factor]';
        [metrics.min_clearance]';
        [metrics.min_pair_distance]';
        [metrics.constraint_tightness]';
    ];
    key_metrics(5, ~isfinite(key_metrics(5, :))) = 0; % Replace inf with 0 for pair distance
    corr_matrix = corrcoef(key_metrics');
    metric_names = {'Overall', 'Path Len', 'Curvature', 'Clearance', 'Pair Dist', 'Tightness'};
    imagesc(corr_matrix);
    colorbar;
    % Use a standard colormap available in all MATLAB versions
    % 'coolwarm' is not available in older versions, use 'jet' or create custom
    try
        colormap(gca, 'coolwarm');
    catch
        % Fallback: create a coolwarm-like colormap (blue to white to red)
        n = 64;
        r = [linspace(0.23, 1, n/2), ones(1, n/2)];
        g = [linspace(0.3, 1, n/2), linspace(1, 0.3, n/2)];
        b = [ones(1, n/2), linspace(1, 0.23, n/2)];
        custom_coolwarm = [r', g', b'];
        colormap(gca, custom_coolwarm);
    end
    caxis([-1 1]);
    set(gca, 'XTick', 1:length(metric_names), 'XTickLabel', metric_names);
    set(gca, 'YTick', 1:length(metric_names), 'YTickLabel', metric_names);
    title('Metric Correlation Matrix');
    
    % Add correlation values as text
    for i = 1:size(corr_matrix, 1)
        for j = 1:size(corr_matrix, 2)
            text(j, i, sprintf('%.2f', corr_matrix(i, j)), ...
                'HorizontalAlignment', 'center', 'Color', 'white', 'FontSize', 8);
        end
    end
    
    sgtitle('Comprehensive Game Difficulty Analysis', 'FontSize', 16, 'FontWeight', 'bold');
    
    % Create additional figure for cross-pair comparison
    figure('Position', [200, 200, 1400, 800], 'Name', 'Cross-Pair Difficulty Comparison');
    
    % Difficulty by number of pairs (original vs adjusted)
    subplot(2, 2, 1);
    unique_pairs = unique(all_results.number_of_pairs);
    orig_data = cell(length(unique_pairs), 1);
    adj_data = cell(length(unique_pairs), 1);
    for i = 1:length(unique_pairs)
        idx = all_results.number_of_pairs == unique_pairs(i);
        orig_data{i} = all_results.overall_difficulty(idx);
        adj_data{i} = [all_results.metrics(idx).adjusted_difficulty];
    end
    
    % Create grouped bar chart instead
    means_orig = cellfun(@mean, orig_data);
    means_adj = cellfun(@mean, adj_data);
    x = 1:length(unique_pairs);
    bar_width = 0.35;
    bar(x - bar_width/2, means_orig, bar_width, 'FaceColor', [0.7 0.7 0.9], 'DisplayName', 'Original');
    hold on;
    bar(x + bar_width/2, means_adj, bar_width, 'FaceColor', [0.9 0.5 0.5], 'DisplayName', 'Adjusted');
    set(gca, 'XTick', x, 'XTickLabel', arrayfun(@(x) sprintf('%d pairs', x), unique_pairs, 'UniformOutput', false));
    xlabel('Number of Pairs');
    ylabel('Mean Difficulty Score');
    title('Original vs Adjusted Difficulty by Pair Number');
    legend('Location', 'best');
    grid on;
    
    % Scatter plot: Original vs Adjusted
    subplot(2, 2, 2);
    scatter(all_results.overall_difficulty, [all_results.metrics.adjusted_difficulty], ...
        50, all_results.number_of_pairs, 'filled');
    hold on;
    plot([0 1], [0 1], 'r--', 'LineWidth', 2);
    xlabel('Original Difficulty');
    ylabel('Adjusted Difficulty');
    title('Original vs Adjusted Difficulty');
    colorbar;
    colormap(gca, 'cool');
    caxis([2 4]);
    ylabel(colorbar, 'Number of Pairs');
    grid on;
    
    % Adjusted difficulty distribution
    subplot(2, 2, 3);
    histogram([all_results.metrics.adjusted_difficulty], 20, 'FaceColor', [0.8 0.4 0.2]);
    xlabel('Adjusted Difficulty Score');
    ylabel('Number of Games');
    title('Distribution of Adjusted Difficulty');
    grid on;
    
    % Top games by adjusted difficulty
    subplot(2, 2, 4);
    axis off;
    [~, sorted_idx] = sort([all_results.metrics.adjusted_difficulty], 'descend');
    top_text = {'Top 10 Games by Adjusted Difficulty:'; ''};
    for i = 1:min(10, length(sorted_idx))
        idx = sorted_idx(i);
        % Extract set number from filename (e.g., "set_9_3pairs.mat" -> 9)
        filename = all_results.game_info{idx};
        set_num_str = regexp(filename, 'set_(\d+)_', 'tokens', 'once');
        if ~isempty(set_num_str)
            set_num = str2double(set_num_str{1});
        else
            set_num = 0;
        end
        top_text{end+1} = sprintf('%d. Set %d (%d pairs): %.4f', ...
            i, set_num, all_results.number_of_pairs(idx), ...
            all_results.metrics(idx).adjusted_difficulty);
    end
    text(0.1, 0.5, top_text, 'FontSize', 10, 'FontFamily', 'monospace', ...
         'VerticalAlignment', 'middle', 'HorizontalAlignment', 'left');
    
    sgtitle('Cross-Pair Difficulty Comparison (Adjusted for Pair Complexity)', ...
        'FontSize', 14, 'FontWeight', 'bold');
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

function display_summary_statistics(all_results)
    % Display summary statistics
    
    fprintf('\n=== SUMMARY STATISTICS ===\n\n');
    
    % Overall difficulty statistics
    fprintf('Overall Difficulty:\n');
    fprintf('  Mean:   %.4f\n', mean(all_results.overall_difficulty));
    fprintf('  Median: %.4f\n', median(all_results.overall_difficulty));
    fprintf('  Std:    %.4f\n', std(all_results.overall_difficulty));
    fprintf('  Min:    %.4f\n', min(all_results.overall_difficulty));
    fprintf('  Max:    %.4f\n', max(all_results.overall_difficulty));
    
    % By number of pairs
    fprintf('\nBy Number of Pairs:\n');
    unique_pairs = unique(all_results.number_of_pairs);
    for i = 1:length(unique_pairs)
        idx = all_results.number_of_pairs == unique_pairs(i);
        fprintf('  %d pairs: %d games, Mean difficulty: %.4f\n', ...
            unique_pairs(i), sum(idx), mean(all_results.overall_difficulty(idx)));
    end
    
    % Difficulty categories
    fprintf('\nDifficulty Categories:\n');
    categories = {all_results.metrics.difficulty_category};
    easy_count = sum(strcmp(categories, 'Easy'));
    medium_count = sum(strcmp(categories, 'Medium'));
    hard_count = sum(strcmp(categories, 'Hard'));
    fprintf('  Easy:   %d games (%.1f%%)\n', easy_count, 100*easy_count/length(categories));
    fprintf('  Medium: %d games (%.1f%%)\n', medium_count, 100*medium_count/length(categories));
    fprintf('  Hard:   %d games (%.1f%%)\n', hard_count, 100*hard_count/length(categories));
    
    % Key metrics statistics
    fprintf('\nKey Metrics:\n');
    path_lengths = [all_results.metrics.path_length_factor];
    clearances = [all_results.metrics.min_clearance];
    curvatures = [all_results.metrics.curvature_factor];
    pair_distances = [all_results.metrics.min_pair_distance];
    pair_distances = pair_distances(isfinite(pair_distances));
    tightness = [all_results.metrics.constraint_tightness];
    
    fprintf('  Path Length Factor:     Mean=%.4f, Std=%.4f\n', mean(path_lengths), std(path_lengths));
    fprintf('  Min Clearance (cm):     Mean=%.4f, Std=%.4f\n', mean(clearances), std(clearances));
    fprintf('  Curvature Factor:       Mean=%.4f, Std=%.4f\n', mean(curvatures), std(curvatures));
    fprintf('  Min Pair Distance (cm): Mean=%.4f, Std=%.4f\n', mean(pair_distances), std(pair_distances));
    fprintf('  Constraint Tightness:   Mean=%.4f, Std=%.4f\n', mean(tightness), std(tightness));
    
    % Top and bottom games
    fprintf('\nEasiest Games (Top 5):\n');
    [~, easy_idx] = sort(all_results.overall_difficulty, 'ascend');
    for i = 1:min(5, length(easy_idx))
        idx = easy_idx(i);
        fprintf('  %s: %.4f (%s)\n', ...
            all_results.game_info{idx}, ...
            all_results.overall_difficulty(idx), ...
            all_results.metrics(idx).difficulty_category);
    end
    
    fprintf('\nHardest Games (Top 5):\n');
    [~, hard_idx] = sort(all_results.overall_difficulty, 'descend');
    for i = 1:min(5, length(hard_idx))
        idx = hard_idx(i);
        fprintf('  %s: %.4f (%s)\n', ...
            all_results.game_info{idx}, ...
            all_results.overall_difficulty(idx), ...
            all_results.metrics(idx).difficulty_category);
    end
end

function save_results(all_results)
    % Save results to .mat file
    
    % Create a structured output
    results = struct();
    results.game_info = all_results.game_info;
    results.overall_difficulty = all_results.overall_difficulty;
    results.number_of_pairs = all_results.number_of_pairs;
    
    % Extract all metric fields into arrays
    metric_fields = fieldnames(all_results.metrics);
    for i = 1:length(metric_fields)
        field_name = metric_fields{i};
        if ischar(all_results.metrics(1).(field_name))
            % Handle string fields (like difficulty_category)
            results.(field_name) = {all_results.metrics.(field_name)};
        else
            % Handle numeric fields
            results.(field_name) = [all_results.metrics.(field_name)];
        end
    end
    
    % Save to file
    save('difficulty_analysis_results.mat', 'results', '-v7.3');
    
    % Also save as CSV for easy viewing
    try
        % Create table for CSV export
        csv_data = table();
        csv_data.GameName = all_results.game_info';
        csv_data.NumberOfPairs = all_results.number_of_pairs';
        csv_data.OverallDifficulty = all_results.overall_difficulty';
        csv_data.DifficultyCategory = {all_results.metrics.difficulty_category}';
        csv_data.PathLengthFactor = [all_results.metrics.path_length_factor]';
        csv_data.CurvatureFactor = [all_results.metrics.curvature_factor]';
        csv_data.MinClearance = [all_results.metrics.min_clearance]';
        csv_data.AvgObstacleDistance = [all_results.metrics.avg_obstacle_distance]';
        csv_data.ObstacleDensity = [all_results.metrics.obstacle_density]';
        csv_data.NumSegments = [all_results.metrics.num_segments]';
        csv_data.AvgObstacleSize = [all_results.metrics.avg_obstacle_size]';
        csv_data.MinPairDistance = [all_results.metrics.min_pair_distance]';
        csv_data.ConstraintTightness = [all_results.metrics.constraint_tightness]';
        csv_data.PathLength = [all_results.metrics.path_length]';
        csv_data.StraightLineDistance = [all_results.metrics.straight_line_distance]';
        csv_data.AdjustedDifficulty = [all_results.metrics.adjusted_difficulty]';
        
        writetable(csv_data, 'difficulty_analysis_results.csv');
        fprintf('Results also saved to difficulty_analysis_results.csv\n');
    catch
        fprintf('Note: CSV export not available (requires Statistics Toolbox)\n');
    end
end

