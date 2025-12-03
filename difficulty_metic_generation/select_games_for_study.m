% SELECT_GAMES_FOR_STUDY - Uses Extended Steering Law (Minimal Rehab Metrics)

% --- CONFIGURATION ---
base_folder = 'C:\Users\Mahbo\OneDrive - University of Calgary\code\game_creation_and_fits\new_games\selected_games';
folders_to_scan = {'3pairs/fit', '4pairs/fit', '5pairs/fit'};

% RELAXED Length Constraints
target_len_GLOBAL = 80; 
tolerance_cm = 8 + 0.1; 

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
            
            % Get Path (prefer curve over A* path)
            if isfield(data, 'curve') && ~isempty(data.curve)
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

% --- 3. VISUALIZATION ---
figure('Position', [50, 50, 1600, 800], 'Name', 'Game Selection - Extended Steering Law');

% SUBPLOT 1: The Difficulty Map (Steering vs Curvature)
subplot(1, 2, 1);
hold on;
x_vals = [all_games.SteeringIndex];
y_vals = [all_games.K_TotalRotation];

% Auto-Scale Map Zones
x_33 = prctile(x_vals, 33); 
x_66 = prctile(x_vals, 66); 
x_max = max(x_vals) * 1.1;
y_33 = prctile(y_vals, 33); 
y_66 = prctile(y_vals, 66); 
y_max = max(y_vals) * 1.1;

% Draw Zones
fill([0 0 x_33 x_33], [0 y_33 y_33 0], [0.8 1 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.3); % Easy
fill([x_66 x_66 x_max x_max], [y_66 y_max y_max y_66], [1 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.3); % Hard

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
subplot(1, 2, 2);
hold on;

% Color code bars based on thresholds
for k = 1:length(sorted_scores)
    score = sorted_scores(k);
    if score < score_33
        bar(k, score, 'FaceColor', [0.2 0.8 0.2]); % Green (Easy)
    elseif score > score_66
        bar(k, score, 'FaceColor', [0.8 0.2 0.2]); % Red (Hard)
    else
        bar(k, score, 'FaceColor', [0.9 0.9 0.2]); % Yellow (Medium)
    end
end

yline(score_33, '--g', 'Easy Threshold (33%ile)', 'LineWidth', 2);
yline(score_66, '--r', 'Hard Threshold (66%ile)', 'LineWidth', 2);

title('Composite Score Separation (ID = Steering + \alpha*log(1+K))', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Game Rank (Sorted)', 'FontSize', 11);
ylabel('Composite Difficulty Score (ID)', 'FontSize', 11);
grid on;

% Add Labels to Top/Bottom 3 for easy reading
num_g = length(sorted_scores);
if num_g >= 3
    text(1:3, sorted_scores(1:3), {sorted_games(1:3).name}, 'Rotation', 90, ...
        'HorizontalAlignment', 'left', 'Interpreter', 'none', 'FontSize', 8);
    text(num_g-2:num_g, sorted_scores(end-2:end), {sorted_games(end-2:end).name}, ...
        'Rotation', 90, 'HorizontalAlignment', 'right', 'Interpreter', 'none', 'FontSize', 8);
end

% --- 4. PRINT SUMMARY ---
fprintf('\n========================================\n');
fprintf('SEPARATION SUMMARY (Extended Steering Law)\n');
fprintf('========================================\n');
fprintf('Total games analyzed: %d\n', length(all_games));
fprintf('Path length range: %.1f - %.1f cm\n\n', min_len, max_len);

fprintf('DIFFICULTY THRESHOLDS:\n');
fprintf('  EASY Threshold (< %.2f)\n', score_33);
fprintf('  HARD Threshold (> %.2f)\n\n', score_66);

% Calculate separation statistics
easy_scores = comp_scores(comp_scores < score_33);
hard_scores = comp_scores(comp_scores > score_66);

if ~isempty(easy_scores) && ~isempty(hard_scores)
    separation_factor = mean(hard_scores) / mean(easy_scores);
    fprintf('SEPARATION METRICS:\n');
    fprintf('  Easy games (< 33%%ile): %d games, mean score = %.2f\n', ...
        length(easy_scores), mean(easy_scores));
    fprintf('  Hard games (> 66%%ile): %d games, mean score = %.2f\n', ...
        length(hard_scores), mean(hard_scores));
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

% Export to workspace for further analysis
fprintf('Games exported to workspace as ''all_games'' and ''sorted_games''\n');
assignin('base', 'all_games', all_games);
assignin('base', 'sorted_games', sorted_games);

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
