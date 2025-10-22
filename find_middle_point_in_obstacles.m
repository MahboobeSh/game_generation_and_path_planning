function [X_m] = find_middle_point_in_obstacles(obstacles)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
X_m = [];
for i=1:2:size(obstacles, 1)
x= (obstacles(i, 1)+ obstacles(i+1, 1) )/2;
y = (obstacles(i, 2)+obstacles(i+1, 2))/2;
temp = [x, y];
X_m = [X_m; temp];

end