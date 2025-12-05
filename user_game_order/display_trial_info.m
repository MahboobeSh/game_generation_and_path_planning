% Script to display game order and subtraction tasks by trial
% Combines game_order_for_user_X.mat and subtraction_task_user_X.mat

clc
clear

% Prompt for user number
user_number = input('Enter user number to load: ');

% File names
game_order_file = sprintf('game_order_for_user_%d.mat', user_number);
subtraction_file = 'subtraction_task.mat';

% Check if files exist
if ~isfile(game_order_file)
    error('Game order file not found: %s', game_order_file);
end

if ~isfile(subtraction_file)
    error('Subtraction task file not found: %s', subtraction_file);
end

% Load both files
fprintf('\nLoading files for user %d...\n', user_number);
game_data = load(game_order_file);
subtraction_load = load(subtraction_file);

% Extract the structs
game_order = game_data.game_order;
subtraction_data = subtraction_load.subtraction_data;

% Verify we have the same number of trials
num_trials = length(game_order);
if length(subtraction_data) ~= num_trials
    warning('Number of game trials (%d) does not match subtraction tasks (%d)', ...
        num_trials, length(subtraction_data));
end

% Display combined trial information
fprintf('\n========================================================================\n');
fprintf('                   USER %d - TRIAL INFORMATION\n', user_number);
fprintf('========================================================================\n\n');

for i = 1:num_trials
    fprintf('╔═══════════════════════════════════════════════════════════════════╗\n');
    fprintf('║ TRIAL %2d                                                          ║\n', i);
    fprintf('╠═══════════════════════════════════════════════════════════════════╣\n');
    fprintf('║ GAME:                                                             ║\n');
    fprintf('║   Mode:       %-50s ║\n', game_order(i).mode);
    fprintf('║   Hand:       %-50s ║\n', game_order(i).hand);
    fprintf('║   Difficulty: %-50s ║\n', game_order(i).difficulty);
    fprintf('║   Game File:  %-50s ║\n', game_order(i).game_file);
    fprintf('║   Direction:  %-2d                                                 ║\n', game_order(i).direction);
    fprintf('╠═══════════════════════════════════════════════════════════════════╣\n');
    fprintf('║ COGNITIVE LOAD (Serial Subtraction):                             ║\n');
    fprintf('║   Starting Number: %-3d                                           ║\n', subtraction_data(i).starting_number);
    fprintf('║   Subtract By:     %-3d                                           ║\n', subtraction_data(i).subtract_by);
    fprintf('║   Task:            %-50s ║\n', subtraction_data(i).task);
    fprintf('╚═══════════════════════════════════════════════════════════════════╝\n\n');
end

% Display summary table
fprintf('\n========================================================================\n');
fprintf('                        SUMMARY TABLE\n');
fprintf('========================================================================\n\n');
fprintf('Trial | Game File  | Mode              | Difficulty | Direction | Subtraction Task\n');
fprintf('------|------------|-------------------|------------|-----------|------------------\n');
for i = 1:num_trials
    fprintf('%5d | %-10s | %-17s | %-10s | %9d | %s\n', ...
        i, ...
        game_order(i).game_file, ...
        game_order(i).mode, ...
        game_order(i).difficulty, ...
        game_order(i).direction, ...
        subtraction_data(i).task);
end
fprintf('\n');

% Store combined data in workspace
trial_info = struct();
for i = 1:num_trials
    trial_info(i).trial_number = i;
    trial_info(i).game_mode = game_order(i).mode;
    trial_info(i).game_hand = game_order(i).hand;
    trial_info(i).game_difficulty = game_order(i).difficulty;
    trial_info(i).game_file = game_order(i).game_file;
    trial_info(i).game_set_number = game_order(i).set_number;
    trial_info(i).game_direction = game_order(i).direction;
    trial_info(i).subtraction_start = subtraction_data(i).starting_number;
    trial_info(i).subtraction_value = subtraction_data(i).subtract_by;
    trial_info(i).subtraction_task = subtraction_data(i).task;
end

assignin('base', 'trial_info', trial_info);
assignin('base', 'game_order', game_order);
assignin('base', 'subtraction_data', subtraction_data);

fprintf('Combined trial information saved to workspace variable: trial_info\n\n');

% ========================================================================
% USAGE INSTRUCTIONS
% ========================================================================
%
% Access specific trial information:
% ----------------------------------
%   trial_info(1)                           % All info for trial 1
%   trial_info(5).game_file                 % Game file for trial 5
%   trial_info(5).subtraction_task          % Subtraction task for trial 5
%   trial_info(5).game_direction            % Direction for trial 5
%
% Loop through all trials:
% ------------------------
%   for i = 1:length(trial_info)
%       fprintf('Trial %d: %s with task %s\n', i, ...
%           trial_info(i).game_file, ...
%           trial_info(i).subtraction_task);
%   end

