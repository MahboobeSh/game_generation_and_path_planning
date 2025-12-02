function inside = isPointInsideRectangle(point, rectangle)
    % isPointInsideRectangle checks if a point is inside a rectangle
    %
    % Inputs:
    %   point - [x, y] coordinates of the point
    %   rectangle - [xMin, yMin, width, height] defining the rectangle
    %
    % Output:
    %   inside - true if point is inside rectangle, false otherwise
    
    x = point(1);
    y = point(2);
    
    xMin = rectangle(1);
    yMin = rectangle(2);
    width = rectangle(3);
    height = rectangle(4);
    
    xMax = xMin + width;
    yMax = yMin + height;
    
    % Check if point is inside rectangle (including borders)
    inside = (x >= xMin) && (x <= xMax) && (y >= yMin) && (y <= yMax);
end

