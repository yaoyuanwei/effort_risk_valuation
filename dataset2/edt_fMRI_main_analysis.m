% Script for fMRI analysis
% Author: Yuanwei Yao
% Date: July 23, 2023

clear
clc

%% Basic settings
% task nameL EDT: effort, RDT: risk
task_name   = 'EDT';
% analysis: univariate or mvpa
anal_type   = 'mvpa';

% folder for behavioral data
base_fold   = ['/Volumes/projects/ERDT/', task_name];
data_fold   = fullfile(base_fold, 'beh_data');

% folder for fMRI data
anal_fold   = ['/Volumes/ERGT/', task_name, '/', anal_type];
    
% get subject folder list
sub_flist   = dir(fullfile(anal_fold, 'Sub*'));

% path of behavioral data files
data_file   = fullfile(data_fold, ['Data_' task_name '_DVD.csv']);
data_all    = readtable(data_file);

% extract necessary sub info based on task type
sub_id      = unique(data_all.subjID);
sub_n       = length(sub_id);

% task info
% run numbers
run_n       = 6;

%% Do the analysis for each subject
for i = 1:sub_n

    % sub_id
    si              = sub_id(i);
    
    % sub fMRI folder
    sub_fold        = fullfile(anal_fold, sub_flist(i).name);
    
    % extract behaviral data and calculate subject values for each subject 
    [sub_data, sub_sv] = edt_extract_sub_data(task_name, data_fold, data_all, si, i);

    % generate events and timing information for SPM
    [onsets, names, durations, nr_ind] = edt_extract_model(task_name, anal_fold, sub_data, run_n, sub_sv, si);
    
    % run 1st-level analysis on SPM
    matlabbatch = edt_run_sub_spm(task_name, anal_type, anal_fold, sub_fold, nr_ind, run_n, i);
    
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
