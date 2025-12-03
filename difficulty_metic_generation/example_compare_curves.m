% EXAMPLE: Compare original curve vs equalized curve for rehab metrics
% This script demonstrates the different comparison modes

clear; clc;

% Configuration
set_numbers = [1, 2, 3];     % Game sets to compare
pairs_numbers = [5, 5, 5];   % Number of pairs for each set
% Note: step_size is automatically read from game data files

fprintf('=====================================================\n');
fprintf('REHAB METRICS VISUALIZATION - COMPARISON MODES\n');
fprintf('=====================================================\n\n');

fprintf('Available modes:\n');
fprintf('  1 - Show original and equalized side-by-side\n');
fprintf('  2 - Show only original curves\n');
fprintf('  3 - Show only equalized curves\n\n');

% Get user choice
fprintf('Choose a mode:\n');
fprintf('  [1] Both (default)\n');
fprintf('  [2] Original only\n');
fprintf('  [3] Equalized only\n');
user_choice = input('Enter choice (1-3): ');

if isempty(user_choice) || user_choice == 1
    comparison_mode = 1;
    fprintf('\nRunning comparison mode: BOTH\n');
elseif user_choice == 2
    comparison_mode = 2;
    fprintf('\nRunning comparison mode: ORIGINAL ONLY\n');
elseif user_choice == 3
    comparison_mode = 3;
    fprintf('\nRunning comparison mode: EQUALIZED ONLY\n');
else
    fprintf('\nInvalid choice, using default: BOTH\n');
    comparison_mode = 1;
end

fprintf('=====================================================\n\n');

% Run the visualization with selected mode
visualize_rehab_metrics(set_numbers, pairs_numbers, comparison_mode);

% Display what to look for based on mode
fprintf('\n=====================================================\n');
if comparison_mode == 1
    fprintf('WHAT TO LOOK FOR:\n');
    fprintf('  - Top row: Original curves with their metrics\n');
    fprintf('  - Middle row: Equalized curves with their metrics\n');
    fprintf('  - Bar chart: Side-by-side comparison\n');
    fprintf('  - Table: Shows percentage differences\n');
    fprintf('\nKey questions:\n');
    fprintf('  - Does equalization change Steering Index?\n');
    fprintf('  - Does equalization change K (Total Rotation)?\n');
    fprintf('  - How much does Composite Score differ?\n');
elseif comparison_mode == 2
    fprintf('WHAT TO LOOK FOR:\n');
    fprintf('  - Color-coded difficulty map (red=narrow, blue=wide)\n');
    fprintf('  - Steering Index values\n');
    fprintf('  - Composite Score (ID) values\n');
    fprintf('  - Path Length and Average Slope\n');
else
    fprintf('WHAT TO LOOK FOR:\n');
    fprintf('  - Uniform point spacing (step size from data)\n');
    fprintf('  - Color-coded difficulty map (red=narrow, blue=wide)\n');
    fprintf('  - How metrics compare to original (run mode 1)\n');
    fprintf('  - Path Length should be very similar to original\n');
end
fprintf('=====================================================\n');
