function isColliding = checkRectangleCollision(x1, y1, w1, h1, x2, y2, w2, h2)
    % This function checks if two rectangles defined by (x, y, w, h) are colliding
    horizontalOverlap = (x1 <= x2 + w2) && (x2 <= x1 + w1);
    verticalOverlap = (y1 <= y2 + h2) && (y2 <= y1 + h1);
    isColliding = horizontalOverlap && verticalOverlap;
end