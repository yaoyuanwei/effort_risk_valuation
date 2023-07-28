% Function to extract behavioral data and subjective value for a subject
% Author: Yuanwei Yao
% Date: July 23, 2023

function [sub_data, sub_sv] = edt_extract_sub_data(task_name, data_fold, data_all, si, sub_count)

    % select data based on task type
    % effortful task
    if strcmp(task_name, 'EDT')  
        task_type   = 1; 
        % fit file name
        fit_file    = fullfile(data_fold, 'edt_power_fit.csv');

    % risky task
    elseif strcmp(task_name, 'RDT')
        task_type   = 2;
        % fit file name
        fit_file    = fullfile(data_fold, 'rdt_cpt_fit.csv');

    % otherwise, show error message
    else
        error('Unknown task name!');
    end

    % load model-fit parameter values
    fit_p       = readtable(fit_file);

    % extract subject data
    sub_data    = data_all(data_all.subjID==si,:);
    
    % trial number
    trial_n     = size(sub_data,1);

    % index for chosen large-reward and small-reward option
    lro_ind     = (sub_data.choice == 1);
    sro_ind     = ~lro_ind;

    % calculate sv
    % reward for the chosen option
    gaini       = lro_ind .* sub_data.amount_one + ...
                    sro_ind .* sub_data.amount_two;
    
    % only the large-reward option is associated with a cost
    costi       = lro_ind .* sub_data.cost_one;

    % extract sv according to the task type
    switch task_type

        % effortful task 
        case 1

            % calculate sv based on the 2-parameter power function
            % 3 free parameters:
            ki          = fit_p.k(sub_count); % discounting rate
            pi          = fit_p.p(sub_count); % effort sensitivity
            rhoi        = fit_p.rho(sub_count); % outcome sensitivity
            % calculate sv
            sub_sv      = (gaini.^rhoi) - ki*(costi.^pi);
        
        % risky task
        case 2

            % calculate sv based on the CPT
            % 3 free parameters:
            rhoi        = fit_p.rho(sub_count); % outcome sensitivity
            gammai      = fit_p.gamma(sub_count); % curvature of the weighting function
            d1i         = fit_p.delta1(sub_count); % elevation of the weighting function for gains
            % probabilities are also need to calculate weights
            p1i         = (1-costi).^gammai; % winning probability
            p2i         = costi.^gammai; % losing probability
            w1i         = (d1i * p1i) ./ (d1i * p1i + p2i); % weights for gains
            % calculate sv
            sub_sv      = (gaini.^rhoi) .* w1i; 

    end % end task_type switch loop
end
