% VISUALIZE_SELECTED_GAMES - Easy interface to visualize games with metrics
%
% This script lets you easily visualize games from your selected_games folders
%
% USAGE:
%   1. Uncomment one of the example lines below, OR
%   2. Manually specify game(s) to visualize
%
% Examples:
%   - Single game by set number and pairs
%   - Multiple games
%   - All games from suggestions
%   - Batch process and save figures

%% CONFIGURATION
base_folder = '/home/mahboobe/Desktop/game_generation_and_path_planning/new_games/selected_games_3';

%% METHOD 1: Visualize specific game(s) by set number and pairs
% Example: Visualize set 44, 3 pairs
% visualize_game_with_metrics(fullfile(base_folder, '3pairs/fit/set_44_3pairs.mat'));

% Example: Visualize multiple games
% games_to_visualize = {
%     fullfile(base_folder, '3pairs/fit/set_44_3pairs.mat'),
%     fullfile(base_folder, '4pairs/fit/set_200_4pairs.mat'),
%     fullfile(base_folder, '5pairs/fit/set_26_5pairs.mat')
% };
% for i = 1:length(games_to_visualize)
%     visualize_game_with_metrics(games_to_visualize{i});
% end

%% METHOD 2: Visualize games from suggestions (run select_games_for_study first)
% First, run select_games_for_study to get suggestions
% Then uncomment and run this section:

% if exist('suggestions', 'var')
%     fprintf('Visualizing %d suggested games...\n', length(suggestions));
%     for i = 1:length(suggestions)
%         % Find the full path
%         game_name = suggestions(i).game;
%         pairs = suggestions(i).pairs;
%         game_path = fullfile(base_folder, sprintf('%dpairs/fit', pairs), game_name);
%         
%         fprintf('\n[%d/%d] %s (%s, score: %.2f)\n', ...
%             i, length(suggestions), game_name, suggestions(i).category, suggestions(i).score);
%         
%         if exist(game_path, 'file')
%             visualize_game_with_metrics(game_path);
%         else
%             warning('File not found: %s', game_path);
%         end
%     end
% else
%     error('Run select_games_for_study first to generate suggestions');
% end

%% METHOD 3: Interactive selection
fprintf('=== GAME VISUALIZATION TOOL ===\n\n');
fprintf('Available options:\n');
fprintf('1. Enter game details manually (set number, pairs)\n');
fprintf('2. Browse and select .mat file\n');
fprintf('3. Visualize from suggestions (requires running select_games_for_study first)\n');
fprintf('4. Batch visualize and save all suggested games\n\n');

choice = input('Select option (1-4): ');

switch choice
    case 1
        % Manual entry
        set_num = input('Enter set number (e.g., 44): ');
        pairs = input('Enter number of pairs (3, 4, or 5): ');
        
        game_path = fullfile(base_folder, sprintf('%dpairs/fit', pairs), ...
            sprintf('set_%d_%dpairs.mat', set_num, pairs));
        
        if exist(game_path, 'file')
            visualize_game_with_metrics(game_path);
        else
            error('Game not found: %s', game_path);
        end
        
    case 2
        % File browser
        [filename, pathname] = uigetfile('*.mat', 'Select game file', base_folder);
        if filename ~= 0
            visualize_game_with_metrics(fullfile(pathname, filename));
        else
            fprintf('No file selected.\n');
        end
        
    case 3
        % From suggestions
        if ~exist('suggestions', 'var')
            error('Run select_games_for_study first to generate suggestions');
        end
        
        fprintf('\nAvailable games:\n');
        for i = 1:length(suggestions)
            fprintf('%2d. %-40s (%s, score: %.2f)\n', i, ...
                suggestions(i).game, suggestions(i).category, suggestions(i).score);
        end
        
        game_idx = input(sprintf('\nSelect game number (1-%d): ', length(suggestions)));
        
        if game_idx >= 1 && game_idx <= length(suggestions)
            game_name = suggestions(game_idx).game;
            pairs = suggestions(game_idx).pairs;
            game_path = fullfile(base_folder, sprintf('%dpairs/fit', pairs), game_name);
            
            if exist(game_path, 'file')
                visualize_game_with_metrics(game_path);
            else
                error('File not found: %s', game_path);
            end
        else
            error('Invalid selection');
        end
        
    case 4
        % Batch save all suggestions
        if ~exist('suggestions', 'var')
            error('Run select_games_for_study first to generate suggestions');
        end
        
        output_dir = fullfile(base_folder, 'visualizations');
        if ~exist(output_dir, 'dir')
            mkdir(output_dir);
        end
        
        fprintf('\nBatch processing %d games...\n', length(suggestions));
        fprintf('Output directory: %s\n\n', output_dir);
        
        for i = 1:length(suggestions)
            game_name = suggestions(i).game;
            pairs = suggestions(i).pairs;
            game_path = fullfile(base_folder, sprintf('%dpairs/fit', pairs), game_name);
            
            fprintf('[%d/%d] Processing %s... ', i, length(suggestions), game_name);
            
            if exist(game_path, 'file')
                visualize_game_with_metrics(game_path, 'SaveFigure', true, 'OutputDir', output_dir);
                fprintf('Done\n');
                close(gcf);  % Close figure to save memory
            else
                fprintf('SKIP (not found)\n');
            end
        end
        
        fprintf('\nBatch processing complete!\n');
        fprintf('Figures saved to: %s\n', output_dir);
        
    otherwise
        error('Invalid option');
end

%% QUICK EXAMPLES (uncomment to use)

% Visualize easy games
% visualize_game_with_metrics(fullfile(base_folder, '3pairs/fit/set_44_3pairs.mat'));
% visualize_game_with_metrics(fullfile(base_folder, '3pairs/fit/set_31_3pairs.mat'));

% Visualize hard games
% visualize_game_with_metrics(fullfile(base_folder, '4pairs/fit/set_2_4pairs.mat'));
% visualize_game_with_metrics(fullfile(base_folder, '5pairs/fit/set_96_5pairs.mat'));


