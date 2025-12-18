% EXAMPLE: Plot curve distance comparison before and after equalization
% This script demonstrates how to use plot_curve_distance_comparison.m

clc;
clear;

% ============================================================================
% EXAMPLE 1: Plot distance comparison for a specific set
% ============================================================================
set_number = 41;      % The set number to analyze
pairs_number = 3;    % Number of pairs in the set

% Optional: specify base folder (if different from default)
base_folder = 'C:\Users\mahbo\OneDrive - University of Calgary\code\game_creation_and_fits\new_games\new_games';
% plot_curve_distance_comparison(set_number, pairs_number, base_folder);

% Use default base folder (current directory)
plot_curve_distance_comparison(set_number, pairs_number, base_folder);

% ============================================================================
% EXAMPLE 2: Analyze multiple sets
% ============================================================================
% Uncomment to analyze multiple sets:
% 
% set_numbers = [1, 2, 3, 4, 5];
% pairs_number = 3;
% 
% for set_num = set_numbers
%     fprintf('\n\nAnalyzing Set %d...\n', set_num);
%     plot_curve_distance_comparison(set_num, pairs_number);
%     pause(2);  % Pause between figures
% end

