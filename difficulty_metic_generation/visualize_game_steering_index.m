function visualize_game_steering_index(game_path, varargin)
    % VISUALIZE_GAME_STEERING_INDEX - Visualize steering index distribution for a game
    %
    % This script visualizes the steering index (constraint difficulty) for a given game.
    % The path is color-coded to show local difficulty (inverse clearance).
    %
    % Usage:
    %   visualize_game_steering_index(game_path)
    %   visualize_game_steering_index(game_path, 'save', true)
    %   visualize_game_steering_index(game_path, 'save', true, 'output_path', 'my_figure.png')
    %   visualize_game_steering_index(game_path, 'show_composite', false)
    %
    % Inputs:
    %   game_path       - Path to game .mat file (e.g., 'set_2_4pairs.mat')
    %   'save'          - (Optional) true to save figure, false otherwise (default: false)
    %   'output_path'   - (Optional) Path to save figure (default: auto-generated)
    %   'show_composite'- (Optional) true to show composite score in title (default: true)
    %
    % Examples:
    %   % Visualize game 2 with 4 pairs
    %   game_path = 'C:\...\new_games\4pairs\fit\set_2_4pairs.mat';
    %   visualize_game_steering_index(game_path);
    %
    %   % Visualize and save
    %   visualize_game_steering_index(game_path, 'save', true);
    %
    %   % Visualize and save to specific path
    %   visualize_game_steering_index(game_path, 'save', true, 'output_path', 'my_game.png');
    
    %% Parse input arguments
    p = inputParser;
    addRequired(p, 'game_path', @ischar);
    addParameter(p, 'save', false, @islogical);
    addParameter(p, 'output_path', '', @ischar);
    addParameter(p, 'show_composite', true, @islogical);
    parse(p, game_path, varargin{:});
    
    save_figure = p.Results.save;
    output_path = p.Results.output_path;
    show_composite = p.Results.show_composite;
    
    %% Load game data
    fprintf('\n========================================\n');
    fprintf('STEERING INDEX VISUALIZATION\n');
    fprintf('========================================\n');
    fprintf('Loading game: %s\n', game_path);
    
    if ~exist(game_path, 'file')
        error('Game file not found: %s', game_path);
    end
    
    data = load(game_path);
    
    % Extract game name from path
    [~, game_name, ~] = fileparts(game_path);
    
    %% Get path (prefer equalized curve, generate if needed)
    if isfield(data, 'curve_equalized') && ~isempty(data.curve_equalized)
        path = data.curve_equalized;
        path_type = 'Equalized Curve';
        fprintf('Using: Equalized Curve (from file)\n');
    elseif isfield(data, 'curve') && ~isempty(data.curve)
        % Generate equalized curve from Bezier curve
        fprintf('Generating equalized Bezier curve...\n');
        
        % Get step size from data file, or use default
        if isfield(data, 'step_size') && ~isempty(data.step_size)
            step_size = data.step_size;
        else
            step_size = 0.25;  % Default 0.25 cm
        end
        
        % Try to generate equalized curve
        if isfield(data, 'curve_segment_points') && ~isempty(data.curve_segment_points)
            [path, ~] = generate_equalized_bezier_curve(data.curve_segment_points, step_size);
            path_type = 'Equalized Curve';
            fprintf('Using: Generated Equalized Curve (%.2f cm step)\n', step_size);
        else
            % If no control points available, use original curve
            path = data.curve;
            path_type = 'Bezier Curve';
            fprintf('Warning: Could not generate equalized curve, using original Bezier curve\n');
        end
    elseif isfield(data, 'path') && ~isempty(data.path)
        path = data.path;
        path_type = 'A* Path';
        fprintf('Using: A* Path\n');
    else
        error('No path found in game file (expected curve_equalized, curve, or path)');
    end
    
    %% Calculate rehabilitation metrics
    fprintf('Calculating steering index metrics...\n');
    
    % Use the minimal version to get steering index
    rehab_metrics = calculate_rehab_metrics_minimal(path, data.obstacle, data.obstacle_radious);
    
    fprintf('\n--- Rehabilitation Metrics ---\n');
    fprintf('Steering Index:       %.4f\n', rehab_metrics.SteeringIndex);
    fprintf('K (Total Rotation):   %.4f rad (%.2f deg)\n', rehab_metrics.K_TotalRotation, rad2deg(rehab_metrics.K_TotalRotation));
    fprintf('Curvature Term:       %.4f\n', rehab_metrics.CurvatureTerm);
    fprintf('Composite Score (ID): %.4f\n', rehab_metrics.CompositeScore);
    fprintf('Path Length:          %.2f cm\n', rehab_metrics.PathLength);
    fprintf('Avg Path Slope:       %.2f deg\n', rehab_metrics.AvgPathSlope);
    fprintf('\n');
    
    %% Calculate steering index contribution at each point
    % Steering Index = Sum(ds / Width) where Width = 2 * min_clearance
    fprintf('Calculating local difficulty (inverse clearance)...\n');
    
    obstacle_radii = data.obstacle_radious(:);
    dists = zeros(size(path, 1), 1);
    clearances = zeros(size(path, 1), 1);
    
    for k = 1:size(path, 1)
        % Calculate distance from path point to each obstacle center
        obstacle_dists = sqrt(sum((data.obstacle - path(k,:)).^2, 2));
        % Subtract obstacle radii to get clearance (gap distance)
        clearance_values = obstacle_dists - obstacle_radii;
        % Find minimum clearance (narrowest gap)
        min_clearance = min(clearance_values);
        clearances(k) = min_clearance;
        
        % Inverse clearance (higher = harder/narrower)
        % This represents the local contribution to steering index
        dists(k) = 1 ./ max(min_clearance, 0.1);
    end
    
    fprintf('Min clearance: %.3f cm\n', min(clearances));
    fprintf('Max clearance: %.3f cm\n', max(clearances));
    fprintf('Avg clearance: %.3f cm\n', mean(clearances));
    
    %% Create visualization
    fprintf('Creating visualization...\n');
    
    fig = figure('Name', sprintf('Steering Index: %s', game_name), ...
                 'Position', [100, 100, 800, 700]);
    
    hold on;
    
    % Draw obstacles as simple black circles
    for j = 1:size(data.obstacle, 1)
        viscircles(data.obstacle(j, :), data.obstacle_radious(j), ...
            'Color', 'k', 'LineWidth', 1.5);
    end
    
    % Plot path with color mapped to difficulty (inverse clearance)
    scatter(path(:,1), path(:,2), 40, dists, 'filled');
    colormap(gca, 'jet'); % Red = Hard (narrow), Blue = Easy (wide)
    c = colorbar;
    c.Label.String = 'Local Difficulty (Inverse Clearance)';
    c.Label.FontSize = 12;
    
    % Add start/end labels in black text
    text(data.X_s(1), data.X_s(2), 'Start', 'HorizontalAlignment', 'center', ...
        'FontSize', 11, 'FontWeight', 'bold', 'Color', 'k');
    text(data.X_e(1), data.X_e(2), 'End', 'HorizontalAlignment', 'center', ...
        'FontSize', 11, 'FontWeight', 'bold', 'Color', 'k');
    
    hold off;
    
    % Create title based on show_composite option
    if show_composite
        title(sprintf('%s - %s\nSteering Index: %.2f | Composite Score (ID): %.2f', ...
            game_name, path_type, rehab_metrics.SteeringIndex, rehab_metrics.CompositeScore), ...
            'Interpreter', 'none', 'FontSize', 12);
    else
        title(sprintf('%s - %s\nSteering Index: %.2f', ...
            game_name, path_type, rehab_metrics.SteeringIndex), ...
            'Interpreter', 'none', 'FontSize', 12);
    end
    xlabel('X (cm)', 'FontSize', 12);
    ylabel('Y (cm)', 'FontSize', 12);
    axis equal;
    grid on;
    
    % Add padding to axis limits (5% on each side)
    x_padding = data.x_range * 0.05;
    y_padding = data.y_range * 0.05;
    xlim([-x_padding, data.x_range + x_padding]);
    ylim([-y_padding, data.y_range + y_padding]);
    
    %% Save figure if requested
    if save_figure
        if isempty(output_path)
            % Auto-generate output path in ../logs/thesis_figures
            % Get the directory of this script (difficulty_metic_generation folder)
            script_path = fileparts(mfilename('fullpath'));
            % Go up one level to game_creation_and_fits, then into logs/thesis_figures
            output_dir = fullfile(script_path, '..', 'logs', 'thesis_figures');
            
            % Create directory if it doesn't exist
            if ~exist(output_dir, 'dir')
                mkdir(output_dir);
                fprintf('Created output directory: %s\n', output_dir);
            end
            
            output_path = fullfile(output_dir, sprintf('steering_index_%s.png', game_name));
        end
        
        fprintf('\nSaving figure to: %s\n', output_path);
        saveas(fig, output_path);
        fprintf('Figure saved successfully!\n');
    end
    
    fprintf('\n========================================\n');
    fprintf('Visualization complete!\n');
    fprintf('========================================\n\n');
end
