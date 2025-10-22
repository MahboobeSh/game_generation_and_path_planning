
function coeff = binomial_coefficient(n, k)
    coeff = factorial(n) / (factorial(k) * factorial(n - k));
end