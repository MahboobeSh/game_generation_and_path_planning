% Script to add old_filename variable to game files
% This script reads all .mat files in game_sets_data/raw_games/
% and adds a variable 'old_filename' with the original file name

clc
clear

% Define the directory containing the raw games
raw_games_dir = fullfile(getenv('HOME'), 'Desktop', 'study_information', 'game_sets_data', 'raw_games');

% Check if directory exists
if ~exist(raw_games_dir, 'dir')
    error('Directory does not exist: %s', raw_games_dir);
end

% Get all .mat files in the directory
mat_files = dir(fullfile(raw_games_dir, '*.mat'));

if isempty(mat_files)
    fprintf('No .mat files found in: %s\n', raw_games_dir);
    return;
end

fprintf('Found %d .mat files in raw_games directory\n\n', length(mat_files));

% Process each file
for i = 1:length(mat_files)
    current_filename = mat_files(i).name;
    full_path = fullfile(raw_games_dir, current_filename);
    
    fprintf('Processing [%d/%d]: %s\n', i, length(mat_files), current_filename);
    
    % Load the file
    file_data = load(full_path);
    
    % Check if old_filename already exists
    if isfield(file_data, 'old_filename')
        fprintf('  -> old_filename already exists: %s (skipping)\n', file_data.old_filename);
        continue;
    end
    
    % Add the old_filename variable to the structure
    file_data.old_filename = current_filename;
    
    % Save back to the file with old_filename added
    save(full_path, '-struct', 'file_data');
    
    fprintf('  -> Added old_filename: %s\n', current_filename);
end

fprintf('\nProcessing complete!\n');
fprintf('Total files processed: %d\n', length(mat_files));

