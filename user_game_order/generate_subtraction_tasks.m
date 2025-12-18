% Script to generate 12 random 3-digit numbers with associated 1-digit numbers
% For serial subtraction cognitive loading task

clc
clear

% Generate 12 unique random 3-digit numbers (100-999) for serial subtraction
num_trials = 12;
starting_numbers = randperm(900, num_trials) + 99;  % Generates numbers from 100 to 999

% Generate 12 random 1-digit numbers from specific set [3,4,6,7,8,9]
% Each digit appears exactly twice, but in random order (subtraction values)
allowed_digits = [3, 4, 6, 7, 8, 9];
subtraction_values = repmat(allowed_digits, 1, 2);  % Each digit twice: [3,4,6,7,8,9,3,4,6,7,8,9]
subtraction_values = subtraction_values(randperm(length(subtraction_values)))';  % Shuffle randomly

% Alternative: Random selection (digits may repeat more than twice)
% subtraction_values = allowed_digits(randi(length(allowed_digits), num_trials, 1));

% Alternative: Use 0-9 (all digits)
% subtraction_values = randi([0, 9], num_trials, 1);

% Alternative: Use 1-9 instead of 0-9
% subtraction_values = randi([1, 9], num_trials, 1);

% Alternative: Use sequential numbers 1-12
% subtraction_values = (1:num_trials)';

% Create a structured format for easy access
subtraction_data = struct();
for i = 1:num_trials
    subtraction_data(i).game_number = i;
    subtraction_data(i).starting_number = starting_numbers(i);
    subtraction_data(i).subtract_by = subtraction_values(i);
    subtraction_data(i).task = sprintf('%d - %d', starting_numbers(i), subtraction_values(i));
end

% Display the results
fprintf('\n=== Serial Subtraction Tasks ===\n\n');
fprintf('Game | Starting | Subtract | Task\n');
fprintf('------|----------|----------|-------------\n');
for i = 1:num_trials
    fprintf('%5d | %8d | %8d | %s\n', ...
        subtraction_data(i).game_number, ...
        subtraction_data(i).starting_number, ...
        subtraction_data(i).subtract_by, ...
        subtraction_data(i).task);
end
fprintf('\n');

% Save to MAT file
save_to_mat = true;  % Set to false if you don't want to save
if save_to_mat
    % Prompt for user number
    user_number = input('Enter user number (e.g., 1, 2, 3... or 0 to skip saving): ');
    
    if user_number == 0
        fprintf('\nFile not saved (user number = 0).\n\n');
    else
        mat_filename = sprintf('subtraction_task_user_%d.mat', user_number);
        
        % Save to .mat file
        save(mat_filename, 'subtraction_data', 'starting_numbers', 'subtraction_values');
        fprintf('\nSerial subtraction tasks saved to MAT file: %s\n', mat_filename);
        fprintf('\nTo load and use:\n');
        fprintf('  load(''%s'')\n', mat_filename);
        fprintf('  trial_1 = subtraction_data(1)\n');
        fprintf('  starting = subtraction_data(1).starting_number\n');
        fprintf('  subtract = subtraction_data(1).subtract_by\n\n');
    end
end

% Store in workspace for further use
assignin('base', 'subtraction_data', subtraction_data);
assignin('base', 'starting_numbers', starting_numbers);
assignin('base', 'subtraction_values', subtraction_values);

% ========================================================================
% USAGE INSTRUCTIONS
% ========================================================================
%
% Load from MAT file:
% -------------------
%   load('subtraction_task_user_1.mat')
%   
%   % Access first trial
%   trial_1 = subtraction_data(1)
%   
%   % Get specific trial information
%   trial_num = 5;
%   starting = subtraction_data(trial_num).starting_number
%   subtract_by = subtraction_data(trial_num).subtract_by
%   task = subtraction_data(trial_num).task
%   
%   % Loop through all trials
%   for i = 1:length(subtraction_data)
%       fprintf('Trial %d: %s (start: %d, subtract: %d)\n', i, ...
%           subtraction_data(i).task, ...
%           subtraction_data(i).starting_number, ...
%           subtraction_data(i).subtract_by);
%   end
%   
%   % Access just the arrays
%   all_starting = [subtraction_data.starting_number]
%   all_subtract = [subtraction_data.subtract_by]

