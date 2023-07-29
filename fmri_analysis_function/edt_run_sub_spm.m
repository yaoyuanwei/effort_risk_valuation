function matlabbatch = edt_run_sub_spm(task_name, anal_type, anal_fold, sub_fold, nr_ind, run_n, si)
% EDT_RUN_SUB_SPM: Run first level analysis on SPM for effort-based decision-making
% July 23, 2023, Yuanwei Yao
%
% Input:
%   task_name:  Name of the task for analysis, e.g., 'edt'
%   anal_type:  Type of task type: MVPA or univariate
%   anal_fold:  Name of the main fMRI analysis folder
%   sub_fold:   Subject folder
%   nr_ind:     No-response index
%   run_n:      Run number
%   si:         Subject numeric id (e.g., 20)
%
% Output:
%   sub_sv:     Subjective values for each subject
%   sub_data:   Data for a subject

    % Name for the model
    model_i     = [task_name, '_model_sv'];

    % Contrast number: sv
    n_con   = 1;

    % Number of key regressors: high and low sv
    n_kreg  = 2;

    % Univariate analysis is based on soomthed data
    if strcmp(anal_type, 'univariate')

        % Prefix for smoothed data
        dat_filt = '^swr.*\.nii$';

    % MVPA is based on unsmoothed data
    elseif strcmp(anal_type, 'mvpa')

        % Prefix for unsmoothed data
        dat_filt = '^wr.*\.nii$';
    end 

    % Initialize weight vector
    w_vec_comb  = [];

    % Initiate spm batch structure
    matlabbatch = {};

    % Load an empty spm file so that we can only fill out the necessary inputs
    load(fullfile(anal_fold, 'spm_model', 'edt_model.mat')); 

    % Read images
    fimg   = spm_select('ExtFPListRec', fullfile(sub_fold,'fun1'), dat_filt, Inf);

    % Read head motion txt files
    rpfiles = fullfile(sub_fold,'rp/*.txt');

    % Find the name of head motion files
    rpinfo  = dir(rpfiles);

    % Full path and name of head motion files
    headm_path = fullfile(sub_fold,'rp', rpinfo(1).name); 

    % Regressors file path
    mreg_path    = [sub_fold '/beh/' model_i '_1run.mat'];

    % Specify contrast vector
    if (nr_ind(1,2) == 1) 

        % 12+2 events: (cue_sv_high, cue_sv_low)*6, choice, missing, 6 head motions 
        n_reg   = (n_kreg*run_n +2 +6);

        % generate
        w_vec   = zeros(n_con,n_reg);

    elseif (nr_ind(1,2) == 0) 
        % 12+1 events: (cue_sv_high, cue_sv_low)*6 choice, 6 head motions 
        n_reg   = (n_kreg*run_n +1 +6);
        
    end

    % Initiate the weighted contrast vector 
    w_vec   = zeros(n_con,n_reg);

    % All high sv runs coded as 1
    w_vec(1,[1,3,5,7,9,11])     = 1;

    % All high sv runs coded as -1
    w_vec(1,[2,4,6,8,10,12])    = -1;

    % The weight vector used for the SPM
    w_vec_comb  = w_vec;

    %% Specify necessary SPM inputs
    % Output directory
    matlabbatch{1}.spm.stats.fmri_spec.dir = {[sub_fold '/results/' model_i]};

    % Path of fMRI data
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).scans = cellstr(fimg);

    % Path of regressors
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).multi = {mreg_path};

    % Path of the head motion file
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).multi_reg = {headm_path};

    % Contrast name
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.name='cue_high_low_sv';

    % Only one row for the contrast vector
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights= w_vec_comb(1,:);

    % No need to repeat vectors
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep='none';
    
    % Save batch file for each subject
    save([sub_fold '/' model_i '_' int2str(si) '.mat'],'matlabbatch');

    % Run spm
    spm_jobman('run', matlabbatch);

    % Back to the analysis directory
    cd(anal_fold);        
end
