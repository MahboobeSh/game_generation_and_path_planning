% EXAMPLE: Validate an obstacle set
% This script demonstrates how to use validate_obstacle_set.m

clc;
clear;

% ============================================================================
% EXAMPLE 1: Validate a specific st
% ============================================================================
set_number = 44;      % The set number to validate
pairs_number = 3;    % Number of pairs in the set

% Optional: specify base folder (if different from default)
base_folder = 'C:\Users\mahbo\OneDrive - University of Calgary\code\game_creation_and_fits\new_games\selected_games_2';
base_folder = '/home/mahboobe/Desktop/game_generation_and_path_planning/new_games/final_games';
[all_passed, results] = validate_obstacle_set(set_number, pairs_number, base_folder);

% Use default base folder
% [all_passed, results] = validate_obstacle_set(set_number, pairs_number);

% ============================================================================
% EXAMPLE 2: Validate multiple sets
% ============================================================================
% Uncomment to validate multiple sets:
% 
% set_numbers = [1, 2, 3, 4, 5];
% pairs_number = 3;
% 
% for set_num = set_numbers
%     fprintf('\n\nValidating Set %d...\n', set_num);
%     [passed, res] = validate_obstacle_set(set_num, pairs_number);
%     if ~passed
%         fprintf('Set %d FAILED validation!\n', set_num);
%     end
% end

% ============================================================================
% EXAMPLE 3: Access detailed results programmatically
% ============================================================================
% After validation, you can access detailed results:
% 
% if ~results.check2_min_pair_distance.passed
%     fprintf('Pair distance violations:\n');
%     disp(results.check2_min_pair_distance.violations);
% end
% 
% if ~results.check5_obstacle_collisions.passed
%     fprintf('Obstacle collision violations:\n');
%     disp(results.check5_obstacle_collisions.violations);
% end

