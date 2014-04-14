% MLEstimationTest

a     = 1;
b     = -2;
delta = 0;
k     = 0.02;
r     = 0.02;

chi  = 1;
zeta = 1;

model.params                    = [a b delta k r];
[model.shocks.e,model.shocks.w] = qnwnorm(20);

interp.s = linspace(min(model.shocks.e),20,500)';

gcp;
pctRunOnAll warning('off','backtrace');
pctRunOnAll warning('off','RECS:FailureREE');
pctRunOnAll warning('off','MATLAB:interp1:ppGriddedInterpolant');

options = struct('ActiveParams' , [1 1 0 1],...
                 'Display'      , 'off',...
                 'InterpMethod' , 'spline',...
                 'MaxIter'      , 1E3  ,...
                 'TolX'         , 1E-10 ,...
                 'reesolveroptions',struct('atol',1E-10),...
                 'cov'          , 3,...
                 'solver','fminsearch',...
                 'ParamsTransform', @(P) [P(1); log(-P(2))/chi; log(P(3)+r); log(P(4))/zeta],...
                 'ParamsTransformInv', @(P) [P(1); -exp(chi*P(2)); exp(P(3))-r; exp(zeta*P(4))],...
                 'ParamsTransformInvDer', @(P) [1; -chi*exp(chi*P(2)); exp(P(3)); zeta*exp(zeta*P(4))],...
                 'solveroptions',optimset('DiffMinChange', eps^(1/3),...
                                          'Display'      , 'off',...
                                          'FinDiffType'  , 'central',...
                                          'LargeScale'   , 'off',...
                                          'MaxFunEvals'  , 2000,...
                                          'MaxIter'      , 1000,...
                                          'TolFun'       , 1e-6,...
                                          'TolX'         , 1e-7,...
                                          'UseParallel'  , 'always'),...
                 'numjacoptions',struct('FinDiffType','central'),...
                 'numhessianoptions',struct('FinDiffRelStep'  , 1E-3,...
                                            'UseParallel'     , 'always'),...
                 'T'          , 5,...
                 'UseParallel', 'never');

interp = SolveStorageDL(model,interp,options);
rng(0)
[Asim,Xsim] = SimulStorage(model,interp,0,1E3);

Pobs = squeeze(Xsim(1,2,:));

% clear LogLik
% [theta,Lik,vcov,g,hess,exitflag,output] = MaxLik(@(theta,obs) LogLik(theta,obs,model,interp,options),...
%                                                  [2 -4 0 0.1]', ...
%                                                  Pobs,options);
% options.solver = 'fminunc';
% [theta,Lik,vcov,g,hess,exitflag,output] = MaxLik(@(theta,obs) LogLik(theta,obs,model,interp,options),...
%                                                  theta, ...
%                                                  Pobs,options);

% agrid  = sort(unique([linspace(a*0.8,a*1.2,40)'; a]));
% bgrid  = sort(unique([linspace(b*1.2,b*0.8,40)'; b]));
% abgrid = gridmake(agrid,bgrid);
% res    = NaN(size(abgrid,1),3);
% res(:,1:2) = abgrid;
% parfor i=1:size(abgrid,1)
%   params = [abgrid(i,:) delta k];
%   res(i,3) = sum(LogLik(params,Pobs,model,interp,options));
% end
% contour(bgrid,agrid,reshape(res(:,3),length(agrid),length(bgrid)),20)
% figure
% surf(bgrid,agrid,reshape(res(:,3),length(agrid),length(bgrid)))

%options.solveroptions.MaxIter = 0;
[theta,Lik,vcov,g,hess,exitflag,output] = MaxLik(@(theta,obs) LogLik(theta,obs,model,interp,options),...
                                                 model.params(1:4)', ...
                                                 Pobs,options);

Results = ProfileLik(@(theta,obs) LogLik(theta,obs,model,interp,options),...
                     model.params(1:4)',Pobs,options);