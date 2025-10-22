function out = sigmoidDistanceFunction(distance, safeRadius, k)
%UNTITLED7 Summary of this function goes here
%   Detailed explanation goes here
out = 1 ./ (1 + exp(-k * (distance - safeRadius)));
end

% Define distance values
