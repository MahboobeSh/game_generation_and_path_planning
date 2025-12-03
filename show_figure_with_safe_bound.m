function show_figure_with_safe_bound(bezier_curve,obstacles_centers,obstacles_radii,safe_bound, title_text)
%UNTITLED4 Summary of this function goes here
    figure_handle = figure;
    hold on;
    % Plot the Bézier curve
    % Plot start and end points
    % Plot obstacles
    for i = 1:size(obstacles_centers, 1)
        viscircles(obstacles_centers(i, :), obstacles_radii(i), 'EdgeColor', 'b');
    end
    for i=1:size(bezier_curve,1)
        theta = linspace(0, 2*pi, 100);  % Parameter to create the circle
        x_center = bezier_curve(i, 1);  % x-coordinate of the center
        y_center = bezier_curve(i, 2);  % y-coordinate of the center
        radius = safe_bound(i);  % Radius of the circle

        % Generate circle points
        x_circle = x_center + radius * cos(theta);
        y_circle = y_center + radius * sin(theta);

        % Plot the filled circle with transparency
        fill(x_circle, y_circle, 'c', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
        % viscircles(bezier_curve(i, :), min_distance_vector(i), 'g', 'FaceAlpha', 0.3, 'EdgeColor', 'none');

    end
    plot(bezier_curve(:, 1), bezier_curve(:, 2), 'r.', 'LineWidth', 2);
    title(title_text);
    hold off;
    print(figure_handle, '-dpng', '-r300');
end