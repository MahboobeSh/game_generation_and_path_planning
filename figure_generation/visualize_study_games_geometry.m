% visualize_study_games_geometry.m
% Creates visualizations of geometric properties from study games
%
% Run analyze_study_games_geometry.m first to generate the data
% This script loads the analyzed data and creates publication-quality figures
% NOTE: Set 0 (baseline) is analyzed separately from Sets 1-12 (study games)

clc; clear; close all;

% ============================================================================
% CONFIGURATION
% ============================================================================
base_path = 'C:\Users\Mahboobe\OneDrive - University of Calgary\user_study_info\user_study_files_with_survey\user_study_files';
games_folder = fullfile(base_path, 'final_games_solved');
output_folder = fullfile(fileparts(mfilename('fullpath')));

% Game indices - separate baseline from study games
baseline_idx = 0;
study_indices = 1:12;
all_game_indices = [baseline_idx, study_indices];
num_games = length(all_game_indices);

% ============================================================================
% LOAD AND ANALYZE ALL GAMES
% ============================================================================
game_data_array = cell(num_games, 1);

for idx = 1:num_games
    game_num = all_game_indices(idx);
    game_file = fullfile(games_folder, sprintf('set_%d_fit.mat', game_num));
    
    if exist(game_file, 'file')
        game_data_array{idx} = load(game_file);
        game_data_array{idx}.game_num = game_num;
    end
end

% Extract data for plotting
all_radii = [];
min_pair_distances = zeros(num_games, 1);
min_interpair_distances = zeros(num_games, 1);
min_dist_to_start = zeros(num_games, 1);
min_dist_to_end = zeros(num_games, 1);
num_pairs_array = zeros(num_games, 1);

for idx = 1:num_games
    if ~isempty(game_data_array{idx})
        gdata = game_data_array{idx};
        
        % Collect all radii (ensure column vector)
        all_radii = [all_radii; gdata.obstacle_radious(:)];
        
        % Number of pairs
        if isfield(gdata, 'number_of_pairs')
            num_pairs = gdata.number_of_pairs;
        else
            num_pairs = size(gdata.obstacle, 1) / 2;
        end
        num_pairs_array(idx) = num_pairs;
        
        % Calculate pair distances
        pair_dists = [];
        for pair_idx = 1:num_pairs
            obs1_idx = 2 * pair_idx - 1;
            obs2_idx = 2 * pair_idx;
            
            center1 = gdata.obstacle(obs1_idx, :);
            center2 = gdata.obstacle(obs2_idx, :);
            radius1 = gdata.obstacle_radious(obs1_idx);
            radius2 = gdata.obstacle_radious(obs2_idx);
            
            center_distance = norm(center1 - center2);
            clear_distance = center_distance - radius1 - radius2;
            pair_dists = [pair_dists; clear_distance];
        end
        min_pair_distances(idx) = min(pair_dists);
        
        % Calculate interpair distances
        num_obstacles = size(gdata.obstacle, 1);
        interpair_dists = [];
        for i = 1:num_obstacles
            for j = i+1:num_obstacles
                pair_i = ceil(i / 2);
                pair_j = ceil(j / 2);
                
                if pair_i ~= pair_j
                    center1 = gdata.obstacle(i, :);
                    center2 = gdata.obstacle(j, :);
                    radius1 = gdata.obstacle_radious(i);
                    radius2 = gdata.obstacle_radious(j);
                    
                    center_distance = norm(center1 - center2);
                    clear_distance = center_distance - radius1 - radius2;
                    interpair_dists = [interpair_dists; clear_distance];
                end
            end
        end
        min_interpair_distances(idx) = min(interpair_dists);
        
        % Distances to start/end
        dists_start = zeros(num_obstacles, 1);
        dists_end = zeros(num_obstacles, 1);
        for i = 1:num_obstacles
            center = gdata.obstacle(i, :);
            radius = gdata.obstacle_radious(i);
            
            dists_start(i) = norm(gdata.X_s - center) - radius;
            dists_end(i) = norm(gdata.X_e - center) - radius;
        end
        min_dist_to_start(idx) = min(dists_start);
        min_dist_to_end(idx) = min(dists_end);
    end
end

% ============================================================================
% CREATE FIGURE 1: OVERVIEW OF KEY METRICS
% ============================================================================
figure('Position', [100, 100, 1200, 800]);

% Subplot 1: Obstacle Radii Distribution
subplot(2, 3, 1);
histogram(all_radii, 15, 'FaceColor', [0.3, 0.6, 0.9], 'EdgeColor', 'k');
xlabel('Obstacle Radius (cm)', 'FontSize', 11);
ylabel('Frequency', 'FontSize', 11);
title('Distribution of Obstacle Radii', 'FontSize', 12, 'FontWeight', 'bold');
grid on;
text(0.05, 0.95, sprintf('Min: %.2f cm\nMax: %.2f cm\nMean: %.2f cm', ...
    min(all_radii), max(all_radii), mean(all_radii)), ...
    'Units', 'normalized', 'VerticalAlignment', 'top', 'FontSize', 9, ...
    'BackgroundColor', 'white', 'EdgeColor', 'black');

% Subplot 2: Minimum Gate Widths per Game
subplot(2, 3, 2);
bar_colors = [0.7, 0.7, 0.7; repmat([0.9, 0.5, 0.3], length(study_indices), 1)];  % Gray for baseline, orange for study
hold on;
for i = 1:num_games
    bar(all_game_indices(i), min_pair_distances(i), 'FaceColor', bar_colors(i,:), 'EdgeColor', 'k');
end
hold off;
xlabel('Game Number', 'FontSize', 11);
ylabel('Min Gate Width (cm)', 'FontSize', 11);
title('Narrowest Gate per Game', 'FontSize', 12, 'FontWeight', 'bold');
legend({'Baseline (Set 0)', 'Study Games'}, 'Location', 'best', 'FontSize', 9);
grid on;
ylim([0, max(min_pair_distances) * 1.1]);

% Subplot 3: Minimum Inter-Pair Distances
subplot(2, 3, 3);
bar_colors = [0.7, 0.7, 0.7; repmat([0.4, 0.8, 0.4], length(study_indices), 1)];
hold on;
for i = 1:num_games
    bar(all_game_indices(i), min_interpair_distances(i), 'FaceColor', bar_colors(i,:), 'EdgeColor', 'k');
end
hold off;
xlabel('Game Number', 'FontSize', 11);
ylabel('Min Distance (cm)', 'FontSize', 11);
title('Closest Inter-Pair Distance per Game', 'FontSize', 12, 'FontWeight', 'bold');
grid on;
ylim([0, max(min_interpair_distances) * 1.1]);

% Subplot 4: Distance to Start Point
subplot(2, 3, 4);
bar_colors = [0.7, 0.7, 0.7; repmat([0.8, 0.4, 0.8], length(study_indices), 1)];
hold on;
for i = 1:num_games
    bar(all_game_indices(i), min_dist_to_start(i), 'FaceColor', bar_colors(i,:), 'EdgeColor', 'k');
end
hold off;
xlabel('Game Number', 'FontSize', 11);
ylabel('Min Distance (cm)', 'FontSize', 11);
title('Closest Obstacle to Start Point', 'FontSize', 12, 'FontWeight', 'bold');
grid on;
ylim([0, max(min_dist_to_start) * 1.1]);

% Subplot 5: Distance to End Point
subplot(2, 3, 5);
bar_colors = [0.7, 0.7, 0.7; repmat([0.9, 0.7, 0.3], length(study_indices), 1)];
hold on;
for i = 1:num_games
    bar(all_game_indices(i), min_dist_to_end(i), 'FaceColor', bar_colors(i,:), 'EdgeColor', 'k');
end
hold off;
xlabel('Game Number', 'FontSize', 11);
ylabel('Min Distance (cm)', 'FontSize', 11);
title('Closest Obstacle to End Point', 'FontSize', 12, 'FontWeight', 'bold');
grid on;
ylim([0, max(min_dist_to_end) * 1.1]);

% Subplot 6: Number of Pairs per Game
subplot(2, 3, 6);
bar_colors = [0.5, 0.5, 0.5; repmat([0.6, 0.6, 0.6], length(study_indices), 1)];
hold on;
for i = 1:num_games
    bar(all_game_indices(i), num_pairs_array(i), 'FaceColor', bar_colors(i,:), 'EdgeColor', 'k');
end
hold off;
xlabel('Game Number', 'FontSize', 11);
ylabel('Number of Pairs', 'FontSize', 11);
title('Obstacle Pairs per Game', 'FontSize', 12, 'FontWeight', 'bold');
grid on;
ylim([0, max(num_pairs_array) * 1.1]);

% Overall title
sgtitle('Geometric Analysis of User Study Games (Gray = Baseline, Colors = Study Games)', ...
        'FontSize', 13, 'FontWeight', 'bold');

% Save figure
saveas(gcf, fullfile(output_folder, 'study_games_geometry_overview.png'));
saveas(gcf, fullfile(output_folder, 'study_games_geometry_overview.eps'), 'epsc');

fprintf('Saved: study_games_geometry_overview.png/eps\n');

% ============================================================================
% CREATE FIGURE 2: BOX PLOTS FOR STATISTICAL OVERVIEW
% ============================================================================
figure('Position', [150, 150, 1000, 600]);

% Prepare data for box plots
box_data = [min_pair_distances, min_interpair_distances, ...
            min_dist_to_start, min_dist_to_end];
box_labels = {'Min Gate Width', 'Min Inter-Pair Dist', ...
              'Min Dist to Start', 'Min Dist to End'};

boxplot(box_data, 'Labels', box_labels, 'Colors', 'k');
ylabel('Distance (cm)', 'FontSize', 12);
title('Statistical Distribution of Minimum Distances Across All Games', ...
      'FontSize', 13, 'FontWeight', 'bold');
grid on;

% Add mean markers
hold on;
means = mean(box_data, 1);
plot(1:4, means, 'rd', 'MarkerSize', 10, 'MarkerFaceColor', 'r', 'LineWidth', 2);
legend('Mean', 'Location', 'best');
hold off;

% Save figure
saveas(gcf, fullfile(output_folder, 'study_games_geometry_boxplots.png'));
saveas(gcf, fullfile(output_folder, 'study_games_geometry_boxplots.eps'), 'epsc');

fprintf('Saved: study_games_geometry_boxplots.png/eps\n');

% ============================================================================
% CREATE FIGURE 3: CORRELATION ANALYSIS
% ============================================================================
figure('Position', [200, 200, 1000, 800]);

% Subplot 1: Gate Width vs Number of Pairs
subplot(2, 2, 1);
scatter(num_pairs_array, min_pair_distances, 100, 'filled', 'MarkerFaceColor', [0.3, 0.6, 0.9]);
xlabel('Number of Obstacle Pairs', 'FontSize', 11);
ylabel('Min Gate Width (cm)', 'FontSize', 11);
title('Gate Width vs. Number of Pairs', 'FontSize', 12, 'FontWeight', 'bold');
grid on;
% Add correlation coefficient
corr_coef = corrcoef(num_pairs_array, min_pair_distances);
text(0.05, 0.95, sprintf('r = %.3f', corr_coef(1,2)), ...
    'Units', 'normalized', 'VerticalAlignment', 'top', ...
    'BackgroundColor', 'white', 'EdgeColor', 'black', 'FontSize', 10);

% Subplot 2: Inter-Pair Distance vs Number of Pairs
subplot(2, 2, 2);
scatter(num_pairs_array, min_interpair_distances, 100, 'filled', 'MarkerFaceColor', [0.9, 0.5, 0.3]);
xlabel('Number of Obstacle Pairs', 'FontSize', 11);
ylabel('Min Inter-Pair Distance (cm)', 'FontSize', 11);
title('Inter-Pair Distance vs. Number of Pairs', 'FontSize', 12, 'FontWeight', 'bold');
grid on;
corr_coef = corrcoef(num_pairs_array, min_interpair_distances);
text(0.05, 0.95, sprintf('r = %.3f', corr_coef(1,2)), ...
    'Units', 'normalized', 'VerticalAlignment', 'top', ...
    'BackgroundColor', 'white', 'EdgeColor', 'black', 'FontSize', 10);

% Subplot 3: Start Distance vs Number of Pairs
subplot(2, 2, 3);
scatter(num_pairs_array, min_dist_to_start, 100, 'filled', 'MarkerFaceColor', [0.4, 0.8, 0.4]);
xlabel('Number of Obstacle Pairs', 'FontSize', 11);
ylabel('Min Distance to Start (cm)', 'FontSize', 11);
title('Start Distance vs. Number of Pairs', 'FontSize', 12, 'FontWeight', 'bold');
grid on;
corr_coef = corrcoef(num_pairs_array, min_dist_to_start);
text(0.05, 0.95, sprintf('r = %.3f', corr_coef(1,2)), ...
    'Units', 'normalized', 'VerticalAlignment', 'top', ...
    'BackgroundColor', 'white', 'EdgeColor', 'black', 'FontSize', 10);

% Subplot 4: End Distance vs Number of Pairs
subplot(2, 2, 4);
scatter(num_pairs_array, min_dist_to_end, 100, 'filled', 'MarkerFaceColor', [0.8, 0.4, 0.8]);
xlabel('Number of Obstacle Pairs', 'FontSize', 11);
ylabel('Min Distance to End (cm)', 'FontSize', 11);
title('End Distance vs. Number of Pairs', 'FontSize', 12, 'FontWeight', 'bold');
grid on;
corr_coef = corrcoef(num_pairs_array, min_dist_to_end);
text(0.05, 0.95, sprintf('r = %.3f', corr_coef(1,2)), ...
    'Units', 'normalized', 'VerticalAlignment', 'top', ...
    'BackgroundColor', 'white', 'EdgeColor', 'black', 'FontSize', 10);

sgtitle('Correlation Between Game Complexity and Geometric Constraints', ...
        'FontSize', 14, 'FontWeight', 'bold');

% Save figure
saveas(gcf, fullfile(output_folder, 'study_games_geometry_correlations.png'));
saveas(gcf, fullfile(output_folder, 'study_games_geometry_correlations.eps'), 'epsc');

fprintf('Saved: study_games_geometry_correlations.png/eps\n');

% ============================================================================
% SUMMARY STATISTICS
% ============================================================================
fprintf('\n================================================================================\n');
fprintf('VISUALIZATION COMPLETE\n');
fprintf('================================================================================\n');
fprintf('Output folder: %s\n\n', output_folder);
fprintf('Generated figures:\n');
fprintf('  1. study_games_geometry_overview.png/eps\n');
fprintf('  2. study_games_geometry_boxplots.png/eps\n');
fprintf('  3. study_games_geometry_correlations.png/eps\n');
fprintf('\nSummary Statistics:\n');
fprintf('  Obstacle radii: %.2f - %.2f cm (mean: %.2f ± %.2f cm)\n', ...
    min(all_radii), max(all_radii), mean(all_radii), std(all_radii));
fprintf('  Gate widths: %.2f - %.2f cm (mean: %.2f ± %.2f cm)\n', ...
    min(min_pair_distances), max(min_pair_distances), ...
    mean(min_pair_distances), std(min_pair_distances));
fprintf('  Inter-pair distances: %.2f - %.2f cm (mean: %.2f ± %.2f cm)\n', ...
    min(min_interpair_distances), max(min_interpair_distances), ...
    mean(min_interpair_distances), std(min_interpair_distances));
fprintf('================================================================================\n');
