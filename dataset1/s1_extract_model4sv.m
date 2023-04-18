% Prepare behavioral data for mvpa fMRI analysis
% Author: Yuanwei Yao
% Date: Jan, 2022

%% basic settings
clear
clc

% run-trial sv estimates
matfile     = 'egt_model4sv';
data_fold   = '/Volumes/ERGT/beh_data/outputs/';
anal_fold   = '/Volumes/ERGT/EGT/univariate/';

% data file info
data_file   = fullfile(data_fold, 'allsub_MG_T09-Mar-2022.csv');
fit_file    = fullfile(data_fold, 'egt_power_fit.csv');
% task type: 1 effort, 2 risk
task_type   = 1;
data_all    = readtable(data_file);
% sub and task info
subi        = unique(data_all.sub);
% exclude sub-24
subi        = subi(subi~=24);
SubNum      = length(subi);
RunNum      = 5;
% model-fit parameter values
fit_p       = readtable(fit_file);

% missing trial recording
nr_record   = zeros(SubNum, RunNum+1);

% subjects with 4 runs
no_r1       = [35, 52];
no_r4       = 57;

for i = 1:SubNum
    si          = subi(i);
    sub_data    = data_all((data_all.sub==si) & (data_all.Effort1_Risk2==task_type),:);
    trial_n     = size(sub_data,1);
    sub_id      = sprintf('sub-%d', si);
    nr_record(i,6)  = si;
    % trial without response
    nan_ind     = (sub_data.response == 0)|isnan(sub_data.response);
    
    % calculate sv
    gaini       = sub_data.reward;
    lossi       = sub_data.loss;
    efforti     = sub_data.effort_risk;
    costi       = zeros(trial_n,1);
    % recode cost based effort level
    costi(efforti==1) = 0.3;
    costi(efforti==2) = 0.4;
    costi(efforti==3) = 0.5;
    costi(efforti==4) = 0.6;
    costi(efforti==5) = 0.7;    
    ki          = fit_p.k(i);
    pi          = fit_p.p(i);
    rhoi        = fit_p.rho(i);
    lambdai     = fit_p.lambda(i);
    % calculate sv based on power2 function
    svi         = (gaini.^rhoi) - lambdai*(lossi.^rhoi) - ki*(costi.^pi);
    sv_md       = median(svi);
    sv_high     = (svi >= sv_md);
    sv_low      = (svi < sv_md);
    
    % cue onset and trial duration
    cue_ons     = sub_data.StrTime;
    trial_dur   = sub_data.dur;
    trial_rt    = sub_data.RT;
    
    for ri = 1:RunNum
        
        
        trial_ri    = (sub_data.run == ri);
        % any trials without response?
        nan_ri      = trial_ri & nan_ind;
        % valid trial index
        valid_ri    = trial_ri & ~(nan_ind);
        sv_hri      = sv_high & valid_ri;
        sv_lri      = sv_low & valid_ri;
        
        % initialize names, onsets, durations for each run
        names       = {};
        onsets      = {};
        durations   = {};
        
        % cue onset
        cue_ons_ri  = cue_ons(valid_ri);
        svh_ons_ri  = cue_ons(sv_hri);
        svl_ons_ri  = cue_ons(sv_lri);
        efm_ons_ri  = cue_ons(ef_mri);
        rt_ri       = trial_rt(valid_ri);
        
        
        
        %% build spm mat
        % each valid cue as a separate regressor
        if max(nan_ri) > 0
            nr_ons_ri   = cue_ons(nan_ri);
            nr_dur_ri   = trial_dur(nan_ri);
            onsets      = {svh_ons_ri, svl_ons_ri, nr_ons_ri};
            names       = {'sv_high', 'sv_low', 'missing'};
            durations   = {0 0 nr_dur_ri};
            nr_record(i,ri)  = 1;
        else
            onsets      = {svh_ons_ri, svl_ons_ri};
            names       = {'sv_high', 'sv_low'};
            durations   = {0 0};
        end
        
        
        aim_fold    = fullfile(anal_fold, sub_id, 'beh');
        if ~isfolder(aim_fold)
            mkdir(aim_fold);
        end
        
        save([aim_fold '/' matfile '_r' num2str(ri) '.mat'], 'names', 'onsets', 'durations');
    end
end

save([anal_fold '/nr_record.mat'], 'nr_record');