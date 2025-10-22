function [y] = control_points_with_d_and_phi(X_p,d, phi)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
X_b = [X_p(1) - d*cos(phi) X_p(2)+ d* sin(-phi)];
X_t = [X_p(1) + d*cos(phi) X_p(2)+ d* sin(phi)];
y = [X_b; X_t];
end