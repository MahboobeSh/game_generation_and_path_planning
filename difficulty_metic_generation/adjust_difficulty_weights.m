function adjust_difficulty_weights()
    % ADJUST_DIFFICULTY_WEIGHTS - Interactive script to adjust difficulty weights
    %
    % This script allows you to:
    %   1. Load existing analysis results
    %   2. Adjust weights for different difficulty factors
    %   3. Recalculate difficulties with new weights
    %   4. Compare results side-by-side
    %
    % Usage:
    %   adjust_difficulty_weights()
    
    fprintf('=== Difficulty Weight Adjustment Tool ===\n\n');
    
    % Default weights (from calculate_game_difficulty.m)
    default_weights = struct();
    default_weights.path_length = 0.10;
    default_weights.curvature = 0.12;
    default_weights.clearance = 0.18;
    default_weights.pair_distance = 0.18;
    default_weights.constraint_tightness = 0.15;
    default_weights.distance = 0.10;
    default_weights.density = 0.07;
    default_weights.segments = 0.07;
    default_weights.size = 0.03;
    
    % Check if results file exists
    if exist('difficulty_analysis_results.mat', 'file')
        fprintf('Loading existing analysis results...\n');
        load('difficulty_analysis_results.mat', 'results');
        use_existing = true;
    else
        fprintf('No existing results found. Running full analysis first...\n');
        analyze_game_difficulty_metrics();
        load('difficulty_analysis_results.mat', 'results');
        use_existing = false;
    end
    
    % Display current weights
    fprintf('\nCurrent Default Weights:\n');
    display_weights(default_weights);
    
    % Ask user if they want to adjust weights
    fprintf('\nOptions:\n');
    fprintf('  1. Use default weights and re-analyze\n');
    fprintf('  2. Adjust weights interactively\n');
    fprintf('  3. Load weights from file\n');
    fprintf('  4. Compare two weight configurations\n');
    
    choice = input('Enter choice (1-4): ');
    
    switch choice
        case 1
            % Use defaults
            custom_weights = default_weights;
            fprintf('\nRe-analyzing with default weights...\n');
            analyze_game_difficulty_metrics(custom_weights);
            
        case 2
            % Interactive adjustment
            custom_weights = interactive_weight_adjustment(default_weights);
            fprintf('\nRe-analyzing with adjusted weights...\n');
            analyze_game_difficulty_metrics(custom_weights);
            
        case 3
            % Load from file
            filename = input('Enter weights file name (or press Enter for default): ', 's');
            if isempty(filename)
                filename = 'custom_weights.mat';
            end
            if exist(filename, 'file')
                load(filename, 'weights');
                custom_weights = weights;
                fprintf('\nLoaded weights from %s\n', filename);
                display_weights(custom_weights);
                fprintf('\nRe-analyzing with loaded weights...\n');
                analyze_game_difficulty_metrics(custom_weights);
            else
                fprintf('File not found. Using defaults.\n');
                custom_weights = default_weights;
                analyze_game_difficulty_metrics(custom_weights);
            end
            
        case 4
            % Compare two configurations
            compare_weight_configurations(results, default_weights);
            return;
            
        otherwise
            fprintf('Invalid choice. Using defaults.\n');
            custom_weights = default_weights;
            analyze_game_difficulty_metrics(custom_weights);
    end
    
    % Ask if user wants to save weights
    save_choice = input('\nSave these weights to file? (y/n): ', 's');
    if strcmpi(save_choice, 'y')
        filename = input('Enter filename (or press Enter for custom_weights.mat): ', 's');
        if isempty(filename)
            filename = 'custom_weights.mat';
        end
        weights = custom_weights;
        save(filename, 'weights');
        fprintf('Weights saved to %s\n', filename);
    end
end

function weights = interactive_weight_adjustment(default_weights)
    % Interactive weight adjustment
    
    weights = default_weights;
    
    fprintf('\n=== Interactive Weight Adjustment ===\n');
    fprintf('Enter new values for each weight (or press Enter to keep current value)\n');
    fprintf('Note: Weights should sum to approximately 1.0\n\n');
    
    weight_names = {'path_length', 'curvature', 'clearance', 'pair_distance', ...
                    'constraint_tightness', 'distance', 'density', 'segments', 'size'};
    weight_labels = {'Path Length', 'Curvature', 'Clearance', 'Pair Distance', ...
                     'Constraint Tightness', 'Avg Distance', 'Density', 'Segments', 'Size'};
    
    for i = 1:length(weight_names)
        current_val = weights.(weight_names{i});
        prompt = sprintf('%s [current: %.3f]: ', weight_labels{i}, current_val);
        new_val = input(prompt);
        if ~isempty(new_val) && isnumeric(new_val) && new_val >= 0
            weights.(weight_names{i}) = new_val;
        end
    end
    
    % Display updated weights
    fprintf('\nUpdated Weights:\n');
    display_weights(weights);
    
    % Check sum
    weight_values = [weights.path_length, weights.curvature, weights.clearance, ...
                     weights.pair_distance, weights.constraint_tightness, ...
                     weights.distance, weights.density, weights.segments, weights.size];
    total = sum(weight_values);
    fprintf('\nTotal weight sum: %.3f\n', total);
    if abs(total - 1.0) > 0.1
        normalize = input('Weights do not sum to 1.0. Normalize? (y/n): ', 's');
        if strcmpi(normalize, 'y')
            weight_values = weight_values / sum(weight_values);
            weights.path_length = weight_values(1);
            weights.curvature = weight_values(2);
            weights.clearance = weight_values(3);
            weights.pair_distance = weight_values(4);
            weights.constraint_tightness = weight_values(5);
            weights.distance = weight_values(6);
            weights.density = weight_values(7);
            weights.segments = weight_values(8);
            weights.size = weight_values(9);
            fprintf('Weights normalized.\n');
            display_weights(weights);
        end
    end
end

function display_weights(weights)
    % Display weights in a formatted way
    
    fprintf('  Path Length:         %.3f\n', weights.path_length);
    fprintf('  Curvature:           %.3f\n', weights.curvature);
    fprintf('  Clearance:           %.3f\n', weights.clearance);
    fprintf('  Pair Distance:       %.3f\n', weights.pair_distance);
    fprintf('  Constraint Tightness: %.3f\n', weights.constraint_tightness);
    fprintf('  Avg Distance:        %.3f\n', weights.distance);
    fprintf('  Density:             %.3f\n', weights.density);
    fprintf('  Segments:            %.3f\n', weights.segments);
    fprintf('  Size:                %.3f\n', weights.size);
    weight_values = [weights.path_length, weights.curvature, weights.clearance, ...
                     weights.pair_distance, weights.constraint_tightness, ...
                     weights.distance, weights.density, weights.segments, weights.size];
    fprintf('  Total:               %.3f\n', sum(weight_values));
end

function compare_weight_configurations(results, default_weights)
    % Compare two weight configurations side-by-side
    
    fprintf('\n=== Weight Configuration Comparison ===\n\n');
    
    % Get first configuration
    fprintf('Configuration 1:\n');
    fprintf('  1. Use defaults\n');
    fprintf('  2. Load from file\n');
    fprintf('  3. Enter manually\n');
    choice1 = input('Enter choice: ');
    
    if choice1 == 1
        weights1 = default_weights;
        name1 = 'Default Weights';
    elseif choice1 == 2
        filename = input('Enter weights file name: ', 's');
        load(filename, 'weights');
        weights1 = weights;
        name1 = filename;
    else
        weights1 = interactive_weight_adjustment(default_weights);
        name1 = 'Manual Weights 1';
    end
    
    % Get second configuration
    fprintf('\nConfiguration 2:\n');
    fprintf('  1. Use defaults\n');
    fprintf('  2. Load from file\n');
    fprintf('  3. Enter manually\n');
    choice2 = input('Enter choice: ');
    
    if choice2 == 1
        weights2 = default_weights;
        name2 = 'Default Weights';
    elseif choice2 == 2
        filename = input('Enter weights file name: ', 's');
        load(filename, 'weights');
        weights2 = weights;
        name2 = filename;
    else
        weights2 = interactive_weight_adjustment(default_weights);
        name2 = 'Manual Weights 2';
    end
    
    % Recalculate difficulties for both configurations
    fprintf('\nRecalculating difficulties...\n');
    base_folder = '/home/mahboobe/Desktop/game_generation_and_path_planning/game/';
    folders_to_analyze = {'2pairs/fit', '3pairs/fit', '4pairs/fit'};
    
    difficulties1 = [];
    difficulties2 = [];
    game_names = {};
    
    for folder_idx = 1:length(folders_to_analyze)
        folder_path = fullfile(base_folder, folders_to_analyze{folder_idx});
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
        
        mat_files = dir(fullfile(folder_path, '*.mat'));
        
        for file_idx = 1:length(mat_files)
            file_path = fullfile(folder_path, mat_files(file_idx).name);
            
            try
                data = load(file_path);
                if ~isfield(data, 'path') || isempty(data.path)
                    continue;
                end
                
                if isfield(data, 'number_of_pairs')
                    num_pairs = data.number_of_pairs;
                else
                    num_pairs = number_of_pairs;
                end
                
                % Calculate with both weight sets
                % Pass Start_points and End_points if available
                if isfield(data, 'Start_points') && isfield(data, 'End_points')
                    metrics1 = calculate_game_difficulty_with_weights(...
                        data.path, data.obstacle, data.obstacle_radious, ...
                        data.X_s, data.X_e, data.x_range, data.y_range, num_pairs, weights1, ...
                        data.Start_points, data.End_points);
                    
                    metrics2 = calculate_game_difficulty_with_weights(...
                        data.path, data.obstacle, data.obstacle_radious, ...
                        data.X_s, data.X_e, data.x_range, data.y_range, num_pairs, weights2, ...
                        data.Start_points, data.End_points);
                else
                    metrics1 = calculate_game_difficulty_with_weights(...
                        data.path, data.obstacle, data.obstacle_radious, ...
                        data.X_s, data.X_e, data.x_range, data.y_range, num_pairs, weights1);
                    
                    metrics2 = calculate_game_difficulty_with_weights(...
                        data.path, data.obstacle, data.obstacle_radious, ...
                        data.X_s, data.X_e, data.x_range, data.y_range, num_pairs, weights2);
                end
                
                difficulties1(end+1) = metrics1.overall_difficulty;
                difficulties2(end+1) = metrics2.overall_difficulty;
                game_names{end+1} = mat_files(file_idx).name;
                
            catch
                continue;
            end
        end
    end
    
    % Create comparison visualization
    figure('Position', [100, 100, 1400, 800], 'Name', 'Weight Configuration Comparison');
    
    % Scatter plot comparison
    subplot(2, 2, 1);
    scatter(difficulties1, difficulties2, 50, 'filled', 'MarkerFaceAlpha', 0.6);
    hold on;
    plot([0 1], [0 1], 'r--', 'LineWidth', 2);
    xlabel(sprintf('Difficulty (%s)', name1));
    ylabel(sprintf('Difficulty (%s)', name2));
    title('Difficulty Comparison');
    grid on;
    axis equal;
    xlim([0 1]);
    ylim([0 1]);
    
    % Difference histogram
    subplot(2, 2, 2);
    diff = difficulties2 - difficulties1;
    histogram(diff, 30, 'FaceColor', [0.6 0.2 0.8]);
    xlabel('Difference (Config 2 - Config 1)');
    ylabel('Frequency');
    title('Difference Distribution');
    grid on;
    hold on;
    plot([0 0], ylim, 'r--', 'LineWidth', 2);
    
    % Distribution comparison
    subplot(2, 2, 3);
    histogram(difficulties1, 20, 'FaceColor', [0.2 0.6 0.8], 'FaceAlpha', 0.6, 'DisplayName', name1);
    hold on;
    histogram(difficulties2, 20, 'FaceColor', [0.8 0.4 0.2], 'FaceAlpha', 0.6, 'DisplayName', name2);
    xlabel('Overall Difficulty');
    ylabel('Frequency');
    title('Difficulty Distribution Comparison');
    legend;
    grid on;
    
    % Statistics table
    subplot(2, 2, 4);
    axis off;
    stats_text = {
        sprintf('Configuration 1: %s', name1);
        sprintf('  Mean:   %.4f', mean(difficulties1));
        sprintf('  Median: %.4f', median(difficulties1));
        sprintf('  Std:    %.4f', std(difficulties1));
        '';
        sprintf('Configuration 2: %s', name2);
        sprintf('  Mean:   %.4f', mean(difficulties2));
        sprintf('  Median: %.4f', median(difficulties2));
        sprintf('  Std:    %.4f', std(difficulties2));
        '';
        sprintf('Difference (Config 2 - Config 1):');
        sprintf('  Mean:   %.4f', mean(diff));
        sprintf('  Std:    %.4f', std(diff));
        sprintf('  Max:    %.4f', max(diff));
        sprintf('  Min:    %.4f', min(diff));
    };
    text(0.1, 0.5, stats_text, 'FontSize', 10, 'FontFamily', 'monospace', ...
         'VerticalAlignment', 'middle');
    
    sgtitle('Weight Configuration Comparison', 'FontSize', 14, 'FontWeight', 'bold');
    
    % Display statistics
    fprintf('\n=== Comparison Statistics ===\n\n');
    fprintf('Configuration 1 (%s):\n', name1);
    fprintf('  Mean:   %.4f\n', mean(difficulties1));
    fprintf('  Median: %.4f\n', median(difficulties1));
    fprintf('  Std:    %.4f\n', std(difficulties1));
    
    fprintf('\nConfiguration 2 (%s):\n', name2);
    fprintf('  Mean:   %.4f\n', mean(difficulties2));
    fprintf('  Median: %.4f\n', median(difficulties2));
    fprintf('  Std:    %.4f\n', std(difficulties2));
    
    fprintf('\nDifference (Config 2 - Config 1):\n');
    fprintf('  Mean:   %.4f\n', mean(diff));
    fprintf('  Std:    %.4f\n', std(diff));
    fprintf('  Max:    %.4f\n', max(diff));
    fprintf('  Min:    %.4f\n', min(diff));
    
    % Correlation
    correlation = corrcoef(difficulties1, difficulties2);
    fprintf('\nCorrelation: %.4f\n', correlation(1, 2));
end

function difficulty_metrics = calculate_game_difficulty_with_weights(path, obstacles, obstacle_radii, X_s, X_e, x_range, y_range, number_of_pairs, custom_weights)
    % Calculate difficulty with custom weights
    difficulty_metrics = calculate_game_difficulty(path, obstacles, obstacle_radii, X_s, X_e, x_range, y_range, number_of_pairs);
    
    % Recalculate overall_difficulty with custom weights
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
    
    weights = custom_weights;
    
    difficulty_metrics.overall_difficulty = weights.path_length * path_length_norm + ...
                                            weights.curvature * curvature_norm + ...
                                            weights.clearance * clearance_norm + ...
                                            weights.pair_distance * pair_distance_norm + ...
                                            weights.constraint_tightness * constraint_tightness_norm + ...
                                            weights.distance * distance_norm + ...
                                            weights.density * density_norm + ...
                                            weights.segments * segments_norm + ...
                                            weights.size * size_norm;
    
    if difficulty_metrics.overall_difficulty < 0.33
        difficulty_metrics.difficulty_category = 'Easy';
    elseif difficulty_metrics.overall_difficulty < 0.67
        difficulty_metrics.difficulty_category = 'Medium';
    else
        difficulty_metrics.difficulty_category = 'Hard';
    end
end

