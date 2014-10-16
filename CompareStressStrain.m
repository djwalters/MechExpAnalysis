function [Modulus1,ModulusCI1,Strain1,Modulus2,ModulusCI2,Strain2,PercChange] = CompareStressStrain(userstrain)
% CompareStressStrain.m
% This function utilizes the computation of the mechanical moduli in the
% external function "StressStrain.m" and compares the mechanical moduli of
% a pair of related tests.  The first call is for the baseline properties
% for which to compare to the second call.  This function can be used for
% multiple mechanical moduli in seperate runs (e.g. shear modulus or
% Young's modulus).  In addition, this also compares the respective yield
% and ultimate strengths of each sample.
%
% INPUTS:
%           userstrain: the user picks the source of strain data for
%           analyzing stress and strain. Valid choices are:
%               'dispx' - Displacement X
%               'dispy' - Displacement Y
%               'epsx' - Strain X
%               'epsy' - Strain Y
%               'epsxy' - Shear Strain
%               'major' - Major Strain
%               'minor' - Minor strain
%
% OUTPUTS:
%           Modulus1: The slope of the stress strain curve during the
%           linear elastic portion of loading of the baseline test.
%               Ex: 
%               -If using epsxy, this would be the shear modulus in (Pa)
%               -If using Major/Minor strain, this would be Young's modulus
%               in the direction of the respective strain (Pa)
%
%           ModulusCI1 - The lower and upper bounds of the 95% confidence
%           interval of the calculated modulus of the baseline test.
%           (described above)
%
%           Strain1: The strain vector of the baseline test which is
%           averaged across the number of stagepoints utilized in the
%           ARAMIS analysis.  Locations of the stagepoints are determined
%           seperately
%       
%           Modulus2,ModulusCI2,Strain2: See above descriptions except
%           these are the values for the 2nd test of the pair (the
%           comparative test).
%
%           PercChangeMod: This is the percent change in the moduli
%           calculated in Modulus1 and Modulus2 (based on Modulus1).
%
% VERSION: 1.0
% DATE: June 5, 2014
% AUTHOR: David J Walters; Montana State University

%% Import Strain Data
% Call external function StressStrain.m to import and calculate the moduli
% of each test being compared.  See documentation for usage parameters at
% the top of the function file.
[Modulus1,ModulusCI1,Strain1,Stress1,ModEqn1] = StressStrain(userstrain,1);
[Modulus2,ModulusCI2,Strain2,Stress2,ModEqn2] = StressStrain(userstrain,1);

%% Compare Moduli
PercChange = ((Modulus2-Modulus1)/Modulus1)*100;

%% Set Plot Controls
ebwidth = 0.1;  % Errorbar cap width
font = 'Palatino Linotype';
fsize = 11;
msize = 5;

%% Plots
% Plot stress strain curves together with linear fits
switch userstrain
    case 'epsxy'
        figure('Name','Shear Stress/Strain','NumberTitle','off')
        plot(ModEqn1,'m-',-Strain1,Stress1,'b.')
        grid on
        hold on
        plot(ModEqn2,'r-.',-Strain2,Stress2,'k*')
        x1 = xlabel('Shear Strain (rad)');
        y1 = ylabel('Stress (Pa)');
        leg = legend('Non-Layered Data','Non-Layered Fit',...
            'Layered Data','Layered Fit','Location','best');
        set(gca,'FontName',font,'FontSize',fsize)
        set([y1 x1],'FontName',font,'FontSize',fsize)
        set(leg,'FontName',font,'FontSize',fsize)
        axis('auto')
end
end