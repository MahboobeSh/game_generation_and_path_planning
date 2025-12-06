% SELECT_GAMES_FOR_STUDY - Uses Extended Steering Law (Minimal Rehab Metrics)
%
% STRATEGY: TIGHT CLUSTERING WITH MAXIMUM SEPARATION
% - EASY cluster: Bottom 15% of games (tight group of easiest)
% - MEDIUM cluster: 40-60th percentile (tight group around median)
% - HARD cluster: Top 15% of games (tight group of hardest)
% - Games within each cluster are CLOSE together (similar difficulty)
% - GAPS between clusters ensure maximum separation
%
% This approach ensures:
%   1. Within-group consistency (low variance within Easy, Medium, Hard)
%   2. Between-group separation (clear gaps between categories)
%   3. Better statistical power for detecting difficulty effects

% --- CONFIGURATION ---
base_folder = 'C:\Users\Mahbo\OneDrive - University of Calgary\code\game_creation_and_fits\new_games\selected_games_2';
base_folder = '/home/mahboobe/Desktop/game_generation_and_path_planning/new_games/selected_games_3';
base_folder = '/home/mahboobe/Desktop/game_generation_and_path_planning/new_games/final_games';
% base_folder = '/home/mahboobe/Desktop/game_generation_and_path_planning/new_games/new_games';
folders_to_scan = {'3pairs/fit', '4pairs/fit', '5pairs/fit'};
% folders_to_scan = {'5pairs/fit',};

% RELAXED Length Constraints
target_len_GLOBAL = 80; 
tolerance_cm = 0.01 + 0.1; 

min_len = target_len_GLOBAL - tolerance_cm; % ~70 cm
max_len = target_len_GLOBAL + tolerance_cm; % ~90 cm

% Storage - Updated for Extended Steering Law metrics
all_games = struct('name', {}, 'pairs', {}, 'SteeringIndex', {}, ...
    'K_TotalRotation', {}, 'CompositeScore', {}, 'PathLength', {});

fprintf('Scanning games and calculating Composite Scores (Extended Steering Law)...\n');

% --- 1. LOAD AND PROCESS ---
for f = 1:length(folders_to_scan)
    full_path = fullfile(base_folder, folders_to_scan{f});
    files = dir(fullfile(full_path, '*.mat'));
    
    for i = 1:length(files)
        try
            data = load(fullfile(full_path, files(i).name));
            
            % Determine Pair Count
            if isfield(data, 'number_of_pairs')
                np = data.number_of_pairs;
            else
                np = 3;
            end
            
            % Get Path (prefer equalized curve > curve > A* path)
            if isfield(data, 'curve_equalized') && ~isempty(data.curve_equalized)
                path = data.curve_equalized;
            elseif isfield(data, 'curve') && ~isempty(data.curve)
                path = data.curve;
            elseif isfield(data, 'path') && ~isempty(data.path)
                path = data.path;
            else
                continue;
            end
            
            % Length Check
            diffs = diff(path);
            L = sum(sqrt(sum(diffs.^2, 2)));
            
            if L < min_len || L > max_len
                fprintf('  Skipping %s (length %.2f cm)\n', files(i).name, L);
                continue; % Reject games that are too short/long
            end
            
            % Calculate Metrics using MINIMAL version (Extended Steering Law)
            m = calculate_rehab_metrics_minimal(path, data.obstacle, data.obstacle_radious);
            
            % EXTRACT COMPOSITE SCORE
            if isfield(m, 'CompositeScore')
                comp_val = m.CompositeScore;
            else
                warning('CompositeScore missing for %s', files(i).name);
                comp_val = 0;
            end
            
            % Store
            idx = length(all_games) + 1;
            all_games(idx).name = files(i).name;
            all_games(idx).pairs = np;
            all_games(idx).SteeringIndex = m.SteeringIndex;
            all_games(idx).K_TotalRotation = m.K_TotalRotation;
            all_games(idx).CompositeScore = comp_val;
            all_games(idx).PathLength = m.PathLength;
            
        catch ME
            fprintf('  Error processing %s: %s\n', files(i).name, ME.message);
        end
    end
end

if isempty(all_games)
    error('No games found.');
end
fprintf('Found %d valid games (length range: %.1f-%.1f cm).\n', ...
    length(all_games), min_len, max_len);

% --- 2. CALCULATE SEPARATION ---
comp_scores = [all_games.CompositeScore];
[sorted_scores, sort_idx] = sort(comp_scores);
sorted_games = all_games(sort_idx);

% Define Thresholds (33% and 66% percentile)
score_33 = prctile(comp_scores, 33);
score_66 = prctile(comp_scores, 66);

% Check total games available
total_games = length(all_games);
min_games_required = 12;
games_per_category = 4;

fprintf('Total valid games: %d\n', total_games);

% Adjust clustering strategy based on number of games
if total_games >= min_games_required && total_games <= 15
    % With 12-15 games, directly split into thirds to ensure 4 per category
    fprintf('Using direct split for %d games to ensure 4 per category\n\n', total_games);
    
    % Easy: indices 1-4 (first 4 sorted games)
    easy_cluster = sorted_games(1:4);
    % Hard: indices end-3:end (last 4 sorted games)
    hard_cluster = sorted_games(end-3:end);
    % Medium: everything in between
    medium_cluster = sorted_games(5:end-4);
    
    fprintf('Cluster Strategy (Direct split):\n');
    fprintf('  EASY cluster: %d games (indices 1-4), scores %.2f - %.2f\n', ...
        length(easy_cluster), min([easy_cluster.CompositeScore]), max([easy_cluster.CompositeScore]));
    fprintf('  MEDIUM cluster: %d games (indices 5-%d), scores %.2f - %.2f\n', ...
        length(medium_cluster), total_games-4, min([medium_cluster.CompositeScore]), max([medium_cluster.CompositeScore]));
    fprintf('  HARD cluster: %d games (indices %d-%d), scores %.2f - %.2f\n\n', ...
        length(hard_cluster), total_games-3, total_games, min([hard_cluster.CompositeScore]), max([hard_cluster.CompositeScore]));
    
elseif total_games > 15
    % With more games, use tight percentile clusters with gaps
    fprintf('Sufficient games available - using tight clusters with gaps\n\n');
    thresh_easy_max = prctile(comp_scores, 15);      % Bottom 15%
    thresh_med_min = prctile(comp_scores, 40);       % Medium start
    thresh_med_max = prctile(comp_scores, 60);       % Medium end
    thresh_hard_min = prctile(comp_scores, 85);      % Top 15%
    
    % Categorize games into clusters
    easy_cluster = sorted_games(comp_scores(sort_idx) <= thresh_easy_max);
    medium_cluster = sorted_games(comp_scores(sort_idx) >= thresh_med_min & comp_scores(sort_idx) <= thresh_med_max);
    hard_cluster = sorted_games(comp_scores(sort_idx) >= thresh_hard_min);
    
    fprintf('Cluster Strategy (Percentile-based):\n');
    fprintf('  EASY cluster (bottom 15%%): %d games, scores %.2f - %.2f\n', ...
        length(easy_cluster), min([easy_cluster.CompositeScore]), max([easy_cluster.CompositeScore]));
    fprintf('  MEDIUM cluster (40-60%%ile): %d games, scores %.2f - %.2f\n', ...
        length(medium_cluster), min([medium_cluster.CompositeScore]), max([medium_cluster.CompositeScore]));
    fprintf('  HARD cluster (top 15%%): %d games, scores %.2f - %.2f\n\n', ...
        length(hard_cluster), min([hard_cluster.CompositeScore]), max([hard_cluster.CompositeScore]));
else
    % Fewer than 12 games - use thirds split
    fprintf('WARNING: Only %d games available (need at least %d for %d per category)\n', ...
        total_games, min_games_required, games_per_category);
    fprintf('Will select as many as possible from each cluster.\n\n');
    
    thresh_easy_max = prctile(comp_scores, 33);
    thresh_med_min = prctile(comp_scores, 34);
    thresh_med_max = prctile(comp_scores, 67);
    thresh_hard_min = prctile(comp_scores, 68);
    
    easy_cluster = sorted_games(comp_scores(sort_idx) <= thresh_easy_max);
    medium_cluster = sorted_games(comp_scores(sort_idx) >= thresh_med_min & comp_scores(sort_idx) <= thresh_med_max);
    hard_cluster = sorted_games(comp_scores(sort_idx) >= thresh_hard_min);
    
    fprintf('Cluster Strategy (Best effort):\n');
    fprintf('  EASY cluster: %d games, scores %.2f - %.2f\n', ...
        length(easy_cluster), min([easy_cluster.CompositeScore]), max([easy_cluster.CompositeScore]));
    fprintf('  MEDIUM cluster: %d games, scores %.2f - %.2f\n', ...
        length(medium_cluster), min([medium_cluster.CompositeScore]), max([medium_cluster.CompositeScore]));
    fprintf('  HARD cluster: %d games, scores %.2f - %.2f\n\n', ...
        length(hard_cluster), min([hard_cluster.CompositeScore]), max([hard_cluster.CompositeScore]));
end

% --- 3. VISUALIZATION ---
figure('Position', [50, 50, 1600, 900], 'Name', 'Game Selection - Extended Steering Law');

% SUBPLOT 1: The Difficulty Map (Steering vs Curvature)
subplot(2, 3, 1);
hold on;
x_vals = [all_games.SteeringIndex];
y_vals = [all_games.K_TotalRotation];

% Auto-Scale Map Zones for TIGHT clusters
x_15 = prctile(x_vals, 15);  % Easy cluster boundary
x_40 = prctile(x_vals, 40);  % Medium cluster start
x_60 = prctile(x_vals, 60);  % Medium cluster end
x_85 = prctile(x_vals, 85);  % Hard cluster boundary
x_max = max(x_vals) * 1.1;
y_15 = prctile(y_vals, 15); 
y_40 = prctile(y_vals, 40); 
y_60 = prctile(y_vals, 60); 
y_85 = prctile(y_vals, 85); 
y_max = max(y_vals) * 1.1;

% Draw TIGHT Zones with gaps
fill([0 0 x_15 x_15], [0 y_15 y_15 0], [0.8 1 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.3); % Easy cluster
fill([x_40 x_40 x_60 x_60], [y_40 y_60 y_60 y_40], [1 1 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.3); % Medium cluster
fill([x_85 x_85 x_max x_max], [y_85 y_max y_max y_85], [1 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.3); % Hard cluster

gscatter(x_vals, y_vals, [all_games.pairs], 'bgr', 'o+^', 8);
text(x_vals, y_vals, {all_games.name}, 'VerticalAlignment', 'bottom', ...
    'HorizontalAlignment', 'right', 'FontSize', 8, 'Interpreter', 'none');

title('Difficulty Components (Extended Steering Law)', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Steering Index (Constraint Difficulty)', 'FontSize', 11);
ylabel('K - Total Rotation (rad)', 'FontSize', 11);
legend('3 pairs', '4 pairs', '5 pairs', 'Location', 'best');
grid on; 
axis([0 x_max 0 y_max]);

% SUBPLOT 2: Composite Score Separation (Bar Chart)
subplot(2, 3, 2);
hold on;

% Define cluster boundaries
thresh_easy_max = prctile(comp_scores, 15);
thresh_med_min = prctile(comp_scores, 40);
thresh_med_max = prctile(comp_scores, 60);
thresh_hard_min = prctile(comp_scores, 85);

% Color code bars based on cluster thresholds
for k = 1:length(sorted_scores)
    score = sorted_scores(k);
    if score <= thresh_easy_max
        bar(k, score, 'FaceColor', [0.2 0.8 0.2]); % Green (Easy cluster)
    elseif score >= thresh_med_min && score <= thresh_med_max
        bar(k, score, 'FaceColor', [0.9 0.9 0.2]); % Yellow (Medium cluster)
    elseif score >= thresh_hard_min
        bar(k, score, 'FaceColor', [0.8 0.2 0.2]); % Red (Hard cluster)
    else
        bar(k, score, 'FaceColor', [0.7 0.7 0.7]); % Gray (Gap)
    end
end

yline(thresh_easy_max, '--g', 'Easy Cluster Max (15%ile)', 'LineWidth', 2);
yline(thresh_med_min, '--', 'Color', [0.8 0.8 0], 'LineWidth', 1.5, 'Label', 'Med Min (40%ile)');
yline(thresh_med_max, '--', 'Color', [0.8 0.8 0], 'LineWidth', 1.5, 'Label', 'Med Max (60%ile)');
yline(thresh_hard_min, '--r', 'Hard Cluster Min (85%ile)', 'LineWidth', 2);

title('Composite Scores with Tight Clusters & Gaps', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Game Rank (Sorted)', 'FontSize', 11);
ylabel('Composite Difficulty Score (ID)', 'FontSize', 11);
grid on;
legend({'Easy', 'Medium', 'Hard', 'Gap'}, 'Location', 'northwest');

% Add Labels to Top/Bottom 3 for easy reading
num_g = length(sorted_scores);
if num_g >= 3
    text(1:3, sorted_scores(1:3), {sorted_games(1:3).name}, 'Rotation', 90, ...
        'HorizontalAlignment', 'left', 'Interpreter', 'none', 'FontSize', 8);
    text(num_g-2:num_g, sorted_scores(end-2:end), {sorted_games(end-2:end).name}, ...
        'Rotation', 90, 'HorizontalAlignment', 'right', 'Interpreter', 'none', 'FontSize', 8);
end

% SUBPLOT 3: Histogram of Composite Scores with cluster boundaries
subplot(2, 3, 3);
histogram(comp_scores, 15, 'FaceColor', [0.5 0.7 0.9], 'EdgeColor', 'k');
hold on;
% Show cluster boundaries
xline(prctile(comp_scores, 15), '--g', 'Easy Max', 'LineWidth', 2, 'LabelVerticalAlignment', 'bottom');
xline(prctile(comp_scores, 40), '--y', 'Med Min', 'LineWidth', 2, 'LabelVerticalAlignment', 'bottom');
xline(prctile(comp_scores, 60), '--y', 'Med Max', 'LineWidth', 2, 'LabelVerticalAlignment', 'top');
xline(prctile(comp_scores, 85), '--r', 'Hard Min', 'LineWidth', 2, 'LabelVerticalAlignment', 'top');
xlabel('Composite Score (ID)', 'FontSize', 11);
ylabel('Number of Games', 'FontSize', 11);
title('Difficulty Distribution with Cluster Boundaries', 'FontSize', 12, 'FontWeight', 'bold');
grid on;

% SUBPLOT 4: Games by Pairs and Difficulty (using cluster boundaries)
subplot(2, 3, 4);
pairs_vals = [all_games.pairs];
unique_pairs = unique(pairs_vals);
colors_cat = [0.2 0.8 0.2; 0.9 0.9 0.2; 0.8 0.2 0.2]; % Green, Yellow, Red

% Define cluster boundaries
thresh_easy_max = prctile(comp_scores, 15);
thresh_med_min = prctile(comp_scores, 40);
thresh_med_max = prctile(comp_scores, 60);
thresh_hard_min = prctile(comp_scores, 85);

hold on;
for p = unique_pairs
    pair_games = all_games(pairs_vals == p);
    pair_scores = [pair_games.CompositeScore];
    
    easy_count = sum(pair_scores <= thresh_easy_max);
    med_count = sum(pair_scores >= thresh_med_min & pair_scores <= thresh_med_max);
    hard_count = sum(pair_scores >= thresh_hard_min);
    
    x_pos = find(unique_pairs == p);
    bar(x_pos, easy_count, 'FaceColor', colors_cat(1,:), 'BarWidth', 0.8);
    bar(x_pos, med_count, 'FaceColor', colors_cat(2,:), 'BarWidth', 0.8, 'BaseValue', easy_count);
    bar(x_pos, hard_count, 'FaceColor', colors_cat(3,:), 'BarWidth', 0.8, 'BaseValue', easy_count+med_count);
end

xticks(1:length(unique_pairs));
xticklabels(arrayfun(@(x) sprintf('%d pairs', x), unique_pairs, 'UniformOutput', false));
ylabel('Number of Games', 'FontSize', 11);
title('Games by Pair Count & Cluster', 'FontSize', 12, 'FontWeight', 'bold');
legend({'Easy Cluster', 'Medium Cluster', 'Hard Cluster'}, 'Location', 'best');
grid on;

% SUBPLOT 5: Path Length vs Difficulty
subplot(2, 3, 5);
path_lengths = [all_games.PathLength];
scatter(comp_scores, path_lengths, 50, [all_games.pairs], 'filled', 'MarkerEdgeColor', 'k');
colormap(gca, 'jet');
cb = colorbar;
cb.Label.String = 'Number of Pairs';
xlabel('Composite Score (ID)', 'FontSize', 11);
ylabel('Path Length (cm)', 'FontSize', 11);
title('Path Length vs Difficulty', 'FontSize', 12, 'FontWeight', 'bold');
grid on;

% SUBPLOT 6: Box plot of metrics by difficulty cluster
subplot(2, 3, 6);
thresh_easy_max = prctile(comp_scores, 15);
thresh_med_min = prctile(comp_scores, 40);
thresh_med_max = prctile(comp_scores, 60);
thresh_hard_min = prctile(comp_scores, 85);

difficulty_cat = cell(size(comp_scores));
for i = 1:length(comp_scores)
    if comp_scores(i) <= thresh_easy_max
        difficulty_cat{i} = 'Easy';
    elseif comp_scores(i) >= thresh_med_min && comp_scores(i) <= thresh_med_max
        difficulty_cat{i} = 'Medium';
    elseif comp_scores(i) >= thresh_hard_min
        difficulty_cat{i} = 'Hard';
    else
        difficulty_cat{i} = 'Gap';
    end
end

boxplot(comp_scores, difficulty_cat, 'Colors', 'k');
ylabel('Composite Score (ID)', 'FontSize', 11);
title('Score Distribution by Cluster (with Gaps)', 'FontSize', 12, 'FontWeight', 'bold');
grid on;

% --- 4. PRINT SUMMARY ---
fprintf('\n========================================\n');
fprintf('CLUSTERING SUMMARY (Extended Steering Law)\n');
fprintf('========================================\n');
fprintf('Total games analyzed: %d\n', length(all_games));
fprintf('Path length range: %.1f - %.1f cm\n\n', min_len, max_len);

% Define cluster boundaries
thresh_easy_max = prctile(comp_scores, 15);
thresh_med_min = prctile(comp_scores, 40);
thresh_med_max = prctile(comp_scores, 60);
thresh_hard_min = prctile(comp_scores, 85);

fprintf('TIGHT CLUSTER BOUNDARIES:\n');
fprintf('  EASY cluster:   scores <= %.2f (bottom 15%%)\n', thresh_easy_max);
fprintf('  GAP:            scores %.2f - %.2f\n', thresh_easy_max, thresh_med_min);
fprintf('  MEDIUM cluster: scores %.2f - %.2f (40-60%%ile)\n', thresh_med_min, thresh_med_max);
fprintf('  GAP:            scores %.2f - %.2f\n', thresh_med_max, thresh_hard_min);
fprintf('  HARD cluster:   scores >= %.2f (top 15%%)\n\n', thresh_hard_min);

% Calculate separation statistics for clusters
easy_scores = comp_scores(comp_scores <= thresh_easy_max);
med_scores = comp_scores(comp_scores >= thresh_med_min & comp_scores <= thresh_med_max);
hard_scores = comp_scores(comp_scores >= thresh_hard_min);

if ~isempty(easy_scores) && ~isempty(hard_scores)
    separation_factor = mean(hard_scores) / mean(easy_scores);
    fprintf('CLUSTER STATISTICS:\n');
    fprintf('  Easy cluster: %d games, mean = %.2f, std = %.2f\n', ...
        length(easy_scores), mean(easy_scores), std(easy_scores));
    if ~isempty(med_scores)
        fprintf('  Medium cluster: %d games, mean = %.2f, std = %.2f\n', ...
            length(med_scores), mean(med_scores), std(med_scores));
    end
    fprintf('  Hard cluster: %d games, mean = %.2f, std = %.2f\n', ...
        length(hard_scores), mean(hard_scores), std(hard_scores));
    fprintf('  Separation Factor (Hard/Easy): %.2f x\n\n', separation_factor);
end

fprintf('========================================\n');
fprintf('TOP 5 HARDEST GAMES\n');
fprintf('========================================\n');
fprintf('%-35s %8s %10s %10s %6s\n', 'Game', 'Score', 'Steering', 'K (rad)', 'Pairs');
fprintf('------------------------------------------------------------------------\n');
for k = length(sorted_games):-1:max(1, length(sorted_games)-4)
    g = sorted_games(k);
    fprintf('%-35s %8.2f %10.2f %10.4f %6d\n', ...
        g.name, g.CompositeScore, g.SteeringIndex, g.K_TotalRotation, g.pairs);
end

fprintf('\n========================================\n');
fprintf('TOP 5 EASIEST GAMES\n');
fprintf('========================================\n');
fprintf('%-35s %8s %10s %10s %6s\n', 'Game', 'Score', 'Steering', 'K (rad)', 'Pairs');
fprintf('------------------------------------------------------------------------\n');
for k = 1:min(5, length(sorted_games))
    g = sorted_games(k);
    fprintf('%-35s %8.2f %10.2f %10.4f %6d\n', ...
        g.name, g.CompositeScore, g.SteeringIndex, g.K_TotalRotation, g.pairs);
end
fprintf('========================================\n\n');

% --- 5. SUGGEST GAMES FOR STUDY ---
% Strategy: Tight clustering within groups, maximum separation between groups
fprintf('========================================\n');
fprintf('SUGGESTED GAMES FOR STUDY\n');
fprintf('========================================\n');

score_min = min(comp_scores);
score_max = max(comp_scores);
score_range = score_max - score_min;

% Clusters are already defined above based on game count

if ~isempty(easy_cluster) && ~isempty(hard_cluster)
    gap_easy_med = min([medium_cluster.CompositeScore]) - max([easy_cluster.CompositeScore]);
    gap_med_hard = min([hard_cluster.CompositeScore]) - max([medium_cluster.CompositeScore]);
    fprintf('  GAP between Easy and Medium: %.2f\n', gap_easy_med);
    fprintf('  GAP between Medium and Hard: %.2f\n\n', gap_med_hard);
end

% Check total games available
total_games = length(all_games);
min_games_required = 12;
games_per_category = 4;

fprintf('Total valid games: %d\n', total_games);
if total_games < min_games_required
    fprintf('WARNING: Only %d games available (need at least %d for %d per category)\n', ...
        total_games, min_games_required, games_per_category);
    fprintf('Will select as many as possible from each cluster.\n\n');
else
    fprintf('Sufficient games available - will select %d per category\n\n', games_per_category);
end

% Suggest games - select from tight clusters
suggestions = struct('category', {}, 'game', {}, 'score', {}, 'pairs', {});

% EASY: Select 4 games from the EASIEST cluster (close together)
if total_games >= min_games_required && length(easy_cluster) >= games_per_category
    % Take exactly 4 games (most similar, easiest)
    for i = 1:games_per_category
        suggestions(end+1).category = 'EASY';
        suggestions(end).game = easy_cluster(i).name;
        suggestions(end).score = easy_cluster(i).CompositeScore;
        suggestions(end).pairs = easy_cluster(i).pairs;
        suggestions(end).steering = easy_cluster(i).SteeringIndex;
        suggestions(end).rotation = easy_cluster(i).K_TotalRotation;
    end
elseif ~isempty(easy_cluster)
    % Fallback: select as many as available (up to 4)
    num_to_select = min(games_per_category, length(easy_cluster));
    for i = 1:num_to_select
        suggestions(end+1).category = 'EASY';
        suggestions(end).game = easy_cluster(i).name;
        suggestions(end).score = easy_cluster(i).CompositeScore;
        suggestions(end).pairs = easy_cluster(i).pairs;
        suggestions(end).steering = easy_cluster(i).SteeringIndex;
        suggestions(end).rotation = easy_cluster(i).K_TotalRotation;
    end
end

% MEDIUM: Select 4 games from the MIDDLE cluster (close together)
if total_games >= min_games_required && length(medium_cluster) >= games_per_category
    % Take exactly 4 games from middle of the cluster
    start_idx = max(1, round(length(medium_cluster)/2) - 1);
    end_idx = min(start_idx + games_per_category - 1, length(medium_cluster));
    for i = start_idx:end_idx
        suggestions(end+1).category = 'MEDIUM';
        suggestions(end).game = medium_cluster(i).name;
        suggestions(end).score = medium_cluster(i).CompositeScore;
        suggestions(end).pairs = medium_cluster(i).pairs;
        suggestions(end).steering = medium_cluster(i).SteeringIndex;
        suggestions(end).rotation = medium_cluster(i).K_TotalRotation;
    end
elseif ~isempty(medium_cluster)
    % Fallback: select as many as available (up to 4) from middle
    num_to_select = min(games_per_category, length(medium_cluster));
    start_idx = max(1, round(length(medium_cluster)/2) - floor(num_to_select/2));
    end_idx = min(start_idx + num_to_select - 1, length(medium_cluster));
    for i = start_idx:end_idx
        suggestions(end+1).category = 'MEDIUM';
        suggestions(end).game = medium_cluster(i).name;
        suggestions(end).score = medium_cluster(i).CompositeScore;
        suggestions(end).pairs = medium_cluster(i).pairs;
        suggestions(end).steering = medium_cluster(i).SteeringIndex;
        suggestions(end).rotation = medium_cluster(i).K_TotalRotation;
    end
end

% HARD: Select 4 games from the HARDEST cluster (close together)
if total_games >= min_games_required && length(hard_cluster) >= games_per_category
    % Take exactly 4 games (most similar, hardest)
    start_idx = length(hard_cluster) - games_per_category + 1;
    for i = start_idx:length(hard_cluster)
        suggestions(end+1).category = 'HARD';
        suggestions(end).game = hard_cluster(i).name;
        suggestions(end).score = hard_cluster(i).CompositeScore;
        suggestions(end).pairs = hard_cluster(i).pairs;
        suggestions(end).steering = hard_cluster(i).SteeringIndex;
        suggestions(end).rotation = hard_cluster(i).K_TotalRotation;
    end
elseif ~isempty(hard_cluster)
    % Fallback: select as many as available (up to 4)
    num_to_select = min(games_per_category, length(hard_cluster));
    start_idx = length(hard_cluster) - num_to_select + 1;
    for i = start_idx:length(hard_cluster)
        suggestions(end+1).category = 'HARD';
        suggestions(end).game = hard_cluster(i).name;
        suggestions(end).score = hard_cluster(i).CompositeScore;
        suggestions(end).pairs = hard_cluster(i).pairs;
        suggestions(end).steering = hard_cluster(i).SteeringIndex;
        suggestions(end).rotation = hard_cluster(i).K_TotalRotation;
    end
end

% Print suggestions
fprintf('\n--- RECOMMENDED GAME SELECTION ---\n\n');
if ~isempty(suggestions)
    % Group by category
    categories = unique({suggestions.category}, 'stable');
    for c = 1:length(categories)
        cat_games = suggestions(strcmp({suggestions.category}, categories{c}));
        fprintf('%s GAMES (%d selected):\n', categories{c}, length(cat_games));
        fprintf('%-40s %8s %10s %10s %6s\n', 'Game', 'Score', 'Steering', 'K (rad)', 'Pairs');
        fprintf('--------------------------------------------------------------------------------\n');
        for i = 1:length(cat_games)
            fprintf('%-40s %8.2f %10.2f %10.4f %6d\n', ...
                cat_games(i).game, cat_games(i).score, cat_games(i).steering, ...
                cat_games(i).rotation, cat_games(i).pairs);
        end
        fprintf('\n');
    end
    
    % Calculate separation metrics for suggested games
    easy_sug = suggestions(strcmp({suggestions.category}, 'EASY'));
    medium_sug = suggestions(strcmp({suggestions.category}, 'MEDIUM'));
    hard_sug = suggestions(strcmp({suggestions.category}, 'HARD'));
    
    if ~isempty(easy_sug) && ~isempty(hard_sug)
        easy_mean = mean([easy_sug.score]);
        easy_std = std([easy_sug.score]);
        hard_mean = mean([hard_sug.score]);
        hard_std = std([hard_sug.score]);
        
        fprintf('WITHIN-GROUP CONSISTENCY (Lower = Better):\n');
        fprintf('  Easy: mean = %.2f, std = %.2f, range = %.2f\n', ...
            easy_mean, easy_std, max([easy_sug.score]) - min([easy_sug.score]));
        
        if ~isempty(medium_sug)
            med_mean = mean([medium_sug.score]);
            med_std = std([medium_sug.score]);
            fprintf('  Medium: mean = %.2f, std = %.2f, range = %.2f\n', ...
                med_mean, med_std, max([medium_sug.score]) - min([medium_sug.score]));
        end
        
        fprintf('  Hard: mean = %.2f, std = %.2f, range = %.2f\n\n', ...
            hard_mean, hard_std, max([hard_sug.score]) - min([hard_sug.score]));
        
        fprintf('BETWEEN-GROUP SEPARATION (Higher = Better):\n');
        if ~isempty(medium_sug)
            gap_easy_med = min([medium_sug.score]) - max([easy_sug.score]);
            gap_med_hard = min([hard_sug.score]) - max([medium_sug.score]);
            fprintf('  Gap Easy-Medium: %.2f\n', gap_easy_med);
            fprintf('  Gap Medium-Hard: %.2f\n', gap_med_hard);
            fprintf('  Total separation: %.2f\n', hard_mean - easy_mean);
        else
            fprintf('  Gap Easy-Hard: %.2f\n', min([hard_sug.score]) - max([easy_sug.score]));
        end
        fprintf('  Separation ratio (Hard/Easy): %.2fx\n\n', hard_mean/easy_mean);
    end
else
    fprintf('Not enough games to make recommendations.\n\n');
end

fprintf('========================================\n\n');

% --- 6. ADDITIONAL VISUALIZATION: SUGGESTED GAMES ---
if ~isempty(suggestions)
    figure('Position', [100, 100, 1400, 800], 'Name', 'Suggested Games Visualization');
    
    % SUBPLOT 1: Highlighted games on difficulty map
    subplot(2, 2, 1);
    hold on;
    
    % Plot all games in light gray
    x_vals = [all_games.SteeringIndex];
    y_vals = [all_games.K_TotalRotation];
    scatter(x_vals, y_vals, 40, [0.8 0.8 0.8], 'filled', 'MarkerEdgeColor', 'none');
    
    % Highlight suggested games
    for i = 1:length(suggestions)
        % Find the game in all_games
        game_idx = find(strcmp({all_games.name}, suggestions(i).game), 1);
        if ~isempty(game_idx)
            if strcmp(suggestions(i).category, 'EASY')
                marker_color = [0.2 0.8 0.2];
            elseif strcmp(suggestions(i).category, 'MEDIUM')
                marker_color = [0.9 0.9 0.2];
            else
                marker_color = [0.8 0.2 0.2];
            end
            scatter(all_games(game_idx).SteeringIndex, all_games(game_idx).K_TotalRotation, ...
                100, marker_color, 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 2);
        end
    end
    
    xlabel('Steering Index', 'FontSize', 11);
    ylabel('K - Total Rotation (rad)', 'FontSize', 11);
    title('Suggested Games (Highlighted)', 'FontSize', 12, 'FontWeight', 'bold');
    legend({'All Games', 'Selected'}, 'Location', 'best');
    grid on;
    
    % SUBPLOT 2: Score distribution with suggested games marked
    subplot(2, 2, 2);
    hold on;
    
    bar(1:length(sorted_scores), sorted_scores, 'FaceColor', [0.7 0.7 0.7], 'EdgeColor', 'none');
    
    % Mark suggested games
    for i = 1:length(suggestions)
        game_idx = find(strcmp({sorted_games.name}, suggestions(i).game), 1);
        if ~isempty(game_idx)
            if strcmp(suggestions(i).category, 'EASY')
                marker_color = [0.2 0.8 0.2];
            elseif strcmp(suggestions(i).category, 'MEDIUM')
                marker_color = [0.9 0.9 0.2];
            else
                marker_color = [0.8 0.2 0.2];
            end
            plot(game_idx, sorted_scores(game_idx), 'o', 'MarkerSize', 10, ...
                'MarkerFaceColor', marker_color, 'MarkerEdgeColor', 'k', 'LineWidth', 2);
        end
    end
    
    xlabel('Game Rank', 'FontSize', 11);
    ylabel('Composite Score', 'FontSize', 11);
    title('Selected Games in Rank Order', 'FontSize', 12, 'FontWeight', 'bold');
    grid on;
    
    % SUBPLOT 3: Comparison of metrics across categories
    subplot(2, 2, 3);
    categories = unique({suggestions.category}, 'stable');
    metric_means = zeros(length(categories), 2);
    
    for c = 1:length(categories)
        cat_games = suggestions(strcmp({suggestions.category}, categories{c}));
        metric_means(c, 1) = mean([cat_games.steering]);
        metric_means(c, 2) = mean([cat_games.rotation]);
    end
    
    bar(metric_means);
    set(gca, 'XTickLabel', categories);
    ylabel('Average Metric Value', 'FontSize', 11);
    legend({'Steering Index', 'K (Total Rotation)'}, 'Location', 'best');
    title('Average Metrics by Category', 'FontSize', 12, 'FontWeight', 'bold');
    grid on;
    
    % SUBPLOT 4: Suggested games table
    subplot(2, 2, 4);
    axis off;
    
    % Create table data
    table_text = sprintf('SUGGESTED GAMES SUMMARY\n\n');
    table_text = [table_text sprintf('%-8s %-30s %8s\n', 'Category', 'Game', 'Score')];
    table_text = [table_text sprintf('%s\n', repmat('-', 1, 60))];
    
    for i = 1:length(suggestions)
        % Truncate long names
        game_name = suggestions(i).game;
        if length(game_name) > 30
            game_name = [game_name(1:27) '...'];
        end
        table_text = [table_text sprintf('%-8s %-30s %8.2f\n', ...
            suggestions(i).category, game_name, suggestions(i).score)];
    end
    
    text(0.1, 0.9, table_text, 'FontSize', 9, 'FontName', 'FixedWidth', ...
        'VerticalAlignment', 'top', 'Interpreter', 'none');
end

% Export to workspace for further analysis
fprintf('Games exported to workspace as ''all_games'', ''sorted_games'', and ''suggestions''\n');
assignin('base', 'all_games', all_games);
assignin('base', 'sorted_games', sorted_games);
assignin('base', 'suggestions', suggestions);

% Interactive Cursor for Map
dcm = datacursormode(gcf);
set(dcm, 'UpdateFcn', {@myupdatefcn, all_games});

function txt = myupdatefcn(~, event_obj, all_games)
    % Custom datacursor function for interactive point inspection
    pos = get(event_obj, 'Position');
    [~, idx] = min(abs([all_games.SteeringIndex] - pos(1)) + ...
                   abs([all_games.K_TotalRotation] - pos(2)));
    g = all_games(idx);
    txt = {g.name, ...
           ['Composite Score: ' num2str(g.CompositeScore, '%.2f')], ...
           ['Steering Index: ' num2str(g.SteeringIndex, '%.2f')], ...
           ['K (Total Rot): ' num2str(g.K_TotalRotation, '%.4f')], ...
           ['Path Length: ' num2str(g.PathLength, '%.1f') ' cm'], ...
           ['Pairs: ' num2str(g.pairs)]};
end
