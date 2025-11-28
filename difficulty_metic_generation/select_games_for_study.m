
    % SELECT_GAMES_FOR_STUDY_V3 (Composite Separation Analysis)
    
    % --- CONFIGURATION ---
    base_folder = '/home/mahboobe/Desktop/game_generation_and_path_planning/selected_games/'; 
    base_folder = '/home/mahboobe/Desktop/game_generation_and_path_planning/game/';
    folders_to_scan = {'2pairs/fit','3pairs/fit', '4pairs/fit'};
    
    % RELAXED Length Constraints

    target_len_GLOBAL = 65; 
    tolerance_cm = 10+0.1; 
    
    min_len = target_len_GLOBAL - tolerance_cm; % 60 cm
    max_len = target_len_GLOBAL + tolerance_cm; % 70 cm
    

    % Storage
    all_games = struct('name', {}, 'pairs', {}, 'SteeringDensity', {}, 'GoalAlign', {}, 'CompositeScore', {});
    
    fprintf('Scanning games and calculating Composite Scores...\n');
    
    % --- 1. LOAD AND PROCESS ---
    for f = 1:length(folders_to_scan)
        full_path = fullfile(base_folder, folders_to_scan{f});
        files = dir(fullfile(full_path, '*.mat'));
        
        for i = 1:length(files)
            try
                data = load(fullfile(full_path, files(i).name));
                
                % Determine Pair Count
                if isfield(data, 'number_of_pairs'), np = data.number_of_pairs;
                else, np = 3; end 
                
                % Get Path
                if isfield(data, 'curve'), path = data.curve;
                elseif isfield(data, 'path'), path = data.path;
                else, continue; end
                
                % Length Check
                diffs = diff(path);
                L = sum(sqrt(sum(diffs.^2, 2)));
                
                                % ... inside the loop ...
                if L < min_len || L > max_len
                    disp(L)
                    disp(files(i).name)
                    continue; % Reject games that are too short/long
                    
                end
                
                
                % Calculate Metrics
                m = calculate_rehab_metrics(path, data.obstacle, data.obstacle_radious, data.x_range, data.y_range, data.num_samples_list);
                
                % Extract Metrics
                if isfield(m, 'GoalAlignmentAvgDeg'), g_val = m.GoalAlignmentAvgDeg;
                elseif isfield(m, 'GoalAlignment'), g_val = m.GoalAlignment;
                else, g_val = 0; end
                
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
                all_games(idx).SteeringDensity = m.SteeringIndex / L;
                all_games(idx).GoalAlign = g_val;
                all_games(idx).CompositeScore = comp_val;
                
            catch
            end
        end
    end
    
    if isempty(all_games), error('No games found.'); end
    fprintf('Found %d valid games.\n', length(all_games));
    
    % --- 2. CALCULATE SEPARATION ---
    comp_scores = [all_games.CompositeScore];
    [sorted_scores, sort_idx] = sort(comp_scores);
    sorted_games = all_games(sort_idx);
    
    % Define Thresholds (33% and 66% percentile)
    score_33 = prctile(comp_scores, 33);
    score_66 = prctile(comp_scores, 66);
    
    % --- 3. VISUALIZATION ---
    figure('Position', [50, 50, 1600, 800], 'Name', 'Game Selection & Separation Analysis');
    
    % SUBPLOT 1: The Difficulty Map (Steering vs Alignment)
    subplot(1, 2, 1);
    hold on;
    x_vals = [all_games.SteeringDensity];
    y_vals = [all_games.GoalAlign];
    
    % Auto-Scale Map Zones
    x_33 = prctile(x_vals, 33); x_66 = prctile(x_vals, 66); x_max = max(x_vals)*1.1;
    y_33 = prctile(y_vals, 33); y_66 = prctile(y_vals, 66); y_max = max(y_vals)*1.1;
    
    % Draw Zones
    fill([0 0 x_33 x_33], [0 y_33 y_33 0], [0.8 1 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.3); % Easy
    fill([x_66 x_66 x_max x_max], [y_66 y_max y_max y_66], [1 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.3); % Hard
    
    gscatter(x_vals, y_vals, [all_games.pairs], 'bgr', 'o+^', 8);
    text(x_vals, y_vals, {all_games.name}, 'VerticalAlignment','bottom', 'HorizontalAlignment','right', 'FontSize', 8, 'Interpreter', 'none');
    
    title('Difficulty Drivers (Motor vs Cognitive)');
    xlabel('Motor Constraint (Steering Density)');
    ylabel('Cognitive Conflict (Goal Alignment Deg)');
    grid on; axis([0 x_max 0 y_max]);
    
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
    
    yline(score_33, '--g', 'Easy Threshold', 'LineWidth', 2);
    yline(score_66, '--r', 'Hard Threshold', 'LineWidth', 2);
    
    title('Composite Score Separation');
    xlabel('Game Rank (Sorted)');
    ylabel('Composite Difficulty Score');
    grid on;
    
    % Add Labels to Top/Bottom 3 for easy reading
    num_g = length(sorted_scores);
    text(1:3, sorted_scores(1:3), {sorted_games(1:3).name}, 'Rotation', 90, 'HorizontalAlignment', 'left', 'Interpreter', 'none');
    text(num_g-2:num_g, sorted_scores(end-2:end), {sorted_games(end-2:end).name}, 'Rotation', 90, 'HorizontalAlignment', 'right', 'Interpreter', 'none');

    % --- 4. PRINT SUMMARY ---
    fprintf('\n=== SEPARATION SUMMARY ===\n');
    fprintf('EASY Threshold (< %.2f)\n', score_33);
    fprintf('HARD Threshold (> %.2f)\n', score_66);
    fprintf('Separation Factor (Hard Mean / Easy Mean): %.2f x\n\n', ...
        mean(sorted_scores(sorted_scores>score_66)) / mean(sorted_scores(sorted_scores<score_33)));
    
    fprintf('--- TOP 4 HARD CANDIDATES ---\n');
    for k = length(sorted_games):-1:length(sorted_games)-3
        if k < 1, break; end
        fprintf('%s (Score: %.2f) [%d pairs]\n', sorted_games(k).name, sorted_games(k).CompositeScore, sorted_games(k).pairs);
    end
    
    fprintf('\n--- TOP 4 EASY CANDIDATES ---\n');
    for k = 1:4
        if k > length(sorted_games), break; end
        fprintf('%s (Score: %.2f) [%d pairs]\n', sorted_games(k).name, sorted_games(k).CompositeScore, sorted_games(k).pairs);
    end
    
    % Interactive Cursor for Map
    dcm = datacursormode(gcf);
    set(dcm, 'UpdateFcn', {@myupdatefcn, all_games});


function txt = myupdatefcn(~, event_obj, all_games)
    pos = get(event_obj,'Position');
    [~, idx] = min(abs([all_games.SteeringDensity] - pos(1)) + abs([all_games.GoalAlign] - pos(2)));
    g = all_games(idx);
    txt = {g.name, ...
           ['Score: ' num2str(g.CompositeScore, '%.1f')], ...
           ['Steer: ' num2str(g.SteeringDensity, '%.2f')], ...
           ['Align: ' num2str(g.GoalAlign, '%.1f')]};
end