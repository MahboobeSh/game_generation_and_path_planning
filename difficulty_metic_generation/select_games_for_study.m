function select_games_for_study_v2()
    % SELECT_GAMES_FOR_STUDY_V2 (Auto-Scaling Version)
    
    % --- CONFIGURATION ---
    base_folder = '/home/mahboobe/Desktop/game_generation_and_path_planning/game/'; 
    folders_to_scan = {'3pairs/fit', '4pairs/fit'};
    
    % RELAXED Length Constraints (To catch Hard games)
    target_len_2p = 60; 
    target_len_3p = 65; 
    target_len_4p = 70;
    tolerance = 0.30; % +/- 30% (Needed for complex paths)
    
    % Storage
    all_games = struct('name', {}, 'pairs', {}, 'SteeringDensity', {}, 'GoalAlign', {});
    
    fprintf('Scanning games with +/- 30%% length tolerance...\n');
    
    % --- 1. LOAD AND PROCESS ---
    for f = 1:length(folders_to_scan)
        full_path = fullfile(base_folder, folders_to_scan{f});
        files = dir(fullfile(full_path, '*.mat'));
        
        for i = 1:length(files)
            try
                data = load(fullfile(full_path, files(i).name));
                
                % Determine Pair Count
                if isfield(data, 'number_of_pairs'), np = data.number_of_pairs;
                else, np = 3; end % Default
                
                % Get Path
                if isfield(data, 'curve'), path = data.curve;
                elseif isfield(data, 'path'), path = data.path;
                else, continue; end
                
                % Length Check
                diffs = diff(path);
                L = sum(sqrt(sum(diffs.^2, 2)));
                
                target = 65;
                if np == 2, target = target_len_2p;
                elseif np == 3, target = target_len_3p;
                elseif np == 4, target = target_len_4p; end
                
                if L < target*(1-tolerance) || L > target*(1+tolerance)
                    continue; 
                end
                
                % Calculate Metrics
                m = calculate_rehab_metrics(path, data.obstacle, data.obstacle_radious, data.x_range, data.y_range, data.num_samples_list);
                
                % Robust Metric Extraction
                if isfield(m, 'GoalAlignmentAvgDeg'), g_val = m.GoalAlignmentAvgDeg;
                elseif isfield(m, 'GoalAlignment'), g_val = m.GoalAlignment;
                else, g_val = 0; end
                
                % Store
                idx = length(all_games) + 1;
                all_games(idx).name = files(i).name;
                all_games(idx).pairs = np;
                all_games(idx).SteeringDensity = m.SteeringIndex / L;
                all_games(idx).GoalAlign = g_val;
                
            catch
                % Skip errors silently for cleaner output
            end
        end
    end
    
    if isempty(all_games), error('No games found. Check paths.'); end
    fprintf('Found %d valid games.\n', length(all_games));
    
    % --- 2. CALCULATE PERCENTILES (The "Relative" Fix) ---
    x_vals = [all_games.SteeringDensity];
    y_vals = [all_games.GoalAlign];
    
    % X Thresholds (Steering)
    x_33 = prctile(x_vals, 33);
    x_66 = prctile(x_vals, 66);
    
    % Y Thresholds (Goal Alignment)
    y_33 = prctile(y_vals, 33);
    y_66 = prctile(y_vals, 66);
    
    % Bounds for plotting
    x_max = max(x_vals) * 1.1;
    y_max = max(y_vals) * 1.1;
    
    % --- 3. VISUALIZATION ---
    figure('Position', [100, 100, 1200, 800], 'Name', 'Auto-Scaled Selection Tool');
    hold on;
    
    % Draw RELATIVE Zones
    % Easy (Bottom-Left 33%)
    fill([0 0 x_33 x_33], [0 y_33 y_33 0], [0.8 1 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
    text(x_33/2, y_33/2, 'EASY ZONE', 'Color', [0 0.5 0], 'HorizontalAlignment', 'center');
    
    % Hard (Top-Right 33%)
    fill([x_66 x_66 x_max x_max], [y_66 y_max y_max y_66], [1 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
    text((x_66+x_max)/2, (y_66+y_max)/2, 'HARD ZONE', 'Color', [0.8 0 0], 'HorizontalAlignment', 'center');
    
    % Plot Points
    pairs = [all_games.pairs];
    gscatter(x_vals, y_vals, pairs, 'bgr', 'o+^', 8);
    
    title('Difficulty Map (Auto-Scaled)');
    xlabel('Motor Constraint (Steering Density)');
    ylabel('Cognitive Conflict (Avg Goal Alignment Deg)');
    grid on;
    axis([0 x_max 0 y_max]); % Zoom to fit data
    
    % Add Labels
    text(x_vals, y_vals, {all_games.name}, 'VerticalAlignment','bottom', ...
        'HorizontalAlignment','right', 'FontSize', 8, 'Interpreter', 'none');
    
    % Interactive Cursor
    dcm = datacursormode(gcf);
    set(dcm, 'UpdateFcn', {@myupdatefcn, all_games});
end

function txt = myupdatefcn(~, event_obj, all_games)
    pos = get(event_obj,'Position');
    [~, idx] = min(abs([all_games.SteeringDensity] - pos(1)) + abs([all_games.GoalAlign] - pos(2)));
    g = all_games(idx);
    txt = {g.name, ['Align: ' num2str(g.GoalAlign, '%.1f')], ['Steer: ' num2str(g.SteeringDensity, '%.2f')]};
end