function list_games_by_path_length()
    % LIST_GAMES_BY_PATH_LENGTH - List all games in fit folders with their path lengths
    %
    % This script scans all games in game/2pairs/fit/, game/3pairs/fit/, and 
    % game/4pairs/fit/ folders, calculates path lengths, and displays:
    %   - A table listing all games with their path lengths
    %   - Distribution plots (histogram, boxplot) grouped by number of pairs
    %   - Summary statistics
    %
    % Usage:
    %   list_games_by_path_length()
    
    % Base folder for games
    base_folder = '/home/mahboobe/Desktop/game_generation_and_path_planning/new_games/';
    
    % Folders to scan
    folders_to_scan = {'3pairs/fit', '4pairs/fit', '5pairs/fit'};
    
    % Storage for all game data
    all_games = struct('name', {}, 'pairs', {}, 'set_number', {}, 'path_length', {}, 'file_path', {});
    
    fprintf('=== Scanning games and calculating path lengths ===\n\n');
    
    % Process each folder
    for folder_idx = 1:length(folders_to_scan)
        folder_path = fullfile(base_folder, folders_to_scan{folder_idx});
        
        if ~exist(folder_path, 'dir')
            fprintf('Warning: Folder not found: %s\n', folder_path);
            continue;
        end
        
        % Extract number of pairs from folder name (e.g., "3pairs/fit" -> 3)
        folder_name = folders_to_scan{folder_idx};
        pairs_match = regexp(folder_name, '(\d+)pairs', 'tokens');
        if ~isempty(pairs_match)
            pairs_num = str2double(pairs_match{1}{1});
        else
            pairs_num = NaN;
        end
        
        % Get all .mat files in folder
        files = dir(fullfile(folder_path, '*.mat'));
        
        fprintf('Scanning %s (%d files)...\n', folders_to_scan{folder_idx}, length(files));
        
        for file_idx = 1:length(files)
            filename = files(file_idx).name;
            file_path = fullfile(folder_path, filename);
            
            try
                % Load game data
                data = load(file_path);
                
                % Extract set number from filename (e.g., "set_9_3pairs.mat" -> 9)
                set_num_str = regexp(filename, 'set_(\d+)_', 'tokens');
                if ~isempty(set_num_str)
                    set_number = str2double(set_num_str{1}{1});
                else
                    set_number = NaN;
                end
                
                % Get path (prefer curve over path)
                if isfield(data, 'curve') && ~isempty(data.curve)
                    path_to_use = data.curve;
                elseif isfield(data, 'path') && ~isempty(data.path)
                    path_to_use = data.path;
                else
                    fprintf('  Warning: No path found in %s\n', filename);
                    continue;
                end
                
                % Calculate path length
                if size(path_to_use, 1) < 2
                    fprintf('  Warning: Path too short in %s\n', filename);
                    continue;
                end
                
                diffs = diff(path_to_use, 1, 1);
                path_length = sum(sqrt(sum(diffs.^2, 2)));
                
                % Store game info
                idx = length(all_games) + 1;
                all_games(idx).name = filename;
                all_games(idx).pairs = pairs_num;
                all_games(idx).set_number = set_number;
                all_games(idx).path_length = path_length;
                all_games(idx).file_path = file_path;
                
            catch ME
                fprintf('  Error loading %s: %s\n', filename, ME.message);
            end
        end
    end
    
    if isempty(all_games)
        error('No games found!');
    end
    
    fprintf('\n=== Found %d games ===\n\n', length(all_games));
    
    % Sort by pairs, then by path length
    [~, sort_idx] = sortrows([cell2mat({all_games.pairs})', [all_games.path_length]'], [1, 2]);
    all_games = all_games(sort_idx);
    
    % Display table
    display_game_table(all_games);
    
    % Create visualizations
    create_distribution_plots(all_games);
    
    % Display summary statistics
    display_summary_stats(all_games);
    
    fprintf('\n=== Done ===\n');
end

function display_game_table(all_games)
    % Display games in a formatted table
    
    fprintf('=== GAME LIST (Sorted by Pairs, then Path Length) ===\n\n');
    fprintf('%-30s %8s %12s %10s\n', 'Game Name', 'Pairs', 'Set #', 'Length (cm)');
    fprintf('%s\n', repmat('-', 1, 70));
    
    for i = 1:length(all_games)
        g = all_games(i);
        set_str = sprintf('%d', g.set_number);
        if isnan(g.set_number)
            set_str = 'N/A';
        end
        fprintf('%-30s %8d %12s %10.2f\n', g.name, g.pairs, set_str, g.path_length);
    end
    fprintf('\n');
end

function create_distribution_plots(all_games)
    % Create distribution plots
    
    % Extract unique pair counts and data dynamically
    unique_pairs = unique([all_games.pairs]);
    pairs_data = cell(length(unique_pairs), 1);
    for i = 1:length(unique_pairs)
        pairs_data{i} = [all_games([all_games.pairs] == unique_pairs(i)).path_length];
    end
    
    % Create figure
    figure('Position', [100, 100, 1400, 900], 'Name', 'Path Length Distribution Analysis');
    
    % Subplot 1: Histogram (overlaid)
    subplot(2, 3, 1);
    hold on;
    colors = lines(length(unique_pairs));
    for i = 1:length(unique_pairs)
        if ~isempty(pairs_data{i})
            histogram(pairs_data{i}, 'BinWidth', 5, 'FaceAlpha', 0.6, ...
                'DisplayName', sprintf('%d pairs', unique_pairs(i)), ...
                'FaceColor', colors(i,:));
        end
    end
    xlabel('Path Length (cm)');
    ylabel('Frequency');
    title('Path Length Distribution (Overlaid)');
    legend('Location', 'best');
    grid on;
    
    % Subplot 2: Histogram (separate)
    subplot(2, 3, 2);
    all_lengths = [all_games.path_length];
    all_pairs = [all_games.pairs];
    histogram2(all_pairs, all_lengths, 'BinWidth', [0.5, 5], 'DisplayStyle', 'bar3');
    xlabel('Number of Pairs');
    ylabel('Path Length (cm)');
    zlabel('Frequency');
    title('Path Length Distribution (2D Histogram)');
    grid on;
    
    % Subplot 3: Boxplot
    subplot(2, 3, 3);
    % Prepare data and grouping variable for boxplot
    all_lengths_box = [];
    all_groups_box = {};
    
    for i = 1:length(unique_pairs)
        if ~isempty(pairs_data{i})
            all_lengths_box = [all_lengths_box, pairs_data{i}(:)'];
            all_groups_box = [all_groups_box, repmat({sprintf('%d pairs', unique_pairs(i))}, 1, length(pairs_data{i}))];
        end
    end
    
    if ~isempty(all_lengths_box)
        boxplot(all_lengths_box, all_groups_box);
    end
    ylabel('Path Length (cm)');
    title('Path Length Distribution (Boxplot)');
    grid on;
    
    % Subplot 4: Scatter plot (Pairs vs Length)
    subplot(2, 3, 4);
    scatter([all_games.pairs], [all_games.path_length], 50, 'filled');
    xlabel('Number of Pairs');
    ylabel('Path Length (cm)');
    title('Path Length vs Number of Pairs');
    grid on;
    unique_pairs = unique([all_games.pairs]);
    if ~isempty(unique_pairs)
        xlim([min(unique_pairs)-0.5, max(unique_pairs)+0.5]);
        xticks(unique_pairs);
    end
    
    % Subplot 5: Cumulative distribution
    subplot(2, 3, 5);
    hold on;
    colors = lines(length(unique_pairs));
    for i = 1:length(unique_pairs)
        if ~isempty(pairs_data{i})
            [f, x] = ecdf(pairs_data{i});
            plot(x, f, 'LineWidth', 2, 'DisplayName', sprintf('%d pairs', unique_pairs(i)), ...
                'Color', colors(i,:));
        end
    end
    xlabel('Path Length (cm)');
    ylabel('Cumulative Probability');
    title('Cumulative Distribution Function');
    legend('Location', 'best');
    grid on;
    
    % Subplot 6: Violin plot approximation (using histogram with jitter)
    subplot(2, 3, 6);
    hold on;
    unique_pairs_list = unique([all_games.pairs]);
    pair_colors = lines(length(unique_pairs_list));
    for p_idx = 1:length(unique_pairs_list)
        p = unique_pairs_list(p_idx);
        pairs_data = [all_games([all_games.pairs] == p).path_length];
        if ~isempty(pairs_data)
            y_pos = p + 0.1 * randn(size(pairs_data));
            scatter(pairs_data, y_pos, 30, 'filled', 'DisplayName', sprintf('%d pairs', p), ...
                'MarkerFaceColor', pair_colors(p_idx,:));
        end
    end
    xlabel('Path Length (cm)');
    ylabel('Number of Pairs');
    title('Path Length Distribution (Scatter)');
    if ~isempty(unique_pairs_list)
        ylim([min(unique_pairs_list)-0.5, max(unique_pairs_list)+0.5]);
        yticks(unique_pairs_list);
    end
    legend('Location', 'best');
    grid on;
    
    sgtitle('Path Length Distribution Analysis', 'FontSize', 14, 'FontWeight', 'bold');
end

function display_summary_stats(all_games)
    % Display summary statistics
    
    fprintf('=== SUMMARY STATISTICS ===\n\n');
    
    % Overall statistics
    all_lengths = [all_games.path_length];
    fprintf('OVERALL:\n');
    fprintf('  Total games: %d\n', length(all_games));
    fprintf('  Mean path length: %.2f cm\n', mean(all_lengths));
    fprintf('  Median path length: %.2f cm\n', median(all_lengths));
    fprintf('  Std deviation: %.2f cm\n', std(all_lengths));
    fprintf('  Min path length: %.2f cm (%s)\n', min(all_lengths), all_games(all_lengths == min(all_lengths)).name);
    fprintf('  Max path length: %.2f cm (%s)\n', max(all_lengths), all_games(all_lengths == max(all_lengths)).name);
    fprintf('  Range: %.2f cm\n\n', max(all_lengths) - min(all_lengths));
    
    % Statistics by pairs
    unique_pairs = unique([all_games.pairs]);
    for pairs = unique_pairs
        games_with_pairs = all_games([all_games.pairs] == pairs);
        if isempty(games_with_pairs)
            continue;
        end
        
        lengths = [games_with_pairs.path_length];
        fprintf('%d PAIRS (%d games):\n', pairs, length(games_with_pairs));
        fprintf('  Mean: %.2f cm\n', mean(lengths));
        fprintf('  Median: %.2f cm\n', median(lengths));
        fprintf('  Std: %.2f cm\n', std(lengths));
        fprintf('  Min: %.2f cm\n', min(lengths));
        fprintf('  Max: %.2f cm\n', max(lengths));
        fprintf('  Range: %.2f cm\n\n', max(lengths) - min(lengths));
    end
    
    % Percentiles
    fprintf('PERCENTILES (Overall):\n');
    percentiles = [10, 25, 50, 75, 90, 95, 99];
    for p = percentiles
        fprintf('  %d%%: %.2f cm\n', p, prctile(all_lengths, p));
    end
    fprintf('\n');
end
