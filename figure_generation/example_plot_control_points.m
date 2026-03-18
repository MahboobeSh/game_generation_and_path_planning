% Example script to generate Bezier control point visualization
% This script demonstrates how to use plot_bezier_control_points.m

clear;
clc;

% Configuration
save_figures = true;  % true = save to files, false = only display

base_folder = 'C:\Users\Mahboobe\OneDrive - University of Calgary\code\game_creation_and_fits';

script_dir = fileparts(mfilename('fullpath'));
output_folder = fullfile(script_dir, '..', 'logs', 'curve');
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

set_number = 14;
pairs_number = 3;

try
    plot_bezier_control_points(set_number, pairs_number, base_folder, save_figures, output_folder);
    fprintf('Successfully generated control point visualization!\n');
catch ME
    fprintf('Error: %s\n', ME.message);
    fprintf('Make sure the .mat file exists in the fit folder.\n');
end
