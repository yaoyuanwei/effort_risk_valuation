% Function to run 1st-level analysis on SPM
% Author: Yuanwei Yao
% Date: July 23, 2023

function matlabbatch = edt_run_sub_spm(task_name, anal_type, anal_fold, sub_fold, nr_ind, run_n, si)

    % name for the model
    model_i     = [task_name, '_model_sv'];

    % contrast number: sv
    n_con   = 1;
    % number of key regressors: high and low sv
    n_kreg  = 2;

    % univariate analysis is based on soomthed data
    if strcmp(anal_type, 'univariate')
        dat_filt = '^swr.*\.nii$';
    % but mvpa based on unsmoothed data
    elseif strcmp(anal_type, 'mvpa')
        dat_filt = '^wr.*\.nii$';
    end 

    % initialize weight vector and batch structure
    w_vec_comb  = [];
    matlabbatch = {};

    % load an empty spm file so that we can only fill out the necessary inputs
    load(fullfile(anal_fold, 'spm_model', 'edt_model.mat')); 

    % read images
    fimg   = spm_select('ExtFPListRec', fullfile(sub_fold,'fun1'), dat_filt, Inf);

    % read head motion files
    rpfiles = fullfile(sub_fold,'rp/*.txt');
    rpinfo  = dir(rpfiles);
    headm_path = fullfile(sub_fold,'rp', rpinfo(1).name); 

    % regressors file path
    mreg_path    = [sub_fold '/beh/' model_i '_1run.mat'];

    % specify contrast vector
    if (nr_ind(1,2) == 1) 
        % 12+2 events: (cue_sv_high, cue_sv_low)*6, choice, missing, 6 head motions 
        n_reg   = (n_kreg*run_n +2 +6);
        w_vec   = zeros(n_con,n_reg);
    elseif (nr_ind(1,2) == 0) 
        % 12+1 events: (cue_sv_high, cue_sv_low)*6 choice, 6 head motions 
        n_reg   = (n_kreg*run_n +1 +6);
        w_vec   = zeros(n_con,n_reg);
    end
    % high vs. low sv, leave others as zeros
    w_vec(1,[1,3,5,7,9,11])     = 1;
    w_vec(1,[2,4,6,8,10,12])    = -1;
    w_vec_comb  = w_vec;

    % output directory
    matlabbatch{1}.spm.stats.fmri_spec.dir = {[sub_fold '/results/' model_i]};

    % add fMRI data, regressors, and rp file to the spm file
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).scans = cellstr(fimg);
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).multi = {mreg_path};
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).multi_reg = {headm_path};

    % add contrast info, same for all subjects
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.name='cue_high_low_sv';
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights= w_vec_comb(1,:);
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep='none';
    
    % save batch file for each sub for checking
    save([sub_fold '/' model_i '_' int2str(si) '.mat'],'matlabbatch');

    % run spm
    spm_jobman('run', matlabbatch);

    % back to the analysis directory
    cd(anal_fold);        
end
