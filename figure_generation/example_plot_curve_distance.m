% EXAMPLE: Plot segment-wise distance analysis and game visualization
% This script demonstrates how to use plot_curve_distance_comparison.m
%
% The function creates TWO figures:
%   
%   Figure 1 (1x2 layout):
%     - Left: Distance between consecutive points (BEFORE equalization)
%       Each segment colored differently, Statistics: Mean, Std, Min, Max
%     - Right: Game environment with colored segments
%       Obstacles, start/end points, curve with same segment colors
%   
%   Figure 2 (2x2 layout):
%     - Subplot 1: Distance BEFORE equalization (repeated for reference)
%     - Subplot 2: Distance AFTER equalization
%     - Subplot 3: Distance with target spacing
%     - Subplot 4: Overall curve comparison

clc;
clear;

% ============================================================================
% EXAMPLE 1: Plot distance comparison for a specific set with custom spacing
% ============================================================================
set_number = 41;         % The set number to analyze
pairs_number = 3;        % Number of pairs in the set
target_spacing = 0.25;   % Target spacing in cm (0.25 cm = 2.5 mm)

% Optional: specify base folder (if different from default)
base_folder = 'C:\Users\mahboobe\OneDrive - University of Calgary\code\game_creation_and_fits\new_games\new_games';

% Call with custom target spacing
plot_curve_distance_comparison(set_number, pairs_number, base_folder, target_spacing);

% ============================================================================
% EXAMPLE 2: Use default 0.5 cm spacing
% ============================================================================
% Uncomment to use default 0.5 cm spacing:
% plot_curve_distance_comparison(set_number, pairs_number, base_folder);
% Or even simpler (uses current directory):
% plot_curve_distance_comparison(set_number, pairs_number);

% ============================================================================
% EXAMPLE 3: Analyze multiple sets
% ============================================================================
% Uncomment to analyze multiple sets:
% 
% set_numbers = [1, 2, 3, 4, 5];
% pairs_number = 3;
% target_spacing = 0.25;  % cm
% 
% for set_num = set_numbers
%     fprintf('\n\nAnalyzing Set %d...\n', set_num);
%     plot_curve_distance_comparison(set_num, pairs_number, base_folder, target_spacing);
%     pause(3);  % Pause between figures
% end

% ============================================================================
% What you'll see:
% ============================================================================
% Figure 1: BEFORE Equalization + Game Environment (side by side)
%   Left subplot:
%     - X-axis: Point index along the curve
%     - Y-axis: Distance between consecutive points (cm)
%     - Each segment shown in different color (Segment 1, 2, 3, 4)
%     - Statistics box showing Mean, Std, Min, Max
%   Right subplot:
%     - Gray circles: Obstacles
%     - Green marker: Start point
%     - Red marker: End point
%     - Colored curve: Each segment matches left plot colors
%
% Figure 2: Detailed Analysis (2x2 layout)
%   - Top-left: Distance BEFORE equalization (repeated)
%   - Top-right: Distance AFTER equalization (segment-wise)
%   - Bottom-left: Distance with target spacing (segment-wise)
%   - Bottom-right: Overall comparison of all three methods

