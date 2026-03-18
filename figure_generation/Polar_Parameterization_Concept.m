%% Configuration
save_figures = true;  % true = save to files, false = only display

script_dir = fileparts(mfilename('fullpath'));
output_folder = fullfile(script_dir, '..', 'logs', 'curve');
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

%% Figure 1: Polar Parameterization of Control Points
figure('Position', [100, 100, 800, 600]);
hold on; axis equal; grid on;

% Reference point (start of segment)
P_start = [2, 3];
plot(P_start(1), P_start(2), 'ko', 'MarkerSize', 12, 'MarkerFaceColor', 'k');
text(P_start(1)-0.3, P_start(2)+0.3, '$\mathbf{P}_0$ (Start)', 'Interpreter', 'latex', 'FontSize', 14);

% Define control points using (d, φ) parameterization
d1 = 1.5;  % distance for P1
phi1 = 30; % angle in degrees

d2 = 2.0;  % distance for P2
phi2 = 45;

% Calculate control points
P1 = P_start + d1*[cosd(phi1), sind(phi1)];
P2 = P_start + d2*[cosd(phi2), sind(phi2)];

% Plot control points
plot(P1(1), P1(2), 'ro', 'MarkerSize', 12, 'MarkerFaceColor', 'r');
plot(P2(1), P2(2), 'bo', 'MarkerSize', 12, 'MarkerFaceColor', 'b');

% Draw distance vectors
quiver(P_start(1), P_start(2), d1*cosd(phi1), d1*sind(phi1), 0, 'r', 'LineWidth', 2, 'MaxHeadSize', 0.5);
quiver(P_start(1), P_start(2), d2*cosd(phi2), d2*sind(phi2), 0, 'b', 'LineWidth', 2, 'MaxHeadSize', 0.5);

% Draw angle arcs
theta1 = linspace(0, phi1*pi/180, 50);
r_arc = 0.5;
arc1_x = P_start(1) + r_arc*cos(theta1);
arc1_y = P_start(2) + r_arc*sin(theta1);
plot(arc1_x, arc1_y, 'r--', 'LineWidth', 1.5);

theta2 = linspace(0, phi2*pi/180, 50);
arc2_x = P_start(1) + r_arc*1.3*cos(theta2);
arc2_y = P_start(2) + r_arc*1.3*sin(theta2);
plot(arc2_x, arc2_y, 'b--', 'LineWidth', 1.5);

% Add labels
text(P1(1)+0.2, P1(2), '$\mathbf{P}_1$', 'Interpreter', 'latex', 'FontSize', 14, 'Color', 'r');
text(P2(1)+0.2, P2(2), '$\mathbf{P}_2$', 'Interpreter', 'latex', 'FontSize', 14, 'Color', 'b');

text(P_start(1) + 0.8, P_start(2) + 0.2, '$\phi_1$', 'Interpreter', 'latex', 'FontSize', 12, 'Color', 'r');
text(P_start(1) + 0.9, P_start(2) + 0.6, '$\phi_2$', 'Interpreter', 'latex', 'FontSize', 12, 'Color', 'b');

text(P_start(1) + d1/2*cosd(phi1) - 0.2, P_start(2) + d1/2*sind(phi1) + 0.3, '$d_1$', 'Interpreter', 'latex', 'FontSize', 12, 'Color', 'r');
text(P_start(1) + d2/2*cosd(phi2) - 0.2, P_start(2) + d2/2*sind(phi2) + 0.3, '$d_2$', 'Interpreter', 'latex', 'FontSize', 12, 'Color', 'b');

xlabel('X', 'FontSize', 12);
ylabel('Y', 'FontSize', 12);
title('Polar Parameterization: Control Points from Reference Point', 'FontSize', 14);
xlim([1, 5]); ylim([2, 6]);
set(gca, 'FontSize', 11);

% Save
if save_figures
    print(gcf, fullfile(output_folder, 'polar_parameterization.png'), '-dpng', '-r300');
    print(gcf, fullfile(output_folder, 'polar_parameterization.pdf'), '-dpdf', '-r300');
    fprintf('Saved: polar_parameterization (.png, .pdf)\n');
end


%% Figure 2: Quartic Bézier with Polar Parameterization Visualization
figure('Position', [100, 100, 900, 600]);
hold on; axis equal; grid on;

% Define segment endpoints
P0 = [1, 2.2];
P4 = [8, 3];

% Define intermediate control points using (d, φ) from start
d2 = 0.8; phi1 = 40;
d3 = 2.5; phi2 = -60;
P1 = P0 + d2*[cosd(phi1), sind(phi1)];
P2 = P0 + d3*[cosd(phi2), sind(phi2)];

% Define control point from end (using NEXT segment's parameters)
d1_next = 2.0; phi1_next = 160; % From end, pointing back
P3 = P4 + d1_next*[cosd(phi1_next), sind(phi1_next)];

% Generate Bézier curve
t = linspace(0, 1, 100);
bezier_curve = zeros(length(t), 2);
for i = 1:length(t)
    B = (1-t(i))^4*P0 + 4*(1-t(i))^3*t(i)*P1 + 6*(1-t(i))^2*t(i)^2*P2 + ...
        4*(1-t(i))*t(i)^3*P3 + t(i)^4*P4;
    bezier_curve(i,:) = B;
end
plot(bezier_curve(:,1), bezier_curve(:,2), 'k-', 'LineWidth', 2.5);

% Plot control points
plot(P0(1), P0(2), 'ko', 'MarkerSize', 14, 'MarkerFaceColor', 'g', 'LineWidth', 2);
plot(P1(1), P1(2), 'ko', 'MarkerSize', 12, 'MarkerFaceColor', 'r');
plot(P2(1), P2(2), 'ko', 'MarkerSize', 12, 'MarkerFaceColor', 'r');
plot(P3(1), P3(2), 'ko', 'MarkerSize', 12, 'MarkerFaceColor', 'b');
plot(P4(1), P4(2), 'ko', 'MarkerSize', 14, 'MarkerFaceColor', 'g', 'LineWidth', 2);

% ===== POLAR PARAMETERIZATION VISUALIZATION =====
% Draw distance vectors FROM P0 (red control points)
quiver(P0(1), P0(2), d2*cosd(phi1), d2*sind(phi1), 0, 'r', 'LineWidth', 2, 'MaxHeadSize', 0.5);
quiver(P0(1), P0(2), d3*cosd(phi2), d3*sind(phi2), 0, 'r', 'LineWidth', 2, 'MaxHeadSize', 0.5);

% Draw distance vector FROM P4 (blue control point)
quiver(P4(1), P4(2), d1_next*cosd(phi1_next), d1_next*sind(phi1_next), 0, 'b', 'LineWidth', 2, 'MaxHeadSize', 0.5);

% Draw angle arcs at P0
r_arc = 0.6;
theta1 = linspace(0, phi1*pi/180, 30);
arc1_x = P0(1) + r_arc*cos(theta1);
arc1_y = P0(2) + r_arc*sin(theta1);
plot(arc1_x, arc1_y, 'r--', 'LineWidth', 1.5);

theta2 = linspace(0, phi2*pi/180, 30);
r_arc2 = 0.8;
arc2_x = P0(1) + r_arc2*cos(theta2);
arc2_y = P0(2) + r_arc2*sin(theta2);
plot(arc2_x, arc2_y, 'r--', 'LineWidth', 1.5);

% Draw angle arc at P4
theta3 = linspace(0, phi1_next*pi/180, 30);
r_arc3 = 0.6;
arc3_x = P4(1) + r_arc3*cos(theta3);
arc3_y = P4(2) + r_arc3*sin(theta3);
plot(arc3_x, arc3_y, 'b--', 'LineWidth', 1.5);

% Add distance labels on arrows
text(P0(1) + d2/2*cosd(phi1) - 0.2, P0(2) + d2/2*sind(phi1) + 0.3, '$d_2$', 'Interpreter', 'latex', 'FontSize', 11, 'Color', 'r', 'FontWeight', 'bold');
text(P0(1) + d3/2*cosd(phi2), P0(2) + d3/2*sind(phi2) - 0.3, '$d_3$', 'Interpreter', 'latex', 'FontSize', 11, 'Color', 'r', 'FontWeight', 'bold');
text(P4(1) + d1_next/2*cosd(phi1_next), P4(2) + d1_next/2*sind(phi1_next) + 0.3, '$d_1^{next}$', 'Interpreter', 'latex', 'FontSize', 11, 'Color', 'b', 'FontWeight', 'bold');

% Add angle labels
text(P0(1) + 1.0, P0(2) + 0.25, '$\phi_1$', 'Interpreter', 'latex', 'FontSize', 11, 'Color', 'r');
text(P0(1) + 1.0, P0(2) + 0.6, '$\phi_2$', 'Interpreter', 'latex', 'FontSize', 11, 'Color', 'r');
text(P4(1) - 1.0, P4(2) + 0.4, '$\phi_1^{next}$', 'Interpreter', 'latex', 'FontSize', 11, 'Color', 'b');

% Add control point labels
text(P0(1)-0.3, P0(2)-0.5, '$\mathbf{P}_0$ (Start)', 'Interpreter', 'latex', 'FontSize', 13, 'FontWeight', 'bold');
text(P1(1)+0.2, P1(2)+0.3, '$\mathbf{P}_1$ $(d_2, \phi_1)$', 'Interpreter', 'latex', 'FontSize', 12, 'Color', 'r');
text(P2(1)+0.2, P2(2)-0.5, '$\mathbf{P}_2$ $(d_3, \phi_2)$', 'Interpreter', 'latex', 'FontSize', 12, 'Color', 'r');
text(P3(1)-0.8, P3(2)+0.5, '$\mathbf{P}_3$ $(d_1^{next}, \phi_1^{next})$', 'Interpreter', 'latex', 'FontSize', 12, 'Color', 'b');
text(P4(1)+0.2, P4(2)-0.5, '$\mathbf{P}_4$ (End)', 'Interpreter', 'latex', 'FontSize', 13, 'FontWeight', 'bold');

xlabel('X', 'FontSize', 12);
ylabel('Y', 'FontSize', 12);
title('Quartic Bézier Segment: 5 Control Points with Polar Parameterization', 'FontSize', 14);
xlim([0.5, 8.5]); ylim([1.5, 4.5]);
set(gca, 'FontSize', 11);

if save_figures
    print(gcf, fullfile(output_folder, 'quartic_bezier_polar.png'), '-dpng', '-r300');
    print(gcf, fullfile(output_folder, 'quartic_bezier_polar.pdf'), '-dpdf', '-r300');
    fprintf('Saved: quartic_bezier_polar (.png, .pdf)\n');
end


%% Figure 3: G¹ Continuity with Polar Parameterization
figure('Position', [100, 100, 1000, 600]);
hold on; axis equal; grid on;

% Segment 1 (ending)
P0_seg1 = [1, 3];
P3_seg1 = [4, 4];
P4_seg1 = [6, 3.5]; % = P0_seg2

% Segment 2 (starting)
P0_seg2 = P4_seg1; % Shared point
P4_seg2 = [10, 4];

% Define control points using shared angle for G¹
phi_shared = 20; % SAME angle for G¹ continuity

% Segment 1: P3 uses parameters from row i+1
d1_row2 = 1.5;
P3_seg1 = P4_seg1 + d1_row2*[cosd(phi_shared+180), sind(phi_shared+180)];

% Segment 2: P1 uses SAME angle but different distance
d2_row2 = 2.2; % Different distance!
P1_seg2 = P0_seg2 + d2_row2*[cosd(phi_shared), sind(phi_shared)];

% Additional control points for complete segments
P1_seg1 = [2, 4.2];
P2_seg1 = [3.5, 4.5];
P2_seg2 = [8, 5];
P3_seg2 = [9, 4.8];

% ===== GENERATE BÉZIER CURVES =====
% Segment 1
t1 = linspace(0, 1, 100);
curve1 = zeros(length(t1), 2);
for i = 1:length(t1)
    B = (1-t1(i))^4*P0_seg1 + 4*(1-t1(i))^3*t1(i)*P1_seg1 + ...
        6*(1-t1(i))^2*t1(i)^2*P2_seg1 + 4*(1-t1(i))*t1(i)^3*P3_seg1 + t1(i)^4*P4_seg1;
    curve1(i,:) = B;
end
plot(curve1(:,1), curve1(:,2), 'b-', 'LineWidth', 3);

% Segment 2
t2 = linspace(0, 1, 100);
curve2 = zeros(length(t2), 2);
for i = 1:length(t2)
    B = (1-t2(i))^4*P0_seg2 + 4*(1-t2(i))^3*t2(i)*P1_seg2 + ...
        6*(1-t2(i))^2*t2(i)^2*P2_seg2 + 4*(1-t2(i))*t2(i)^3*P3_seg2 + t2(i)^4*P4_seg2;
    curve2(i,:) = B;
end
plot(curve2(:,1), curve2(:,2), 'r-', 'LineWidth', 3);

% ===== PLOT CONTROL POINTS =====
% Segment 1 control points
plot(P0_seg1(1), P0_seg1(2), 'bo', 'MarkerSize', 10, 'MarkerFaceColor', 'cyan');
plot(P1_seg1(1), P1_seg1(2), 'bo', 'MarkerSize', 8, 'MarkerFaceColor', 'b');
plot(P2_seg1(1), P2_seg1(2), 'bo', 'MarkerSize', 8, 'MarkerFaceColor', 'b');
plot(P3_seg1(1), P3_seg1(2), 'bo', 'MarkerSize', 12, 'MarkerFaceColor', 'cyan', 'LineWidth', 2);
plot(P4_seg1(1), P4_seg1(2), 'ko', 'MarkerSize', 15, 'MarkerFaceColor', 'yellow', 'LineWidth', 3);

% Segment 2 control points
plot(P0_seg2(1), P0_seg2(2), 'ko', 'MarkerSize', 15, 'MarkerFaceColor', 'yellow', 'LineWidth', 3);
plot(P1_seg2(1), P1_seg2(2), 'ro', 'MarkerSize', 12, 'MarkerFaceColor', 'magenta', 'LineWidth', 2);
plot(P2_seg2(1), P2_seg2(2), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
plot(P3_seg2(1), P3_seg2(2), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
plot(P4_seg2(1), P4_seg2(2), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'magenta');

% ===== POLAR PARAMETERIZATION VISUALIZATION =====
% Arrow from P4_seg1 to P3_seg1 (blue - segment 1)
quiver(P4_seg1(1), P4_seg1(2), P3_seg1(1)-P4_seg1(1), P3_seg1(2)-P4_seg1(2), 0, ...
    'b', 'LineWidth', 3, 'MaxHeadSize', 0.8);

% Arrow from P0_seg2 to P1_seg2 (red - segment 2)
quiver(P0_seg2(1), P0_seg2(2), P1_seg2(1)-P0_seg2(1), P1_seg2(2)-P0_seg2(2), 0, ...
    'r', 'LineWidth', 3, 'MaxHeadSize', 0.8);

% Distance labels on arrows
text(P4_seg1(1) + (P3_seg1(1)-P4_seg1(1))/2 - 0.3, P4_seg1(2) + (P3_seg1(2)-P4_seg1(2))/2 + 0.3, ...
    '$d_1^{(i+1)}$', 'Interpreter', 'latex', 'FontSize', 12, 'Color', 'b', 'FontWeight', 'bold', 'BackgroundColor', 'white');

text(P0_seg2(1) + (P1_seg2(1)-P0_seg2(1))/2, P0_seg2(2) + (P1_seg2(2)-P0_seg2(2))/2 + 0.3, ...
    '$d_2^{(i+1)}$', 'Interpreter', 'latex', 'FontSize', 12, 'Color', 'r', 'FontWeight', 'bold', 'BackgroundColor', 'white');

% Draw angle arc showing SHARED angle (spanning both directions)
r_arc = 1.2;
theta_arc = linspace(phi_shared*pi/180, (phi_shared+180)*pi/180, 50);
arc_x = P0_seg2(1) + r_arc*cos(theta_arc);
arc_y = P0_seg2(2) + r_arc*sin(theta_arc);
plot(arc_x, arc_y, 'g--', 'LineWidth', 2.5);

% Individual angle arcs
r_arc_small = 0.7;
% Arc for segment 2 (forward direction)
theta_fwd = linspace(0, phi_shared*pi/180, 30);
arc_fwd_x = P0_seg2(1) + r_arc_small*cos(theta_fwd);
arc_fwd_y = P0_seg2(2) + r_arc_small*sin(theta_fwd);
plot(arc_fwd_x, arc_fwd_y, 'r--', 'LineWidth', 1.5);

% Arc for segment 1 (backward direction)
theta_back = linspace(phi_shared*pi/180, (phi_shared+180)*pi/180, 30);
arc_back_x = P0_seg2(1) + r_arc_small*cos(theta_back);
arc_back_y = P0_seg2(2) + r_arc_small*sin(theta_back);
plot(arc_back_x, arc_back_y, 'b--', 'LineWidth', 1.5);

% Angle labels
text(P0_seg2(1) + 1.0, P0_seg2(2) + 0.3, '$\phi_1^{(i+1)}$', 'Interpreter', 'latex', ...
    'FontSize', 13, 'Color', 'g', 'FontWeight', 'bold', 'BackgroundColor', 'white');

% ===== CONTROL POINT LABELS =====
text(P3_seg1(1)-0.6, P3_seg1(2)+0.4, '$\mathbf{P}_3^{(i)}$', 'Interpreter', 'latex', 'FontSize', 12, 'Color', 'b', 'FontWeight', 'bold');
text(P0_seg2(1)-0.3, P0_seg2(2)-0.6, '$\mathbf{P}_0^{(i+1)} = \mathbf{P}_4^{(i)}$', 'Interpreter', 'latex', 'FontSize', 12, 'FontWeight', 'bold');
text(P1_seg2(1)+0.3, P1_seg2(2)+0.3, '$\mathbf{P}_1^{(i+1)}$', 'Interpreter', 'latex', 'FontSize', 12, 'Color', 'r', 'FontWeight', 'bold');

% ===== KEY ANNOTATIONS =====
annotation('textbox', [0.15, 0.85, 0.3, 0.1], 'String', ...
    'Same angle $\phi_1^{(i+1)}$ (Collinear)', ...
    'Interpreter', 'latex', 'FontSize', 14, 'Color', 'g', ...
    'FontWeight', 'bold', 'EdgeColor', 'g', 'LineWidth', 2, 'BackgroundColor', 'white');

annotation('textbox', [0.15, 0.75, 0.35, 0.1], 'String', ...
    'Different distances: $d_1^{(i+1)} \neq d_2^{(i+1)}$', ...
    'Interpreter', 'latex', 'FontSize', 14, 'Color', 'm', ...
    'FontWeight', 'bold', 'EdgeColor', 'm', 'LineWidth', 2, 'BackgroundColor', 'white');

annotation('textbox', [0.15, 0.65, 0.2, 0.1], 'String', ...
    '$\Rightarrow$ G$^1$ Continuity', ...
    'Interpreter', 'latex', 'FontSize', 14, 'Color', 'k', ...
    'FontWeight', 'bold', 'EdgeColor', 'k', 'LineWidth', 2, 'BackgroundColor', 'yellow');

% Segment labels
text(2.5, 2.3, 'Segment $i$', 'Interpreter', 'latex', 'FontSize', 14, 'Color', 'b', 'FontWeight', 'bold');
text(8, 2.3, 'Segment $i+1$', 'Interpreter', 'latex', 'FontSize', 14, 'Color', 'r', 'FontWeight', 'bold');

xlabel('X', 'FontSize', 12);
ylabel('Y', 'FontSize', 12);
title('G¹ Continuity: Collinear Tangents (Same Angle, Different Distances)', 'FontSize', 14);
xlim([0, 11]); ylim([2, 6]);
set(gca, 'FontSize', 11);

if save_figures
    print(gcf, fullfile(output_folder, 'g1_continuity_polar.png'), '-dpng', '-r300');
    print(gcf, fullfile(output_folder, 'g1_continuity_polar.pdf'), '-dpdf', '-r300');
    fprintf('Saved: g1_continuity_polar (.png, .pdf)\n');
end
