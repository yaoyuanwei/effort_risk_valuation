% Prepare behavioral data for model-based fMRI analysis
% Author: Yuanwei Yao
% Date: Feb, 2022

%% basic settings
clear all
clc
close all

% model: high vs low SV
matfile     = 'edt_model4sv_6fd';
base_fold   = '/Volumes/projects/ERDT/Effort';
data_fold   = fullfile(base_fold, 'beh_data');
anal_fold   = fullfile(base_fold, 'mvpa');

% DVD file info
DVD_Info    = dir(fullfile(data_fold, 'Result_EDT_DVD*'));
fit_file    = fullfile(data_fold, 'edt_fit_power.csv');
% load fitted parameter
fit_p       = readtable(fit_file);
SubNum      = size(fit_p, 1);
RunNum      = 6;
TrialNum    = 28;

% load onset file
edt_onset   = load(fullfile(data_fold, 'onset_edt.mat'));
edt_onset   = edt_onset.edt_onset;
edt_onset   = edt_onset(edt_onset(:,1)~=322,:);

% missing trial recording
nr_record   = zeros(SubNum, 2);


for i = 1:SubNum
    
    DVD_File        = DVD_Info(i).name;
    SubID           = str2double(DVD_File(19:21));
    nr_record(i,1)  = SubID;
    
    % some subjects have different run 2&3 onset
    run_ons         = zeros(1,3);
    run_ons(1)      = 0;  
    run_ons(2)      = edt_onset(i,8);
    run_ons(3)      = edt_onset(i,9);
    
    % load individual parameter
    ki      = fit_p.k(i);
    pi      = fit_p.p(i);
    rhoi    = fit_p.rho(i);
    % load data
    TrialResult     = load(fullfile(data_fold, DVD_File));
    TrialResult     = TrialResult.TrialResult;
    trial_n         = size(TrialResult,1);
    % index for chosen large-reward and small-reward option
    ind_large 		= TrialResult.DecisionResult=='AcceptLarge';
    ind_small 		= TrialResult.DecisionResult=='AcceptSmall';
    
    % sv parameter
    % cost small always = 0
    effort_chosen   = ind_large .* TrialResult.LevelName;
    
    reward_chosen   = ind_large .* TrialResult.LargeReward + ...
                      ind_small .* TrialResult.SmallReward;

    cost_chosen     = zeros(trial_n,1);

    % recode cost based effort level
    cost_chosen(effort_chosen==1)   = 0.5;
    cost_chosen(effort_chosen==2)   = 0.65;
    cost_chosen(effort_chosen==3)   = 0.8;
    cost_chosen(effort_chosen==4)   = 0.95;
    
    % calculate sv based on the power function
    sv_chosen       = (reward_chosen.^rhoi) - ki*(cost_chosen.^pi);

    % median relative sv used to split SVs
    sv_md           = median(sv_chosen);
    sv_high         = (sv_chosen >= sv_md);
    sv_low          = (sv_chosen < sv_md);
    
    % trial without response
    nan_ind         = isnan(TrialResult.DecisionRT);
    valid_ind       = ~(nan_ind);
    run1_ind        = [ones(TrialNum,1);zeros(TrialNum*5,1)];
    run2_ind        = [zeros(TrialNum,1); ones(TrialNum,1); zeros(TrialNum*4,1)];
    run3_ind        = [zeros(TrialNum*2,1); ones(TrialNum,1); zeros(TrialNum*3,1)];
    run4_ind        = [zeros(TrialNum*3,1); ones(TrialNum,1); zeros(TrialNum*2,1)];
    run5_ind        = [zeros(TrialNum*4,1); ones(TrialNum,1); zeros(TrialNum,1)];
    run6_ind        = [zeros(TrialNum*5,1); ones(TrialNum,1)];
    
    % onset info
    fix_ons         = TrialResult.TrialOnset_TrialResult;
    cue_ons         = fix_ons + TrialResult.FixDura;
    choice_ons      = cue_ons + 2;
    feedback_ons    = TrialResult.FeedbackOnset;

    % index for high and low relative sv trials
    sv_hi1          = sv_high & valid_ind & run1_ind;
    sv_li1          = sv_low & valid_ind & run1_ind;
    sv_hi2          = sv_high & valid_ind & run2_ind;
    sv_li2          = sv_low & valid_ind & run2_ind;
    sv_hi3          = sv_high & valid_ind & run3_ind;
    sv_li3          = sv_low & valid_ind & run3_ind;
    sv_hi4          = sv_high & valid_ind & run4_ind;
    sv_li4          = sv_low & valid_ind & run4_ind;
    sv_hi5          = sv_high & valid_ind & run5_ind;
    sv_li5          = sv_low & valid_ind & run5_ind;
    sv_hi6          = sv_high & valid_ind & run6_ind;
    sv_li6          = sv_low & valid_ind & run6_ind;
    

    % initialize names, onsets, durations, weight vector for each run
    names           = {};
    onsets          = {};
    durations       = {};
    
    % model trials with different rewards and those with same rewards
    % separately
    cue_svh1        = cue_ons(sv_hi1);
    cue_svl1        = cue_ons(sv_li1);
    cue_svh2        = cue_ons(sv_hi2);
    cue_svl2        = cue_ons(sv_li2);
    cue_svh3        = cue_ons(sv_hi3);
    cue_svl3        = cue_ons(sv_li3);
    cue_svh4        = cue_ons(sv_hi4);
    cue_svl4        = cue_ons(sv_li4);
    cue_svh5        = cue_ons(sv_hi5);
    cue_svl5        = cue_ons(sv_li5);
    cue_svh6        = cue_ons(sv_hi6);
    cue_svl6        = cue_ons(sv_li6);
    choice_valid    = choice_ons(valid_ind);
    
    %% build spm mat
    % each valid cue as a separate regressor
    if max(nan_ind) > 0
        nr_ons      = cue_ons(nan_ind);
        onsets      = {cue_svh1, cue_svl1, cue_svh2, cue_svl2, cue_svh3, cue_svl3, ...
                        cue_svh4, cue_svl4, cue_svh5, cue_svl5, cue_svh6, cue_svl6, ...
                        choice_valid, nr_ons};
        names       = {'cue_sv_high', 'cue_sv_low', 'cue_sv_high', 'cue_sv_low', ...
                        'cue_sv_high', 'cue_sv_low', 'cue_sv_high', 'cue_sv_low', ...
                        'cue_sv_high', 'cue_sv_low', 'cue_sv_high', 'cue_sv_low', ...
                        'choice', 'missing'};
        durations   = {0 0 0 0 0 0 0 0 0 0 0 0 2 4};
        nr_record(i,2)  = 1;
    else
        onsets      = {cue_svh1, cue_svl1, cue_svh2, cue_svl2, cue_svh3, cue_svl3, ...
                        cue_svh4, cue_svl4, cue_svh5, cue_svl5, cue_svh6, cue_svl6, ...
                        choice_valid};
        names       = {'cue_sv_high', 'cue_sv_low', 'cue_sv_high', 'cue_sv_low', ...
                        'cue_sv_high', 'cue_sv_low', 'cue_sv_high', 'cue_sv_low', ...
                        'cue_sv_high', 'cue_sv_low', 'cue_sv_high', 'cue_sv_low', ...
                        'choice'};
        durations   = {0 0 0 0 0 0 0 0 0 0 0 0 2};
    end
    
    
    aim_fold    = fullfile(anal_fold, sprintf('Sub%d', SubID), 'beh');
    if ~isfolder(aim_fold)
        mkdir(aim_fold);
    end
    
    save([aim_fold '/' matfile '_1run.mat'], 'names', 'onsets', 'durations');
end

% save([anal_fold '/nr_record.mat'], 'nr_record');