% EXAMPLE: Visualize Steering Index for Games
% This script demonstrates how to use visualize_game_steering_index.m

clear; close all; clc;

% %% Example 1: Basic visualization (just show figure)
% fprintf('=== Example 1: Basic Visualization ===\n');
% 
% % Set path to a game file (relative to difficulty_metic_generation folder)
 base_path = fullfile('..', 'new_games', 'new_games');
 game_path = fullfile(base_path, '4pairs', 'fit', 'set_2_4pairs.mat');
% 
% % Visualize (just show, don't save)
% visualize_game_steering_index(game_path);
% 
% %% Example 2: Visualize and save figure
% fprintf('\n=== Example 2: Visualize and Save ===\n');
% 
% % Same game, but save the figure
% visualize_game_steering_index(game_path, 'save', true);
% This will save to: ../logs/thesis_figures/steering_index_set_2_4pairs.png

%% Example 3: Visualize and save to specific location
fprintf('\n=== Example 3: Save to Specific Path ===\n');

% Save with custom filename in ../logs/thesis_figures
output_folder = fullfile('..', 'logs', 'thesis_figures');
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end
output_file = fullfile(output_folder, 'game_set2_4pairs_steering.png');

visualize_game_steering_index(game_path, 'save', true, 'output_path', output_file);

%% Example 3b: Hide composite score in title
fprintf('\n=== Example 3b: Hide Composite Score ===\n');

% Show only steering index (not composite score)
visualize_game_steering_index(game_path, 'show_composite', false);

%% Example 4: Visualize multiple games
fprintf('\n=== Example 4: Visualize Multiple Games ===\n');

% Define multiple games to visualize
games = {
    struct('set', 30, 'pairs', 4);
    struct('set', 50, 'pairs', 4);
    struct('set', 61, 'pairs', 4);
    struct('set', 41, 'pairs', 3);
};

for i = 1:length(games)
    game_set = games{i}.set;
    game_pairs = games{i}.pairs;

    game_file = sprintf('set_%d_%dpairs.mat', game_set, game_pairs);
    game_full_path = fullfile(base_path, sprintf('%dpairs', game_pairs), 'fit', game_file);

    if exist(game_full_path, 'file')
        fprintf('\nVisualizing Game %d: Set %d, %d pairs\n', i, game_set, game_pairs);
        visualize_game_steering_index(game_full_path);

        % Optionally save each one
        % visualize_game_steering_index(game_full_path, 'save', true);
    else
        fprintf('Game file not found: %s\n', game_full_path);
    end
end

fprintf('\n=== All visualizations complete! ===\n');
