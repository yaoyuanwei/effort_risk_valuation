% Script for fMRI analysis
% Author: Yuanwei Yao
% Date: July 23, 2023

clear
clc

%% Basic settings
% task nameL egt: effort, rgt: risk
task_name   = 'egt';
% analysis: univariate or mvpa
anal_type   = 'mvpa';

% folder for behavioral data
data_fold   = '/Volumes/ERGT/beh_data/outputs/';

% folder for fMRI data
anal_fold   = ['/Volumes/ERGT/', task_name, '/', anal_type];
    
% get subject folder list
sub_flist     = dir(fullfile(anal_fold, 'sub*'));

% load behavioral data for all subjects
data_file   = fullfile(data_fold, 'allsub_MG_T09-Mar-2022.csv');
data_all    = readtable(data_file);

% extract necessary sub info based on task type
[sub_id, sub_n] = egt_extract_sub_info(task_name, data_all);

% run numbers
run_n       = 5;

% file that records runs with no-response trials, additional colume for sub_id
nr_record   = zeros(sub_n, run_n+1);

%% Do the analysis for each subject
for i = 1:sub_n

    % sub_id
    si      = sub_id(i);
    % sub fMRI folder
    sub_fold    = fullfile(anal_fold, sub_flist(i).name);

    % extract behaviral data and calculate subject values for each subject 
    [sub_data, sub_sv] = egt_extract_sub_data(task_name, data_fold, data_all, si, i);

    % generate events and timing information for SPM
    [onsets, names, durations, nr_ind] = egt_extract_model(task_name, anal_fold, sub_data, run_n, sub_sv, si);
    
    % update no-response trial matrix
    nr_record(i,:)  = nr_ind;
    
    % run 1st-level analysis on SPM
    matlabbatch = egt_run_sub_spm(task_name, anal_type, anal_fold, nr_record, si);
    
    % for MVPA: decoding + smoothing
    if strcmp(anal_type, 'mvpa')
        % decoding lables
        labelname1 = 'sv_high';
        labelname2 = 'sv_low';
        % run decoding and get the file names for copying
        [source_file, dest_file] = run_decoding(task_name, anal_fold, sub_fold, labelname1, labelname2, si);
    
    % for univariate: smoothing is not required 
    elseif strcmp(anal_type, 'univariate')
        % contrast to be copied
        cons_copy  = {'con_0001.nii'};     
        % get the file names for copying
        [source_file, dest_file] = copy_contrast(task_name, anal_fold, sub_fold, cons_copy, si);
    end
    
    % copy contrast or decoding map
    copyfile(source_file, dest_file);
end

% save the no-response recording matrix
save([anal_fold '/nr_record.mat'], 'nr_record');