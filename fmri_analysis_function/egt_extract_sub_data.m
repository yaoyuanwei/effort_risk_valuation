function [sub_data, sub_sv] = egt_extract_sub_data(task_name, data_fold, data_all, si, sub_count)
% EGT_EXTRACT_SUB_DATA: Extract behavioral data and subjective values for effort-based gambling
% July 23, 2023, by Yuanwei Yao
%
% This function is to extract behavioral data and subjective values for a subject
%
% Input:
%   task_name:  Name of the task for analysis, e.g., 'ddt'
%   anal_fold:  Name of the main fMRI analysis folder
%   data_all:   Data for all subjects
%   si:         Subject numeric id (e.g., 20)
%   sub_count:  Order of the current subject (e.g., 1)
%
% Output:
%   sub_sv:     Subjective values for each subject
%   sub_data:   Data for a subject

    %% Select data based on task type
    % Effortful task
    if strcmp(task_name, 'egt')

        % Note it in task_type  
        task_type   = 1; 

        % Fit file name
        fit_file    = fullfile(data_fold, 'egt_power_fit.csv');

    % Risky task
    elseif strcmp(task_name, 'rgt')

        % Note it in task_type 
        task_type   = 2;
        
        % Fit file name
        fit_file    = fullfile(data_fold, 'rgt_cpt_fit.csv');

    % Otherwise, show error message
    else
        error('Unknown task name!');
    end

    % Load model-fit parameter values
    fit_p       = readtable(fit_file);

    % Extract subject data
    sub_data    = data_all((data_all.sub==si) & (data_all.Effort1_Risk2==task_type),:);
    
    % Trial number
    trial_n     = size(sub_data,1);

    %% Calculate sv
    % Gain and loss info
    gaini       = sub_data.reward;
    lossi       = sub_data.loss;

    % Create a zero vector to store cost info
    costi       = zeros(trial_n,1);

    % Extract cost info according to the task type
    switch task_type

        % Effortful task 
        case 1
            
            % Effort level info
            efforti     = sub_data.effort_risk;

            % Recode cost based effort level
            costi(efforti==1) = 0.3;
            costi(efforti==2) = 0.4;
            costi(efforti==3) = 0.5;
            costi(efforti==4) = 0.6;
            costi(efforti==5) = 0.7;

            % Calculate sv based on the 2-parameter power function
            % 4 free parameters: k, p, rho, and lambda
            ki          = fit_p.k(sub_count); % discounting rate
            pi          = fit_p.p(sub_count); % effort sensitivity
            rhoi        = fit_p.rho(sub_count); % outcome sensitivity
            lmdi        = fit_p.lambda(sub_count); % loss aversion parameter
            
            % Calculate sv
            sub_sv      = (gaini.^rhoi) - lmdi*(lossi.^rhoi) - ki*(costi.^pi);
        
        % Risky task
        case 2
            
            % Risk level info
            riski       = sub_data.effort_risk;

            % Recode cost based risk level
            costi(riski==1) = 0.1;
            costi(riski==2) = 0.3;
            costi(riski==3) = 0.5;
            costi(riski==4) = 0.7;
            costi(riski==5) = 0.9;

            % Calculate sv based on the cumulative prospect theory
            % 5 free parameters: rho, lambda, gamma, delta1, delta2
            rhoi        = fit_p.rho(sub_count); % outcome sensitivity
            lmdi        = fit_p.lambda(sub_count); % loss aversion parameter
            gammai      = fit_p.gamma(sub_count); % curvature of the weighting function
            d1i         = fit_p.delta1(sub_count); % elevation of the weighting function for gains
            d2i         = fit_p.delta2(sub_count); % elevation of the weighting function for losses
            
            % Probabilities are also need to calculate weights
            p1i         = (1-costi).^gammai; % winning probability
            p2i         = costi.^gammai; % losing probability
            w1i         = (d1i * p1i) ./ (d1i * p1i + p2i); % weights for gains
            w2i         = (d2i * p2i) ./ (d2i * p2i + p1i); % weights for losses
            
            % Calculate sv
            sub_sv      = (gaini.^rhoi) .* w1i - lmdi * ((lossi.^rhoi) .* w2i); 

    end % end task_type switch loop
end
