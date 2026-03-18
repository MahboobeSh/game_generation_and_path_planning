% analyze_study_games_geometry.m
% Comprehensive geometric analysis of games selected for user study
%
% This script analyzes the following geometric properties for each game:
% 1. Obstacle radii (min, max, mean, std)
% 2. Minimum distance between obstacle pairs (obstacles in the same pair)
% 3. Minimum distance between obstacles in different pairs
% 4. Distance from obstacles to start point
% 5. Distance from obstacles to end point
% 6. Distance from closest obstacle to start and end points
%
% Output:
% - Detailed per-game analysis saved to text file
% - Summary statistics across all games
% - Table format suitable for thesis reporting

clc; clear; close all;

% ============================================================================
% CONFIGURATION
% ============================================================================
% Path to study games folder
base_path = 'C:\Users\Mahboobe\OneDrive - University of Calgary\user_study_info\user_study_files_with_survey\user_study_files';
games_folder = fullfile(base_path, 'final_games_solved');
output_folder = fullfile(fileparts(mfilename('fullpath')));
output_file = fullfile(output_folder, 'study_games_geometry_analysis.txt');

% Game indices to analyze
game_indices = 0:12;
num_games = length(game_indices);

% Separate baseline (set 0) from study games (sets 1-12)
baseline_idx = 0;
study_indices = 1:12;
num_study_games = length(study_indices);

% ============================================================================
% EXPECTED CONSTRAINTS (from validate_obstacle_set.m and create_obstacle_sets.m)
% ============================================================================
% These are the constraints used when creating the study games (sets 1-12)
EXPECTED_MIN_RADIUS = 2.0;  % cm
EXPECTED_MAX_RADIUS = 3.25;  % cm
EXPECTED_MIN_PAIR_DISTANCE = 2.0;  % cm (gate width - min distance within same pair)
EXPECTED_MAX_PAIR_DISTANCE = 3.0;  % cm (gate width - max distance within same pair)
EXPECTED_MIN_INTERPAIR_DISTANCE = 2.0;  % cm (between different pairs)
EXPECTED_MIN_DIST_TO_START_END = 2.5;  % cm

% ============================================================================
% INITIALIZE DATA STRUCTURES
% ============================================================================
% Structure to store results for each game
game_results = struct();

% Arrays to store aggregated statistics - SEPARATE for baseline and study games
% Baseline (set 0)
baseline_radii = [];
baseline_min_pair_distance = [];
baseline_min_interpair_distance = [];
baseline_min_dist_to_start = [];
baseline_min_dist_to_end = [];

% Study games (sets 1-12)
study_radii = [];
study_min_pair_distances = [];
study_max_pair_distances = [];
study_mean_pair_distances = [];
study_min_interpair_distances = [];
study_min_dist_to_start = [];
study_min_dist_to_end = [];

% ============================================================================
% ANALYZE EACH GAME
% ============================================================================
fprintf('Analyzing %d games from study...\n', num_games);
fprintf('Games folder: %s\n\n', games_folder);

for idx = 1:num_games
    game_num = game_indices(idx);
    game_file = fullfile(games_folder, sprintf('set_%d_fit.mat', game_num));
    
    if ~exist(game_file, 'file')
        warning('Game file not found: %s', game_file);
        continue;
    end
    
    fprintf('Processing Game %d...\n', game_num);
    
    % Load game data
    game_data = load(game_file);
    
    % Extract obstacle information
    obstacle_centers = game_data.obstacle;  % Nx2 matrix
    obstacle_radii = game_data.obstacle_radious;  % Nx1 vector
    start_point = game_data.X_s;  % 1x2 vector
    end_point = game_data.X_e;  % 1x2 vector
    num_obstacles = size(obstacle_centers, 1);
    
    % Determine number of pairs
    if isfield(game_data, 'number_of_pairs')
        num_pairs = game_data.number_of_pairs;
    else
        num_pairs = num_obstacles / 2;  % Assume pairs
    end
    
    % ========================================================================
    % 1. OBSTACLE RADII ANALYSIS
    % ========================================================================
    radii_min = min(obstacle_radii);
    radii_max = max(obstacle_radii);
    radii_mean = mean(obstacle_radii);
    radii_std = std(obstacle_radii);
    
    % ========================================================================
    % 2. MINIMUM DISTANCE BETWEEN OBSTACLE PAIRS (same pair)
    % ========================================================================
    % Obstacles are ordered in pairs: [1,2], [3,4], [5,6], etc.
    % This matches the logic in validate_obstacle_set.m lines 137-150
    pair_distances = [];
    pair_center_distances = [];
    for pair_idx = 1:num_pairs
        obs1_idx = 2 * pair_idx - 1;
        obs2_idx = 2 * pair_idx;
        
        center1 = obstacle_centers(obs1_idx, :);
        center2 = obstacle_centers(obs2_idx, :);
        radius1 = obstacle_radii(obs1_idx);
        radius2 = obstacle_radii(obs2_idx);
        
        % Distance between centers (as in validate_obstacle_set.m line 142)
        center_distance = norm(center1 - center2);
        
        % Clear distance (edge-to-edge) - gate width
        clear_distance = center_distance - radius1 - radius2;
        
        pair_distances = [pair_distances; clear_distance];
        pair_center_distances = [pair_center_distances; center_distance];
    end
    
    min_pair_distance = min(pair_distances);
    max_pair_distance = max(pair_distances);
    mean_pair_distance = mean(pair_distances);
    
    % ========================================================================
    % 3. MINIMUM DISTANCE BETWEEN OBSTACLES IN DIFFERENT PAIRS
    % ========================================================================
    % This matches the logic in validate_obstacle_set.m lines 221-246
    % and create_obstacle_sets.m lines 188-210
    interpair_distances = [];
    for i = 1:num_obstacles
        for j = i+1:num_obstacles
            % Determine which pairs these obstacles belong to
            pair_i = ceil(i / 2);
            pair_j = ceil(j / 2);
            
            % Only consider obstacles from different pairs
            if pair_i ~= pair_j
                center1 = obstacle_centers(i, :);
                center2 = obstacle_centers(j, :);
                radius1 = obstacle_radii(i);
                radius2 = obstacle_radii(j);
                
                % Center-to-center distance
                center_distance = norm(center1 - center2);
                
                % Clear distance (edge-to-edge)
                % Check in validation: distance < (radius1 + radius2 + min_distance_between_obstacles)
                clear_distance = center_distance - radius1 - radius2;
                
                interpair_distances = [interpair_distances; clear_distance];
            end
        end
    end
    
    min_interpair_distance = min(interpair_distances);
    max_interpair_distance = max(interpair_distances);
    mean_interpair_distance = mean(interpair_distances);
    
    % ========================================================================
    % 4. DISTANCE FROM OBSTACLES TO START POINT
    % ========================================================================
    % This matches the logic in validate_obstacle_set.m lines 301-302
    % and create_obstacle_sets.m lines 429
    distances_to_start = zeros(num_obstacles, 1);
    for i = 1:num_obstacles
        center = obstacle_centers(i, :);
        radius = obstacle_radii(i);
        % Center-to-center distance
        center_distance = norm(start_point - center);
        % Clear distance (edge of obstacle to start point)
        clear_distance = center_distance - radius;
        distances_to_start(i) = clear_distance;
    end
    
    min_dist_to_start = min(distances_to_start);
    max_dist_to_start = max(distances_to_start);
    mean_dist_to_start = mean(distances_to_start);
    
    % ========================================================================
    % 5. DISTANCE FROM OBSTACLES TO END POINT
    % ========================================================================
    % This matches the logic in validate_obstacle_set.m lines 301-302
    % and create_obstacle_sets.m lines 439
    distances_to_end = zeros(num_obstacles, 1);
    for i = 1:num_obstacles
        center = obstacle_centers(i, :);
        radius = obstacle_radii(i);
        % Center-to-center distance
        center_distance = norm(end_point - center);
        % Clear distance (edge of obstacle to end point)
        clear_distance = center_distance - radius;
        distances_to_end(i) = clear_distance;
    end
    
    min_dist_to_end = min(distances_to_end);
    max_dist_to_end = max(distances_to_end);
    mean_dist_to_end = mean(distances_to_end);
    
    % ========================================================================
    % 6. CLOSEST OBSTACLE TO START AND END
    % ========================================================================
    [closest_to_start_dist, closest_to_start_idx] = min(distances_to_start);
    [closest_to_end_dist, closest_to_end_idx] = min(distances_to_end);
    
    % ========================================================================
    % STORE RESULTS FOR THIS GAME
    % ========================================================================
    game_results(idx).game_num = game_num;
    game_results(idx).num_pairs = num_pairs;
    game_results(idx).num_obstacles = num_obstacles;
    
    % Radii
    game_results(idx).radii_min = radii_min;
    game_results(idx).radii_max = radii_max;
    game_results(idx).radii_mean = radii_mean;
    game_results(idx).radii_std = radii_std;
    
    % Pair distances
    game_results(idx).min_pair_distance = min_pair_distance;
    game_results(idx).max_pair_distance = max_pair_distance;
    game_results(idx).mean_pair_distance = mean_pair_distance;
    
    % Interpair distances
    game_results(idx).min_interpair_distance = min_interpair_distance;
    game_results(idx).max_interpair_distance = max_interpair_distance;
    game_results(idx).mean_interpair_distance = mean_interpair_distance;
    
    % Distances to start/end
    game_results(idx).min_dist_to_start = min_dist_to_start;
    game_results(idx).max_dist_to_start = max_dist_to_start;
    game_results(idx).mean_dist_to_start = mean_dist_to_start;
    game_results(idx).min_dist_to_end = min_dist_to_end;
    game_results(idx).max_dist_to_end = max_dist_to_end;
    game_results(idx).mean_dist_to_end = mean_dist_to_end;
    
    % Aggregate data - separate baseline from study games
    if game_num == baseline_idx
        % This is the baseline game (set 0)
        baseline_radii = obstacle_radii(:);  % Ensure column vector
        baseline_min_pair_distance = min_pair_distance;
        baseline_min_interpair_distance = min_interpair_distance;
        baseline_min_dist_to_start = min_dist_to_start;
        baseline_min_dist_to_end = min_dist_to_end;
    else
        % This is a study game (sets 1-12)
        study_radii = [study_radii; obstacle_radii(:)];  % Ensure column vector
        study_min_pair_distances = [study_min_pair_distances; min_pair_distance];
        study_max_pair_distances = [study_max_pair_distances; max_pair_distance];
        study_mean_pair_distances = [study_mean_pair_distances; mean_pair_distance];
        study_min_interpair_distances = [study_min_interpair_distances; min_interpair_distance];
        study_min_dist_to_start = [study_min_dist_to_start; min_dist_to_start];
        study_min_dist_to_end = [study_min_dist_to_end; min_dist_to_end];
    end
end

fprintf('\nAnalysis complete. Generating report...\n');

% ============================================================================
% CHECK FOR OBSTACLES OUTSIDE EXPECTED RANGE
% ============================================================================
fprintf('\n================================================================================\n');
fprintf('CHECKING FOR OBSTACLES OUTSIDE EXPECTED RANGE [%.2f, %.2f] cm\n', ...
    EXPECTED_MIN_RADIUS, EXPECTED_MAX_RADIUS);
fprintf('================================================================================\n');

found_violations = false;
for idx = 1:num_games
    g = game_results(idx);
    
    if g.radii_min < EXPECTED_MIN_RADIUS || g.radii_max > EXPECTED_MAX_RADIUS
        found_violations = true;
        fprintf('Game %2d: Min = %.3f cm, Max = %.3f cm  ', ...
            g.game_num, g.radii_min, g.radii_max);
        
        if g.radii_max > EXPECTED_MAX_RADIUS
            fprintf('⚠ MAX EXCEEDS %.2f cm by %.3f cm', ...
                EXPECTED_MAX_RADIUS, g.radii_max - EXPECTED_MAX_RADIUS);
        end
        if g.radii_min < EXPECTED_MIN_RADIUS
            fprintf('⚠ MIN BELOW %.2f cm by %.3f cm', ...
                EXPECTED_MIN_RADIUS, EXPECTED_MIN_RADIUS - g.radii_min);
        end
        fprintf('\n');
    end
end

if ~found_violations
    fprintf('✓ All games have obstacles within expected range.\n');
end
fprintf('================================================================================\n\n');

% ============================================================================
% GENERATE TEXT REPORT
% ============================================================================
fid = fopen(output_file, 'w');

fprintf(fid, '================================================================================\n');
fprintf(fid, 'GEOMETRIC ANALYSIS OF USER STUDY GAMES\n');
fprintf(fid, '================================================================================\n');
fprintf(fid, 'Generated: %s\n', datestr(now));
fprintf(fid, 'Total games analyzed: %d\n', num_games);
fprintf(fid, '  - Baseline/Training game: set_0_fit.mat\n');
fprintf(fid, '  - Study games: set_1_fit.mat to set_12_fit.mat (%d games)\n', num_study_games);
fprintf(fid, 'All distances in cm (centimeters)\n');
fprintf(fid, '================================================================================\n\n');

% ----------------------------------------------------------------------------
% PER-GAME DETAILED ANALYSIS
% ----------------------------------------------------------------------------
fprintf(fid, '\n================================================================================\n');
fprintf(fid, 'DETAILED ANALYSIS FOR EACH GAME\n');
fprintf(fid, '================================================================================\n\n');

% First, print baseline game (set 0)
fprintf(fid, '################################################################################\n');
fprintf(fid, '# BASELINE/TRAINING GAME (SET 0)\n');
fprintf(fid, '################################################################################\n\n');

for idx = 1:num_games
    g = game_results(idx);
    if g.game_num ~= baseline_idx
        continue;  % Skip study games for now
    end
    
    fprintf(fid, '--- GAME %d (BASELINE) ---\n', g.game_num);
    fprintf(fid, 'Number of obstacle pairs: %d\n', g.num_pairs);
    fprintf(fid, 'Total obstacles: %d\n\n', g.num_obstacles);
    
    fprintf(fid, 'Obstacle Radii:\n');
    fprintf(fid, '  Min:  %.3f cm\n', g.radii_min);
    fprintf(fid, '  Max:  %.3f cm\n', g.radii_max);
    fprintf(fid, '  Mean: %.3f cm\n', g.radii_mean);
    fprintf(fid, '  Std:  %.3f cm\n\n', g.radii_std);
    
    fprintf(fid, 'Distances Within Obstacle Pairs (same pair):\n');
    fprintf(fid, '  Min:  %.3f cm (narrowest gate)\n', g.min_pair_distance);
    fprintf(fid, '  Max:  %.3f cm (widest gate)\n', g.max_pair_distance);
    fprintf(fid, '  Mean: %.3f cm\n\n', g.mean_pair_distance);
    
    fprintf(fid, 'Distances Between Different Pairs:\n');
    fprintf(fid, '  Min:  %.3f cm (closest approach)\n', g.min_interpair_distance);
    fprintf(fid, '  Max:  %.3f cm (most separated)\n', g.max_interpair_distance);
    fprintf(fid, '  Mean: %.3f cm\n\n', g.mean_interpair_distance);
    
    fprintf(fid, 'Distance to Start Point:\n');
    fprintf(fid, '  Min:  %.3f cm (closest obstacle to start)\n', g.min_dist_to_start);
    fprintf(fid, '  Max:  %.3f cm (farthest obstacle from start)\n', g.max_dist_to_start);
    fprintf(fid, '  Mean: %.3f cm\n\n', g.mean_dist_to_start);
    
    fprintf(fid, 'Distance to End Point:\n');
    fprintf(fid, '  Min:  %.3f cm (closest obstacle to end)\n', g.min_dist_to_end);
    fprintf(fid, '  Max:  %.3f cm (farthest obstacle from end)\n', g.max_dist_to_end);
    fprintf(fid, '  Mean: %.3f cm\n\n', g.mean_dist_to_end);
    
    fprintf(fid, '################################################################################\n\n\n');
end

% Now print study games (sets 1-12)
fprintf(fid, '################################################################################\n');
fprintf(fid, '# STUDY GAMES (SETS 1-12)\n');
fprintf(fid, '################################################################################\n\n');

for idx = 1:num_games
    g = game_results(idx);
    if g.game_num == baseline_idx
        continue;  % Skip baseline game
    end
    
    fprintf(fid, '--- GAME %d ---\n', g.game_num);
    fprintf(fid, 'Number of obstacle pairs: %d\n', g.num_pairs);
    fprintf(fid, 'Total obstacles: %d\n\n', g.num_obstacles);
    
    fprintf(fid, 'Obstacle Radii:\n');
    fprintf(fid, '  Min:  %.3f cm\n', g.radii_min);
    fprintf(fid, '  Max:  %.3f cm\n', g.radii_max);
    fprintf(fid, '  Mean: %.3f cm\n', g.radii_mean);
    fprintf(fid, '  Std:  %.3f cm\n\n', g.radii_std);
    
    fprintf(fid, 'Distances Within Obstacle Pairs (same pair):\n');
    fprintf(fid, '  Min:  %.3f cm (narrowest gate)\n', g.min_pair_distance);
    fprintf(fid, '  Max:  %.3f cm (widest gate)\n', g.max_pair_distance);
    fprintf(fid, '  Mean: %.3f cm\n\n', g.mean_pair_distance);
    
    fprintf(fid, 'Distances Between Different Pairs:\n');
    fprintf(fid, '  Min:  %.3f cm (closest approach)\n', g.min_interpair_distance);
    fprintf(fid, '  Max:  %.3f cm (most separated)\n', g.max_interpair_distance);
    fprintf(fid, '  Mean: %.3f cm\n\n', g.mean_interpair_distance);
    
    fprintf(fid, 'Distance to Start Point:\n');
    fprintf(fid, '  Min:  %.3f cm (closest obstacle to start)\n', g.min_dist_to_start);
    fprintf(fid, '  Max:  %.3f cm (farthest obstacle from start)\n', g.max_dist_to_start);
    fprintf(fid, '  Mean: %.3f cm\n\n', g.mean_dist_to_start);
    
    fprintf(fid, 'Distance to End Point:\n');
    fprintf(fid, '  Min:  %.3f cm (closest obstacle to end)\n', g.min_dist_to_end);
    fprintf(fid, '  Max:  %.3f cm (farthest obstacle from end)\n', g.max_dist_to_end);
    fprintf(fid, '  Mean: %.3f cm\n\n', g.mean_dist_to_end);
    
    fprintf(fid, '--------------------------------------------------------------------------------\n\n');
end

% ----------------------------------------------------------------------------
% SUMMARY STATISTICS - SEPARATE FOR BASELINE AND STUDY GAMES
% ----------------------------------------------------------------------------
fprintf(fid, '\n================================================================================\n');
fprintf(fid, 'SUMMARY STATISTICS\n');
fprintf(fid, '================================================================================\n\n');

fprintf(fid, '--- BASELINE GAME (SET 0) ---\n\n');

fprintf(fid, 'OBSTACLE RADII:\n');
fprintf(fid, '  Min:  %.3f cm\n', min(baseline_radii));
fprintf(fid, '  Max:  %.3f cm\n', max(baseline_radii));
fprintf(fid, '  Mean: %.3f cm\n', mean(baseline_radii));
fprintf(fid, '  Std:  %.3f cm\n\n', std(baseline_radii));

fprintf(fid, 'MINIMUM GATE WIDTH: %.3f cm\n\n', baseline_min_pair_distance);
fprintf(fid, 'MINIMUM INTER-PAIR DISTANCE: %.3f cm\n\n', baseline_min_interpair_distance);
fprintf(fid, 'MINIMUM DISTANCE TO START: %.3f cm\n\n', baseline_min_dist_to_start);
fprintf(fid, 'MINIMUM DISTANCE TO END: %.3f cm\n\n', baseline_min_dist_to_end);

fprintf(fid, '--------------------------------------------------------------------------------\n\n');
fprintf(fid, '--- STUDY GAMES (SETS 1-12, N=%d) ---\n\n', num_study_games);

fprintf(fid, 'OBSTACLE RADII (all obstacles, all study games):\n');
fprintf(fid, '  Overall Min:  %.3f cm\n', min(study_radii));
fprintf(fid, '  Overall Max:  %.3f cm\n', max(study_radii));
fprintf(fid, '  Overall Mean: %.3f cm\n', mean(study_radii));
fprintf(fid, '  Overall Std:  %.3f cm\n\n', std(study_radii));

fprintf(fid, 'GATE WIDTHS (distance within pairs):\n');
fprintf(fid, '  Minimum gate widths per game:\n');
fprintf(fid, '    Min across games:  %.3f cm (narrowest gate in any game)\n', min(study_min_pair_distances));
fprintf(fid, '    Max across games:  %.3f cm (widest of the narrowest gates)\n', max(study_min_pair_distances));
fprintf(fid, '    Mean: %.3f cm, Std: %.3f cm\n', mean(study_min_pair_distances), std(study_min_pair_distances));
fprintf(fid, '  Mean gate widths per game:\n');
fprintf(fid, '    Min:  %.3f cm (game with narrowest average gates)\n', min(study_mean_pair_distances));
fprintf(fid, '    Max:  %.3f cm (game with widest average gates)\n', max(study_mean_pair_distances));
fprintf(fid, '    Mean of means: %.3f cm (overall average gate width)\n', mean(study_mean_pair_distances));
fprintf(fid, '    Std:  %.3f cm\n\n', std(study_mean_pair_distances));

fprintf(fid, 'MINIMUM DISTANCE BETWEEN DIFFERENT PAIRS (per game, then aggregated):\n');
fprintf(fid, '  Min across games:  %.3f cm (closest pair-to-pair distance in any game)\n', min(study_min_interpair_distances));
fprintf(fid, '  Max across games:  %.3f cm\n', max(study_min_interpair_distances));
fprintf(fid, '  Mean across games: %.3f cm\n', mean(study_min_interpair_distances));
fprintf(fid, '  Std across games:  %.3f cm\n\n', std(study_min_interpair_distances));

fprintf(fid, 'MINIMUM DISTANCE TO START POINT (per game, then aggregated):\n');
fprintf(fid, '  Min across games:  %.3f cm (closest any obstacle gets to start)\n', min(study_min_dist_to_start));
fprintf(fid, '  Max across games:  %.3f cm\n', max(study_min_dist_to_start));
fprintf(fid, '  Mean across games: %.3f cm\n', mean(study_min_dist_to_start));
fprintf(fid, '  Std across games:  %.3f cm\n\n', std(study_min_dist_to_start));

fprintf(fid, 'MINIMUM DISTANCE TO END POINT (per game, then aggregated):\n');
fprintf(fid, '  Min across games:  %.3f cm (closest any obstacle gets to end)\n', min(study_min_dist_to_end));
fprintf(fid, '  Max across games:  %.3f cm\n', max(study_min_dist_to_end));
fprintf(fid, '  Mean across games: %.3f cm\n', mean(study_min_dist_to_end));
fprintf(fid, '  Std across games:  %.3f cm\n\n', std(study_min_dist_to_end));

% ----------------------------------------------------------------------------
% THESIS-READY SUMMARY TABLE
% ----------------------------------------------------------------------------
fprintf(fid, '\n================================================================================\n');
fprintf(fid, 'SUMMARY TABLE (THESIS-READY FORMAT)\n');
fprintf(fid, '================================================================================\n\n');

fprintf(fid, 'Table 1: Geometric Properties of STUDY GAMES (Sets 1-12, N=%d games)\n\n', num_study_games);
fprintf(fid, '%-40s | %8s | %8s | %8s | %8s\n', 'Property', 'Min', 'Max', 'Mean', 'Std');
fprintf(fid, '--------------------------------------------------------------------------------\n');
fprintf(fid, '%-40s | %8.3f | %8.3f | %8.3f | %8.3f\n', 'Obstacle Radius (cm)', ...
    min(study_radii), max(study_radii), mean(study_radii), std(study_radii));
fprintf(fid, '%-40s | %8.3f | %8.3f | %8.3f | %8.3f\n', 'Min Gate Width per Game (cm)', ...
    min(study_min_pair_distances), max(study_min_pair_distances), mean(study_min_pair_distances), std(study_min_pair_distances));
fprintf(fid, '%-40s | %8.3f | %8.3f | %8.3f | %8.3f\n', 'Mean Gate Width per Game (cm)', ...
    min(study_mean_pair_distances), max(study_mean_pair_distances), mean(study_mean_pair_distances), std(study_mean_pair_distances));
fprintf(fid, '%-40s | %8.3f | %8.3f | %8.3f | %8.3f\n', 'Min Inter-Pair Distance per Game (cm)', ...
    min(study_min_interpair_distances), max(study_min_interpair_distances), mean(study_min_interpair_distances), std(study_min_interpair_distances));
fprintf(fid, '%-40s | %8.3f | %8.3f | %8.3f | %8.3f\n', 'Min Distance to Start per Game (cm)', ...
    min(study_min_dist_to_start), max(study_min_dist_to_start), mean(study_min_dist_to_start), std(study_min_dist_to_start));
fprintf(fid, '%-40s | %8.3f | %8.3f | %8.3f | %8.3f\n', 'Min Distance to End per Game (cm)', ...
    min(study_min_dist_to_end), max(study_min_dist_to_end), mean(study_min_dist_to_end), std(study_min_dist_to_end));

fprintf(fid, '\n\n');
fprintf(fid, 'Table 2: Geometric Properties of BASELINE GAME (Set 0)\n\n');
fprintf(fid, '%-40s | %8s\n', 'Property', 'Value');
fprintf(fid, '--------------------------------------------------------------------------------\n');
fprintf(fid, '%-40s | %8.3f - %8.3f\n', 'Obstacle Radius Range (cm)', min(baseline_radii), max(baseline_radii));
fprintf(fid, '%-40s | %8.3f\n', 'Mean Obstacle Radius (cm)', mean(baseline_radii));
fprintf(fid, '%-40s | %8.3f\n', 'Min Gate Width (cm)', baseline_min_pair_distance);
fprintf(fid, '%-40s | %8.3f\n', 'Min Inter-Pair Distance (cm)', baseline_min_interpair_distance);
fprintf(fid, '%-40s | %8.3f\n', 'Min Distance to Start (cm)', baseline_min_dist_to_start);
fprintf(fid, '%-40s | %8.3f\n', 'Min Distance to End (cm)', baseline_min_dist_to_end);

fprintf(fid, '\n\nNote: All distances are clear distances (edge-to-edge, not center-to-center)\n');
fprintf(fid, 'Gate width = distance between obstacles within the same pair\n');
fprintf(fid, 'Inter-pair distance = distance between obstacles from different pairs\n');

% ----------------------------------------------------------------------------
% CONSTRAINT VALIDATION SECTION
% ----------------------------------------------------------------------------
fprintf(fid, '\n\n================================================================================\n');
fprintf(fid, 'VALIDATION AGAINST EXPECTED CONSTRAINTS\n');
fprintf(fid, '================================================================================\n\n');
fprintf(fid, 'Expected constraints from game creation (create_obstacle_sets.m):\n');
fprintf(fid, '  Obstacle radius range: %.2f - %.2f cm\n', EXPECTED_MIN_RADIUS, EXPECTED_MAX_RADIUS);
fprintf(fid, '  Gate width (same pair): %.2f - %.2f cm\n', EXPECTED_MIN_PAIR_DISTANCE, EXPECTED_MAX_PAIR_DISTANCE);
fprintf(fid, '  Min inter-pair distance: >= %.2f cm\n', EXPECTED_MIN_INTERPAIR_DISTANCE);
fprintf(fid, '  Min distance to start/end: >= %.2f cm\n\n', EXPECTED_MIN_DIST_TO_START_END);

fprintf(fid, 'Validation Results:\n');
fprintf(fid, '-------------------\n');

fprintf(fid, '--- STUDY GAMES (Sets 1-12) ---\n\n');

% Check radius constraints
radius_violations = sum(study_radii < EXPECTED_MIN_RADIUS) + sum(study_radii > EXPECTED_MAX_RADIUS);
if radius_violations == 0
    fprintf(fid, '✓ All obstacle radii within expected range [%.2f, %.2f] cm\n', ...
        EXPECTED_MIN_RADIUS, EXPECTED_MAX_RADIUS);
else
    fprintf(fid, '✗ %d obstacle radius violations found\n', radius_violations);
end

% Check gate width constraints (both min and max)
gate_min_violations = sum(study_min_pair_distances < EXPECTED_MIN_PAIR_DISTANCE);
gate_max_violations = 0;  % Check if any individual gate exceeds max
for idx = 1:num_games
    g = game_results(idx);
    if g.game_num ~= baseline_idx
        if g.max_pair_distance > EXPECTED_MAX_PAIR_DISTANCE
            gate_max_violations = gate_max_violations + 1;
        end
    end
end

if gate_min_violations == 0 && gate_max_violations == 0
    fprintf(fid, '✓ All gate widths within range [%.2f, %.2f] cm (narrowest: %.3f cm)\n', ...
        EXPECTED_MIN_PAIR_DISTANCE, EXPECTED_MAX_PAIR_DISTANCE, min(study_min_pair_distances));
else
    if gate_min_violations > 0
        fprintf(fid, '✗ %d games with gate width < %.2f cm (narrowest: %.3f cm)\n', ...
            gate_min_violations, EXPECTED_MIN_PAIR_DISTANCE, min(study_min_pair_distances));
    end
    if gate_max_violations > 0
        fprintf(fid, '✗ %d games with gate width > %.2f cm\n', ...
            gate_max_violations, EXPECTED_MAX_PAIR_DISTANCE);
    end
end

% Check inter-pair distance constraints
interpair_violations = sum(study_min_interpair_distances < EXPECTED_MIN_INTERPAIR_DISTANCE);
if interpair_violations == 0
    fprintf(fid, '✓ All inter-pair distances >= %.2f cm (closest: %.3f cm)\n', ...
        EXPECTED_MIN_INTERPAIR_DISTANCE, min(study_min_interpair_distances));
else
    fprintf(fid, '✗ %d games with inter-pair distance violations (closest: %.3f cm)\n', ...
        interpair_violations, min(study_min_interpair_distances));
end

% Check start point distance constraints
start_violations = sum(study_min_dist_to_start < EXPECTED_MIN_DIST_TO_START_END);
if start_violations == 0
    fprintf(fid, '✓ All start distances >= %.2f cm (closest: %.3f cm)\n', ...
        EXPECTED_MIN_DIST_TO_START_END, min(study_min_dist_to_start));
else
    fprintf(fid, '✗ %d games with start distance violations (closest: %.3f cm)\n', ...
        start_violations, min(study_min_dist_to_start));
end

% Check end point distance constraints
end_violations = sum(study_min_dist_to_end < EXPECTED_MIN_DIST_TO_START_END);
if end_violations == 0
    fprintf(fid, '✓ All end distances >= %.2f cm (closest: %.3f cm)\n', ...
        EXPECTED_MIN_DIST_TO_START_END, min(study_min_dist_to_end));
else
    fprintf(fid, '✗ %d games with end distance violations (closest: %.3f cm)\n', ...
        end_violations, min(study_min_dist_to_end));
end

fprintf(fid, '\n');
total_violations = radius_violations + gate_min_violations + gate_max_violations + ...
    interpair_violations + start_violations + end_violations;
if total_violations == 0
    fprintf(fid, '✓✓✓ ALL STUDY GAMES PASS VALIDATION CONSTRAINTS ✓✓✓\n');
else
    fprintf(fid, '⚠ Total violations: %d\n', total_violations);
    fprintf(fid, 'Note: Some violations may be acceptable if they are minor or due to\n');
    fprintf(fid, 'rounding differences in the validation thresholds.\n');
end

% ----------------------------------------------------------------------------
% PER-GAME SUMMARY TABLE
% ----------------------------------------------------------------------------
fprintf(fid, '\n\n================================================================================\n');
fprintf(fid, 'PER-GAME SUMMARY TABLE - STUDY GAMES (SETS 1-12)\n');
fprintf(fid, '================================================================================\n\n');

fprintf(fid, 'Game | Pairs | Radius(min) | Radius(max) | Min Gate | Mean Gate | Min Inter | Min->Start | Min->End\n');
fprintf(fid, '     |       |     (cm)    |     (cm)    |   (cm)   |   (cm)    |   (cm)    |    (cm)    |   (cm)\n');
fprintf(fid, '----------------------------------------------------------------------------------------------------\n');

for idx = 1:num_games
    g = game_results(idx);
    if g.game_num == baseline_idx
        continue;  % Skip baseline
    end
    fprintf(fid, '%4d | %5d | %11.3f | %11.3f | %8.3f | %9.3f | %9.3f | %10.3f | %8.3f\n', ...
        g.game_num, g.num_pairs, g.radii_min, g.radii_max, ...
        g.min_pair_distance, g.mean_pair_distance, g.min_interpair_distance, ...
        g.min_dist_to_start, g.min_dist_to_end);
end

fprintf(fid, '\n\n');
fprintf(fid, 'PER-GAME SUMMARY TABLE - BASELINE GAME (SET 0)\n');
fprintf(fid, '================================================================================\n\n');

fprintf(fid, 'Game | Pairs | Radius(min) | Radius(max) | Min Gate | Min Inter | Min->Start | Min->End\n');
fprintf(fid, '     |       |     (cm)    |     (cm)    |   (cm)   |   (cm)    |    (cm)    |   (cm)\n');
fprintf(fid, '--------------------------------------------------------------------------------\n');

for idx = 1:num_games
    g = game_results(idx);
    if g.game_num ~= baseline_idx
        continue;  % Skip study games
    end
    fprintf(fid, '%4d | %5d | %11.3f | %11.3f | %8.3f | %9.3f | %10.3f | %8.3f\n', ...
        g.game_num, g.num_pairs, g.radii_min, g.radii_max, ...
        g.min_pair_distance, g.min_interpair_distance, ...
        g.min_dist_to_start, g.min_dist_to_end);
end

fprintf(fid, '\n================================================================================\n');
fprintf(fid, 'END OF REPORT\n');
fprintf(fid, '================================================================================\n');

fclose(fid);

fprintf('\n================================================================================\n');
fprintf('Report saved to: %s\n', output_file);
fprintf('================================================================================\n');

% ============================================================================
% DISPLAY SUMMARY TO CONSOLE
% ============================================================================
fprintf('\nQUICK SUMMARY:\n');
fprintf('\n--- BASELINE GAME (Set 0) ---\n');
fprintf('  Total obstacles: %d\n', length(baseline_radii));
fprintf('  Obstacle radii range: %.3f - %.3f cm (mean: %.3f cm)\n', ...
    min(baseline_radii), max(baseline_radii), mean(baseline_radii));
fprintf('  Narrowest gate: %.3f cm\n', baseline_min_pair_distance);
fprintf('  Closest inter-pair distance: %.3f cm\n', baseline_min_interpair_distance);

fprintf('\n--- STUDY GAMES (Sets 1-12) ---\n');
fprintf('  Games analyzed: %d\n', num_study_games);
fprintf('  Total obstacles: %d\n', length(study_radii));
fprintf('  Obstacle radii range: %.3f - %.3f cm (mean: %.3f cm)\n', ...
    min(study_radii), max(study_radii), mean(study_radii));
fprintf('  Gate widths:\n');
fprintf('    Narrowest gate (min across games): %.3f cm\n', min(study_min_pair_distances));
fprintf('    Widest narrowest gate (max of mins): %.3f cm\n', max(study_min_pair_distances));
fprintf('    Mean gate width per game (mean of means): %.3f cm\n', mean(study_mean_pair_distances));
fprintf('    Range of mean gate widths: %.3f - %.3f cm\n', ...
    min(study_mean_pair_distances), max(study_mean_pair_distances));
fprintf('  Closest inter-pair distance: %.3f cm\n', min(study_min_interpair_distances));
fprintf('  Distance to start (min-max across games): %.3f - %.3f cm\n', ...
    min(study_min_dist_to_start), max(study_min_dist_to_start));
fprintf('  Distance to end (min-max across games): %.3f - %.3f cm\n', ...
    min(study_min_dist_to_end), max(study_min_dist_to_end));
fprintf('\n');
