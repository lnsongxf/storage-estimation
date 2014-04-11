ComPrices = readtable(fullfile('..','Data','ComPrices-DL1995.csv'),'ReadRowNames',true);

ComList = {'Coffee'; 'Copper'; 'Jute'; 'Maize'; 'Palmoil'; 'Sugar'; 'Tin'};

NActiveParams = 3;
Lik           = zeros(length(ComList),1);
exitflag      = zeros(length(ComList),1);
output        = cell(length(ComList),1);
V             = zeros(length(ComList),NActiveParams);
theta         = zeros(4,length(ComList));
thetainit     = zeros(4,length(ComList));
pstar         = zeros(length(ComList),1);
G             = zeros(length(ComList),1);

GridLimits = table(-5*ones(7,1),[30 40 30 40 30 20 45]','RowNames',ComList, ...
                   'VariableNames',{'Min' 'Max'});

options = struct('ActiveParams' , [1 1 0 1],...
                 'Display'      , 'off',...
                 'interp'       , 'linear',...
                 'MaxIter'      , 1E3  ,...
                 'TolX'         , 1E-10 ,...
                 'reesolveroptions',struct('atol',1E-10),...
                 'cov'          , 3,...
                 'ParamsTransformInvDer', @(P) [1; -exp(P(2)); exp(P(3)); exp(P(4))],...
                 'solveroptions',optimset('DiffMinChange', eps^(1/3),...
                                          'Display'      , 'iter',...
                                          'FinDiffType'  , 'central',...
                                          'LargeScale'   , 'off',...
                                          'MaxFunEvals'  , 0,...
                                          'MaxIter'      , 0,...
                                          'TolFun'       , 1e-6,...
                                          'TolX'         , 1e-7,...
                                          'UseParallel'  , 'never'),...
                 'numjacoptions',struct([]),...
                 'numhessianoptions',struct('FinDiffRelStep'  , 1E-3,...
                                            'UseParallel'     , 'never'),...
                 'T'          , 5,...
                 'UseParallel', 'never');

warning('off','backtrace');
warning('off','RECS:FailureREE');
warning('off','MATLAB:interp1:ppGriddedInterpolant');
N = [2 100 200];

%% Estimate in all situations
r=0.02;
options.ParamsTransform = @(P) [P(1); log(-P(2)); log(P(3)+r); log(P(4))];
options.ParamsTransformInv = @(P) [P(1); -exp(P(2)); exp(P(3))-r; exp(P(4))];
solver={'fminsearch'};
options.solver = solver{:};
com=1;
[Pobs,model,interp,tmp] = initpb(ComList{com},...
                                 [],...
                                 r,...
                                 GridLimits{com,:},...
                                 N, ...
                                 ComPrices,...
                                 options);
theta = [0.2652 -0.4035 0 0.0098];
model.params = [theta r];
interp                = SolveStorageEGM(model,interp,options);
clear LogLik
[thetatmp,Lik(com),vcov,g,hess,exitflag(com),output{com}] = MaxLik(@(theta,obs) LogLik(theta,obs,model,interp,options),...
                                                  theta', ...
                                                  Pobs,options);
par                   = num2cell(model.params);
[a, b, delta, k, r]   = par{:}; %#ok<ASGLU>
demand                    = @(p) (p-a)/b;
invdemand                 = @(d) a+b*d;
invPriceFunction = interp1(interp.x(:,2),interp.s,'linear','pp');
Aobs             = max(ppval(invPriceFunction,Pobs),demand(Pobs));
[min(Aobs),max(Aobs)]
[min(interp.s),max(interp.s)]