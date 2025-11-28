% Load the data from the .mat file
clc
clear


color1 = [0, 119, 187] / 255;    % Blue color (#0077BB)
color2 = [43, 208, 158] / 255;   % Teal color (#22B199)
color3 = [238, 119, 51] / 255;   % Orange color (#EE7733)
color4 = [195, 48, 15] / 255;    % Red color (#C3300F)
color5 = [0, 0, 0] / 255;   % black (#2BD09E)
color6 = [255, 0, 140] / 255;   % Magenta color (#FF008C)
color7 = [255, 120, 0] / 255;   % Orange color (#FF7800)
color8 = [57, 226, 213] / 255;  % Aqua color (#39E2D5)
color9 = [8, 61, 119] / 255;    % Navy blue color (#083D77)

for k = [131:222]
    found_whole_path = true;
    step_size = 0.25;
    m =4;

    % Load the data from the .mat file
    set_number = k;
    pairs_number =4;
    % base_folder = 'C:\Users\mahbo\OneDrive - University of Calgary\code\game_creation_and_fits';
    base_folder = '/home/mahboobe/Desktop/game_generation_and_path_planning/game/';
    base_folder = '/home/mahboobe/Desktop/game_generation_and_path_planning/selected_games/';
    base_folder = '/home/mahboobe/Desktop/game_generation_and_path_planning/new_games/';
    pairs_folder = fullfile(base_folder, sprintf('%dpairs', pairs_number));
    set_name = sprintf('set_%d_%dpairs.mat', set_number, pairs_number);
    fullFileName = fullfile(pairs_folder, set_name);
    data = load(fullFileName);



    % Load the data from the .mat file
    X_s = floor(data.X_s / step_size) * step_size;
    X_e = floor(data.X_e / step_size) * step_size;
    obstacles = data.obstacle;
    obstacle_radii = data.obstacle_radious;
    x_range = data.x_range;
    y_range = data.y_range;

    disp('Data loaded successfully.');

    X_m = find_middle_point_in_obstacles(obstacles);
    Start_points = floor([X_s; X_m] / step_size) * step_size;
    End_points = floor([X_m; X_e] / step_size) * step_size;
    dynamic_path = [];
    modified_path = [];
    tr_path = [];
    visited_nodes = [];
    
    avoid_radius = step_size * m; % Radius to avoid revisiting nodes
    % Find the path using A* algorithm
    disp('Starting  modified A* algorithm...');
    for i = 1:size(Start_points, 1)
        partial_path = a_star_algorithm_tr(Start_points(i, :), End_points(i, :), obstacles, obstacle_radii, x_range, y_range, step_size);
        tr_path = [tr_path; partial_path];
    end 
    % Find the path using A* algorithm
    disp('Starting  modified A* algorithm...');
    for i = 1:size(Start_points, 1)
        partial_path = a_star_algorithm(Start_points(i, :), End_points(i, :), obstacles, obstacle_radii, x_range, y_range, step_size);
        modified_path = [modified_path; partial_path];
    end

    disp('Starting  modified dynamic A* algorithm...');
    for i = 1:size(Start_points, 1)
        partial_path = a_star_algorithm_dynamic(Start_points(i, :), End_points(i, :), obstacles, obstacle_radii, x_range, y_range, step_size, visited_nodes, avoid_radius);
        if size(partial_path,1) == 0
            found_whole_path = false;
        end
        dynamic_path = [dynamic_path; partial_path];
        visited_nodes = [visited_nodes; partial_path]; % Update visited nodes
    end



astar_path = dynamic_path;

% % Load the Bezier path data
% bezier_data = load(optimiazion_results_file);


num_segments = size(data.obstacle, 1) /2 + 1;

diagonal_distance = sqrt((x_range)^2 + (y_range)^2);

% Define the A* path and control points


% astar_path = astar_data.path;

% X_s = astar_data.X_s;
% X_e = astar_data.X_e;
% obstacles = astar_data.obstacle;
% obstacle_radii = astar_data.obstacle_radious;

% Define middle point

% Start_points = floor([X_s; X_m] / step_size) * step_size;
% End_points = floor([X_m; X_e] / step_size) * step_size;

% Initial curve length for segments
curve_length = sqrt(sum((End_points - Start_points).^2, 2));

% Optimization parameters

max_d = diagonal_distance / m;
max_d3 = diagonal_distance /2;
min_d = diagonal_distance / 100;
d_ub_in = ones(num_segments+1, 1) * max_d;
d3_ub_in = ones(num_segments+1, 1) * max_d3;
d_lb_in = ones(num_segments+1, 1) * min_d;
phi_ub_in = pi * ones(num_segments+1, 1);
phi_lb_in = -pi * ones(num_segments+1, 1);

lb_in = [d_lb_in; d_lb_in; d_lb_in;phi_lb_in; phi_lb_in;];
ub_in = [d_ub_in; d_ub_in;d3_ub_in; phi_ub_in;phi_ub_in];
% lb_in = [d_lb_in; d_lb_in; phi_lb_in; phi_lb_in];
% ub_in = [d_ub_in; d_ub_in; phi_ub_in; phi_ub_in];
temp_lb_in = lb_in;
temp_ub_in = ub_in;

n_d = 2;
n_phi = 1;
limit_factor = 1;

% Initial optimization variables
initial_d_in = ((d_lb_in + d_ub_in) / 2).* ones(num_segments+1, n_d +1);
initial_phi_in = ((phi_lb_in + phi_ub_in) / 2).*ones(num_segments+1, n_phi +1 );
initial_optimization_variables_in = [initial_d_in, initial_phi_in];
vector_variables_in = reshape(initial_optimization_variables_in, [], 1);
num_samples_list = [25,25,25,25];
% Define the objective function for optimization

points = floor(X_m /step_size)*step_size;
start_index = zeros(size(points, 1) +1, 1);
end_index = zeros(size(points, 1) +1 , 1);

start_index(1) = 1;
end_index(size(points, 1) +1) = size(astar_path,1);
for i = 1:size(points, 1)
    % Find the index of the exact match
    idx = find(astar_path(:,1) == points(i,1) & astar_path(:,2) == points(i,2));
    
    % Store the index
    start_index(i+1) = idx(1);
    end_index(i) = idx(1);
end
different = end_index - start_index;
different(1) = different(1) + 1;
% Calculate num_samples_list dynamically based on path segments, or use saved value
if isfield(data, 'num_samples_list')
    num_samples_list = data.num_samples_list; % Use saved value if available
else
    % Calculate dynamically based on path segment lengths
    num_samples_list = round(different*(size(astar_path,1))/sum(different));
end
% num_samples is used as a default/fallback in objective function (use average from list)
num_samples = round(mean(num_samples_list));
% curve_length = [0,0,0,0];
% for i = 1: 4
% 
%     curve_length(i) = sum(sqrt(sum(diff(astar_path(start_index(i):end_index(i),:)).^2, 2)));
% end
% 
% 
% num_samples_list = round(curve_length*100/sum(curve_length));
% sum(sqrt(sum(diff(astar_path).^2, 2)))

objective_in = @(x) optimize_bezier_to_astar(x, num_segments, Start_points(:, :), End_points(:, :), astar_path, num_samples, n_d, n_phi,num_samples_list,start_index,end_index );

% Perform the optimization
options = optimoptions('fmincon', 'Display', 'iter', 'Algorithm', 'sqp', 'MaxIterations', 1000);
% options = optimoptions('fmincon', 'SpecifyObjectiveGradient', true, 'Algorithm', 'interior-point', 'Display', 'iter');
% options = optimoptions('fmincon', 'SpecifyObjectiveGradient', true, 'Algorithm', 'interior-point', 'Display', 'iter');
[x_in, f_var] = fmincon(objective_in, vector_variables_in, [], [], [], [], lb_in, ub_in, [], options);
% [optimal_variables, optimal_cost] = fmincon(objective_function, initial_guess, [], [], [], [], [], [], [], options);
% Reshape the optimized variables
variables_matrix = reshape(x_in, [], n_d + n_phi+2);

% Combine the control points for all segments


% Calculate the Bézier curve segment points
curve_segment_points = calculate_curve_segment_points(variables_matrix, Start_points, End_points, num_segments, n_d, n_phi);

% Plot the results





























    % Plot the results
    figure_handle = figure;
    hold on;
    colormap(parula);
    % Plot start and end points


    % Plot obstacles
    for i = 1:size(obstacles, 1)
        viscircles(obstacles(i, :), obstacle_radii(i), 'EdgeColor', 'k', 'color', color5);
    end


    plot(X_s(1), X_s(2), 'ko', 'MarkerSize', 8, 'MarkerFaceColor', 'k', 'HandleVisibility', 'off');
    text(X_s(1), X_s(2), ' Start', 'FontSize', 8, 'FontWeight', 'bold', 'Color', 'k', ...
     'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left');
    plot(X_e(1), X_e(2), 'ko', 'MarkerSize', 8, 'MarkerFaceColor', 'k', 'HandleVisibility', 'off');
    text(X_e(1), X_e(2), ' End', 'FontSize', 8, 'FontWeight', 'bold', 'Color', 'k', ...
     'VerticalAlignment', 'top', 'HorizontalAlignment', 'right');

   % Plot the restricted areas
    % for i = 1:size(visited_nodes, 1)
    %     if i == 1
    %         continue;
    %     end
    %     current_node = visited_nodes(i, :);
    %     previous_node = visited_nodes(i-1, :);
    %     direction = (current_node - previous_node) / norm(current_node - previous_node);
    %     angle = atan2(direction(2), direction(1));
    %     draw_sector(current_node, avoid_radius, angle + pi/2, angle + 3*pi/2, 'y');
    % end

    % Plot the path




    % 
    if ~isempty(tr_path)
        plot(tr_path(:, 1), tr_path(:, 2),'color', color1,'LineStyle', '--', 'LineWidth', 2, 'DisplayName','Traditional A*');
    else
        disp('No path found.');
    end

            % Plot the path
    if ~isempty(modified_path)
        plot(modified_path(:, 1), modified_path(:, 2),'color', color2,'LineStyle', ':', 'LineWidth', 2.5, 'DisplayName','Modified A*');
    else
        disp('No path found.');
    end

    if ~isempty(dynamic_path)
        plot(dynamic_path(:, 1), dynamic_path(:, 2), 'color', color6,'LineStyle','-.', 'LineWidth', 1.5, 'DisplayName','Modified A* + Restriction');
    else
        disp('No path found.');
    end

    curve = [];
    for i = 1:num_segments
    segment_control_points = curve_segment_points(:, :, i);
    % Use num_samples_list for each segment (calculated dynamically based on path)
    segment_curve = bezier_curve(segment_control_points, num_samples_list(i));
    curve = [curve; segment_curve];
    
    end
    plot(curve(:, 1), curve(:, 2),'color', color3,'LineStyle','-' , 'LineWidth', 1.5, 'DisplayName','Bezier Curve');



        % Set plot limits
    % xlim([0 x_range]);
    % ylim([0 y_range]);
    % legend([start_plot, end_plot, path_plot], {'Start Point', 'End Point', 'Path'}, 'Location', 'Best');
    % mahboobe = sprintf("Path Planinig for 3 pairs obstacle senario");
    % title(mahboobe);
    xlabel('X');
    ylabel('Y');
    grid on;
    % Text coordinates and properties need to be adjusted based on figure dimensions and preference
    hold off;
    legend;
    path = dynamic_path;
    
    % Create the fit folder if it doesn't exist
    fit_folder = fullfile(base_folder, sprintf('%dpairs', pairs_number), 'fit');
    if ~exist(fit_folder, 'dir')
        mkdir(fit_folder);
    end
    unvalid_folder = fullfile(base_folder, sprintf('%dpairs', pairs_number), 'fit_unvalid');
    if ~exist(unvalid_folder, 'dir')
        mkdir(unvalid_folder);
    end
    
    % Save figure in the fit folder
    figure_filename = ['figure_set_' num2str(set_number) '_' num2str(pairs_number) 'pairs_Astr_avoid_stepsize_' num2str(step_size) '_m_' num2str(m) '_2.png'];
    
    if found_whole_path
        figure_fullFileName = fullfile(fit_folder, figure_filename);
        print(figure_fullFileName, '-dpng');
    else
        figure_fullFileName = fullfile(unvalid_folder, figure_filename);
        print(figure_fullFileName, '-dpng');
    end
    
    % Create new filename in the fit folder
    fit_set_name = sprintf('set_%d_%dpairs.mat', set_number, pairs_number);
    fit_fullFileName = fullfile(fit_folder, fit_set_name);
    
    % Save all original data from game set file plus new computed data
    % Original data from game set file
    obstacle = data.obstacle;
    obstacle_radious = data.obstacle_radious;
    x_range = data.x_range;
    y_range = data.y_range;
    % Extract number_of_pairs if it exists in the original file
    if isfield(data, 'number_of_pairs')
        number_of_pairs = data.number_of_pairs;
    else
        number_of_pairs = pairs_number; % Fallback to pairs_number if not in file
    end
    
    % Save all data to new file (original + new)
    % Original game set variables: X_e, X_s, obstacle, obstacle_radious, x_range, y_range, number_of_pairs
    % New computed variables: Start_points, End_points, path, step_size, m, avoid_radius, 
    %                         visited_nodes, curve, curve_segment_points, variables_matrix, num_samples_list
    if found_whole_path
        save(fit_fullFileName, 'X_e', 'X_s', 'obstacle', 'obstacle_radious', 'x_range', 'y_range', 'number_of_pairs', ...
             'Start_points', 'End_points', 'path', 'step_size', 'm', 'avoid_radius', ...
             'visited_nodes', 'curve', 'curve_segment_points', 'variables_matrix', 'num_samples_list');
    end
    disp('Pathfinding completed.');
    % Convert to a string suitable for a filename (e.g., '2024-03-11_15-30-00')


end

function path = a_star_algorithm_dynamic(X_s, X_e, obstacles, obstacle_radii, x_range, y_range, step_size, visited_nodes, avoid_radius)
    start = X_s;
    goal = X_e;
    open_list = [start, 0, heuristic_max_dist(start, goal, obstacles, obstacle_radii), heuristic_max_dist(start, goal, obstacles, obstacle_radii), -1];
    closed_list = [];
    directions_step = [-1, 0; 1, 0; 0, -1; 0, 1; -1, -1; -1, 1; 1, -1; 1, 1];
    directions = directions_step * step_size;

    while ~isempty(open_list)
        [~, idx] = min(open_list(:, 4));
        current_node = open_list(idx, :);
        open_list(idx, :) = [];
        closed_list = [closed_list; current_node];

        if all(current_node(1:2) == goal)
            disp('Goal reached. Reconstructing path...');
            path = reconstruct_path(closed_list, current_node);
            return;
        end

        for i = 1:size(directions, 1)
            neighbor = current_node(1:2) + directions(i, :);
            current_direction = directions(i, :) / norm(directions(i, :));
            if any(ismember(closed_list(:, 1:2), neighbor, 'rows')) || check_collision(neighbor, obstacles, obstacle_radii) || within_avoid_radius(neighbor, visited_nodes, avoid_radius, current_direction)
                continue;
            end
            tentative_g_score = current_node(3) + norm(directions(i, :));
            in_open_list = ismember(open_list(:, 1:2), neighbor, 'rows');
            if in_open_list
                open_list_idx = find(ismember(open_list(:, 1:2), neighbor, 'rows'));
                if tentative_g_score >= open_list(open_list_idx, 3)
                    continue;
                end
            end
            h_score = heuristic_max_dist(neighbor, goal, obstacles, obstacle_radii);
            f_score = tentative_g_score + h_score;
            if in_open_list
                open_list(open_list_idx, :) = [neighbor, tentative_g_score, h_score, f_score, size(closed_list, 1)];
            else
                open_list = [open_list; neighbor, tentative_g_score, h_score, f_score, size(closed_list, 1)];
            end
        end
        if mod(size(closed_list, 1), 10) == 0
            disp(['Processed ', num2str(size(closed_list, 1)), ' nodes...']);
            if size(closed_list, 1) > 5000
                break;
            end
        end
    end
    disp('No path found.');
    path = [];
end

function h = heuristic_max_dist(point, goal, obstacles, obstacle_radii)
    % Euclidean distance to the goal
    h_goal = norm(point - goal);
    
    % Calculate minimum distance to any obstacle
    min_dist_to_obstacle = inf;
    for i = 1:size(obstacles, 1)
        dist_to_obstacle = norm(point - obstacles(i, :)) - obstacle_radii(i);
        if dist_to_obstacle < min_dist_to_obstacle
            min_dist_to_obstacle = dist_to_obstacle;
        end
    end

    % Apply a penalty based on proximity to obstacles
    penalty_weight = 10; % Adjust this weight to balance the influence
    if min_dist_to_obstacle > 0
        penalty = penalty_weight / (1+min_dist_to_obstacle);
    else
        penalty = inf; % High penalty if inside an obstacle
    end
     % penalty = 0;
    % Combine the heuristic for goal distance and obstacle penalty
    h = h_goal + penalty;
end

function path = reconstruct_path(closed_list, current_node)
    path = current_node(1:2);
    parent_index = current_node(6);
    while parent_index ~= -1
        current_node = closed_list(parent_index, :);
        path = [current_node(1:2); path];
        parent_index = current_node(6);
    end
end


function [neighbors, directions_step] = generate_neighbors_dynamic(current, x_range, y_range, step_size, visited_nodes, avoid_radius)
    directions_step = [-1, 0; 1, 0; 0, -1; 0, 1; -1, -1; -1, 1; 1, -1; 1, 1];
    directions = directions_step * step_size;
    neighbors = [];
    for i = 1:size(directions, 1)
        neighbor = current + directions(i, :);
        if neighbor(1) >= 0 && neighbor(1) <= x_range && neighbor(2) >= 0 && neighbor(2) <= y_range
            % Check if neighbor is within avoid radius of visited nodes
            within_avoid_radius = false;
            for j = 1:size(visited_nodes, 1)
                if norm(neighbor - visited_nodes(j, :)) < avoid_radius
                    within_avoid_radius = true;
                    break;
                end
            end
            if ~within_avoid_radius
                neighbors = [neighbors; neighbor];
            end
        end
    end
end

function [neighbors, directions_step] = generate_neighbors(current, x_range, y_range, step_size)
    directions_step = [-1, 0; 1, 0; 0, -1; 0, 1; -1, -1; -1, 1; 1, -1; 1, 1];
    directions = directions_step * step_size;
    neighbors = [];
    for i = 1:size(directions, 1)
        neighbor = current + directions(i, :);
        if neighbor(1) >= 0 && neighbor(1) <= x_range && neighbor(2) >= 0 && neighbor(2) <= y_range
            neighbors = [neighbors; neighbor];
        end
    end
end

function collision = check_collision(point, obstacles, obstacle_radii)
    collision = false;
    for i = 1:size(obstacles, 1)
        if norm(point - obstacles(i, :)) < obstacle_radii(i)
            collision = true;
            return;
        end
    end
end


function within_radius = within_avoid_radius(point, visited_nodes, avoid_radius, current_direction)
    within_radius = false;
    for i = 1:size(visited_nodes, 1)
        distance = norm(point - visited_nodes(i, :));
        if distance < avoid_radius
            direction_to_point = (point - visited_nodes(i, :)) / distance;
            % Back sector: Check if point is behind within π ± π/8
            if dot(direction_to_point, current_direction) < 0 % Only consider points behind
                    within_radius = true;
                    return;
            end
        end
    end
end

function draw_sector(center, radius, start_angle, end_angle, color)
    theta = linspace(start_angle, end_angle, 100);
    x = center(1) + radius * cos(theta);
    y = center(2) + radius * sin(theta);
    fill([center(1) x], [center(2) y], color, 'FaceAlpha', 0.3, 'EdgeColor', 'none');
end

function path = a_star_algorithm(X_s, X_e, obstacles, obstacle_radii, x_range, y_range, step_size)
    start = X_s;
    goal = X_e;
    open_list = [start, 0, heuristic_max_dist(start, goal, obstacles, obstacle_radii), heuristic_max_dist(start, goal, obstacles, obstacle_radii), -1];
    closed_list = [];
    directions_step = [-1, 0; 1, 0; 0, -1; 0, 1; -1, -1; -1, 1; 1, -1; 1, 1];
    directions = directions_step * step_size;

    while ~isempty(open_list)
        [~, idx] = min(open_list(:, 4));
        current_node = open_list(idx, :);
        open_list(idx, :) = [];
        closed_list = [closed_list; current_node];

        if all(current_node(1:2) == goal)
            disp('Goal reached. Reconstructing path...');
            path = reconstruct_path(closed_list, current_node);
            return;
        end

        for i = 1:size(directions, 1)
            neighbor = current_node(1:2) + directions(i, :);
            if any(ismember(closed_list(:, 1:2), neighbor, 'rows')) || check_collision(neighbor, obstacles, obstacle_radii)
                continue;
            end
            tentative_g_score = current_node(3) + norm(directions(i, :));
            in_open_list = ismember(open_list(:, 1:2), neighbor, 'rows');
            if in_open_list
                open_list_idx = find(ismember(open_list(:, 1:2), neighbor, 'rows'));
                if tentative_g_score >= open_list(open_list_idx, 3)
                    continue;
                end
            end
            h_score = heuristic_max_dist(neighbor, goal, obstacles, obstacle_radii);
            f_score = tentative_g_score + h_score;
            if in_open_list
                open_list(open_list_idx, :) = [neighbor, tentative_g_score, h_score, f_score, size(closed_list, 1)];
            else
                open_list = [open_list; neighbor, tentative_g_score, h_score, f_score, size(closed_list, 1)];
            end
        end
        if mod(size(closed_list, 1), 10) == 0
            disp(['Processed ', num2str(size(closed_list, 1)), ' nodes...']);
        end
    end
    disp('No path found.');
    path = [];
end


function path = a_star_algorithm_tr(X_s, X_e, obstacles, obstacle_radii, x_range, y_range, step_size)
    start = X_s;
    goal = X_e;
    open_list = [start, 0, heuristic_max_dist(start, goal, obstacles, obstacle_radii), heuristic_max_dist(start, goal, obstacles, obstacle_radii), -1];
    closed_list = [];
    directions_step = [-1, 0; 1, 0; 0, -1; 0, 1; -1, -1; -1, 1; 1, -1; 1, 1];
    directions = directions_step * step_size;

    while ~isempty(open_list)
        [~, idx] = min(open_list(:, 4));
        current_node = open_list(idx, :);
        open_list(idx, :) = [];
        closed_list = [closed_list; current_node];

        if all(current_node(1:2) == goal)
            disp('Goal reached. Reconstructing path...');
            path = reconstruct_path(closed_list, current_node);
            return;
        end

        for i = 1:size(directions, 1)
            neighbor = current_node(1:2) + directions(i, :);
            if any(ismember(closed_list(:, 1:2), neighbor, 'rows')) || check_collision(neighbor, obstacles, obstacle_radii)
                continue;
            end
            tentative_g_score = current_node(3) + norm(directions(i, :));
            in_open_list = ismember(open_list(:, 1:2), neighbor, 'rows');
            if in_open_list
                open_list_idx = find(ismember(open_list(:, 1:2), neighbor, 'rows'));
                if tentative_g_score >= open_list(open_list_idx, 3)
                    continue;
                end
            end
            h_score = heuristic_max_dist_tr(neighbor, goal, obstacles, obstacle_radii);
            f_score = tentative_g_score + h_score;
            if in_open_list
                open_list(open_list_idx, :) = [neighbor, tentative_g_score, h_score, f_score, size(closed_list, 1)];
            else
                open_list = [open_list; neighbor, tentative_g_score, h_score, f_score, size(closed_list, 1)];
            end
        end
        if mod(size(closed_list, 1), 10) == 0
            disp(['Processed ', num2str(size(closed_list, 1)), ' nodes...']);
        end
    end
    disp('No path found.');
    path = [];
end


function h = heuristic_max_dist_tr(point, goal, obstacles, obstacle_radii)
    % Euclidean distance to the goal
    h = norm(point - goal);
 
end