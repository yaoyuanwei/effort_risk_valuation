% Function to extract behavioral data for a subject
% Author: Yuanwei Yao
% Date: July 23, 2023

function [sub_data, sub_sv] = egt_extract_sub_data(task_name, data_fold, data_all, si, sub_count)

    % select data based on task type
    % effortful task
    if strcmp(task_name, 'egt')  
        task_type   = 1; 
        % fit file name
        fit_file    = fullfile(data_fold, 'egt_power_fit.csv');

    % risky task
    elseif strcmp(task_name, 'rgt')
        task_type   = 2;
        % fit file name
        fit_file    = fullfile(data_fold, 'rgt_cpt_fit.csv');

    % otherwise, show error message
    else
        error('Unknown task name!');
    end

    % load model-fit parameter values
    fit_p       = readtable(fit_file);

    % extract subject data
    sub_data    = data_all((data_all.sub==si) & (data_all.Effort1_Risk2==task_type),:);
    % trial number
    trial_n     = size(sub_data,1);

    % calculate sv
    % gain and loss info
    gaini       = sub_data.reward;
    lossi       = sub_data.loss;
    % create a zero vector to store cost info
    costi       = zeros(trial_n,1);

    % extract cost info according to the task type
    switch task_type

        % effortful task 
        case 1
            % recode cost based effort level
            efforti     = sub_data.effort_risk;
            costi(efforti==1) = 0.3;
            costi(efforti==2) = 0.4;
            costi(efforti==3) = 0.5;
            costi(efforti==4) = 0.6;
            costi(efforti==5) = 0.7;

            % calculate sv based on the 2-parameter power function
            % 4 free parameters:
            ki          = fit_p.k(sub_count); % discounting rate
            pi          = fit_p.p(sub_count); % effort sensitivity
            rhoi        = fit_p.rho(sub_count); % outcome sensitivity
            lmdi        = fit_p.lambda(sub_count); % loss aversion parameter
            % calculate sv
            sub_sv      = (gaini.^rhoi) - lmdi*(lossi.^rhoi) - ki*(costi.^pi);
        
        % risky task
        case 2
            % recode cost based risk level
            riski       = sub_data.effort_risk;
            costi(riski==1) = 0.1;
            costi(riski==2) = 0.3;
            costi(riski==3) = 0.5;
            costi(riski==4) = 0.7;
            costi(riski==5) = 0.9;

            % calculate sv based on the CPT
            % 5 free parameters:
            rhoi        = fit_p.rho(sub_count); % outcome sensitivity
            lmdi        = fit_p.lambda(sub_count); % loss aversion parameter
            gammai      = fit_p.gamma(sub_count); % curvature of the weighting function
            d1i         = fit_p.delta1(sub_count); % elevation of the weighting function for gains
            d2i         = fit_p.delta2(sub_count); % elevation of the weighting function for losses
            % probabilities are also need to calculate weights
            p1i         = (1-costi).^gammai; % winning probability
            p2i         = costi.^gammai; % losing probability
            w1i         = (d1i * p1i) ./ (d1i * p1i + p2i); % weights for gains
            w2i         = (d2i * p2i) ./ (d2i * p2i + p1i); % weights for losses
            % calculate sv
            sub_sv      = (gaini.^rhoi) .* w1i - lmdi * ((lossi.^rhoi) .* w2i); 

    end % end task_type switch loop
end
