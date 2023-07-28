function [sub_data, sub_sv] = edt_extract_sub_data(task_name, data_fold, data_all, si, sub_count)
% extract subject data for dataset 2: July 23, 2023, by Yuanwei Yao
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
    if strcmp(task_name, 'EDT')  
        
        % Note it in task_type
        task_type   = 1; 

        % Fit file name
        fit_file    = fullfile(data_fold, 'edt_power_fit.csv');

    % Risky task
    elseif strcmp(task_name, 'RDT')

        % Note it in task_type
        task_type   = 2;

        % Fit file name
        fit_file    = fullfile(data_fold, 'rdt_cpt_fit.csv');

    % Otherwise, show error message
    else
        error('Unknown task name!');
    end

    % Load model-fit parameter values
    fit_p       = readtable(fit_file);

    % Extract subject data
    sub_data    = data_all(data_all.subjID==si,:);
    
    % Trial number
    trial_n     = size(sub_data,1);

    % Index for chosen large-reward and small-reward option
    lro_ind     = (sub_data.choice == 1);
    sro_ind     = ~lro_ind;

    %% Calculate sv
    % Reward for the chosen option
    gaini       = lro_ind .* sub_data.amount_one + ...
                    sro_ind .* sub_data.amount_two;
    
    % Only the large-reward option is associated with a cost
    costi       = lro_ind .* sub_data.cost_one;

    % Extract sv according to the task type
    switch task_type

        % Effortful task 
        case 1

            % Calculate sv based on the 2-parameter power function
            % 3 free parameters: k, p, and rho
            ki          = fit_p.k(sub_count); % discounting rate
            pi          = fit_p.p(sub_count); % effort sensitivity
            rhoi        = fit_p.rho(sub_count); % outcome sensitivity
            
            % Calculate sv
            sub_sv      = (gaini.^rhoi) - ki*(costi.^pi);
        
        % Risky task
        case 2

            % Calculate sv based on the cumulative prospect theory
            % 3 free parameters: rho, gamma, and d1
            rhoi        = fit_p.rho(sub_count); % outcome sensitivity
            gammai      = fit_p.gamma(sub_count); % curvature of the weighting function
            d1i         = fit_p.delta1(sub_count); % elevation of the weighting function for gains

            % Probabilities are also need to calculate weights
            p1i         = (1-costi).^gammai; % winning probability
            p2i         = costi.^gammai; % losing probability
            w1i         = (d1i * p1i) ./ (d1i * p1i + p2i); % weights for gains
            
            % Calculate sv
            sub_sv      = (gaini.^rhoi) .* w1i; 

    end % end task_type switch loop
end
