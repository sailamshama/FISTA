function [X, iter, min_cost] = fista_backtracking(cal_f, grad, proj, Xinit, opts, calc_F)   
% function [X, iter, min_cost] = fista_backtracking(func, grad, proj, Xinit, L, opts, calc_F)   
% * A Fast Iterative Shrinkage-Thresholding Algorithm for 
% Linear Inverse Problems.
% * Solve the problem: X = arg min_X F(X) = f(X) + lambda*g(X) where:
%   - X: variable, can be a matrix.
%   - f(X): a smooth convex function with continuously differentiable 
%       with Lipschitz continuous gradient `L(f)` (Lipschitz constant of 
%       the gradient of `f`).
%  INPUT:
%       cal_f  : a function calculating f(x) in F(x) = f(x) + g(x) 
%       grad   : a function calculating gradient of f(X) given X.
%       proj   : a function calculating pL(x) -- projection
%       Xinit  : a matrix -- initial guess.
%       L      : a scalar the Lipschitz constant of the gradient of f(X).
%       opts   : a struct
%           opts.lambda  : a regularization parameter, can be either a scalar or
%                           a weighted matrix.
%           opts.max_iter: maximum iterations of the algorithm. 
%                           Default 300.
%           opts.tol     : a tolerance, the algorithm will stop if difference 
%                           between two successive X is smaller than this value. 
%                           Default 1e-8.
%           opts.verbose : showing F(X) after each iteration or not. 
%                           Default false. 
%           opts.L0 : a positive scalar. 
%           opts.eta: (must be > 1). eta in the algorithm (page 194)
%
%       calc_F: optional, a function calculating value of F at X 
%               via feval(calc_F, X). 
%  OUTPUT:
%      X        : solution
%      iter     : number of run iterations
%      min_cost : the achieved cost
% Modifications:
% 06/17/2016: set default value for opts.pos = false
% -------------------------------------
% Author: Tiep Vu, thv102, 4/6/2016
% (http://www.personal.psu.edu/thv102/)
% -------------------------------------
%     opts = initOpts(opts);
    if ~isfield(opts, 'max_iter')
        opts.max_iter = 500;
    end
    if ~isfield(opts, 'regul')
        opts.regul = 'l1';
    end     
    if ~isfield(opts, 'pos')
        opts.pos = false;
    end
    
    if ~isfield(opts, 'tol')
        opts.tol = 1e-8;
    end
    
    if ~isfield(opts, 'verbose')
        opts.verbose = false;
    end

    if ~isfield(opts, 'L0')
        opts.L0 = 1;
    end 
    if ~isfield(opts, 'eta')
        opts.eta = 2;
    end 

    %% computer g 
    function res = g(x) 
        if strcmp(opts.regul, 'l1')
            res = opts.lambda*norm1(x);
        end 
    end 

    %% computer Q 
    function res = calc_Q(x, y, L) 
        % based on equation 2.5, page 189
        res = feval(cal_f, y) + (x - y)'*feval(grad, y) ...
                    + L/2*normF2(x - y) + g(x);
    end 

%     Linv = 1/L;    
%     lambdaLiv = opts.lambda*Linv;
    % opts_shrinkage = opts;
    % opts_shrinkage.lambda = lambdaLiv;
    x_old = Xinit;
    y_old = Xinit;
    t_old = 1;
    iter = 0;
    cost_old = 1e10;
    %% MAIN LOOP
    opts_proj = opts;
%     opts_proj.lambda = lambdaLiv;
    Lold = opts.L0;
    while  iter < opts.max_iter
        iter = iter + 1;
        % find i_k 
        ik = 0; 
        Lbar = Lold; 
        while true 
            opts0 = opts;
            opts0.lambda = opts.lambda/Lbar; 
            zk = feval(proj, y_old - 1/Lbar*feval(grad, y_old), opts0);
            F = calc_F(zk);
            Q = calc_Q(zk, y_old, Lbar);
            Lbar = Lbar*opts.eta; 
            Lold = Lbar; 
            if F <= Q 
                break;
            end             
        end 
        
        opts_proj.lambda = opts.lambda/Lold;
        x_new = feval(proj, y_old - 1/Lold*feval(grad, y_old), opts_proj);
        t_new = 0.5*(1 + sqrt(1 + 4*t_old^2));
        y_new = x_new + (t_old - 1)/t_new * (x_new - x_old);
        %% check stop criteria
        e = norm1(x_new - x_old)/numel(x_new);
        if e < opts.tol
            break;
        end
        %% update
        x_old = x_new;
        t_old = t_new;
        y_old = y_new;
        %% show progress
        if opts.verbose
            if nargin ~= 0
                cost_new = feval(calc_F, x_new);
                if cost_new <= cost_old 
                    stt = 'YES.';
                else 
                    stt = 'NO, check your code.';
                end
                fprintf('iter = %3d, cost = %f, cost decreases? %s\n', ...
                    iter, cost_new, stt);
                cost_old = cost_new;
            else 
                if mod(iter, 5) == 0
                    fprintf('.');
                end
                if mod(iter, 10) == 0 
                   fprintf('%d', iter);
                end     
            end        
        end 
    end
    X = x_new;
    if nargout == 3 
        min_cost = feval(calc_F, X);
    end 
end 