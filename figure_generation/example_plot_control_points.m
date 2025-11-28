% Example script to generate Bezier control point visualization
% This script demonstrates how to use plot_bezier_control_points.m

clear;
clc;

% Set the base folder (adjust to your path)
base_folder = 'C:\Users\mahbo\OneDrive - University of Calgary\code\game_creation_and_fits';
base_folder = "/home/mahboobe/Desktop/game_generation_and_path_planning/game"

% Example: Plot control points for set 14 with 3 pairs of obstacles
set_number = 14;
pairs_number = 3;

try
    plot_bezier_control_points(set_number, pairs_number, base_folder);
    fprintf('Successfully generated control point visualization!\n');
catch ME
    fprintf('Error: %s\n', ME.message);
    fprintf('Make sure the .mat file exists in the fit folder.\n');
end

