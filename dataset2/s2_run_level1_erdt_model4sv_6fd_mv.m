clear;
clc;

%% excluded runs due to excessive head motions:

model_i     = 'edt_model4sv_6fd';
exp_dir     = '/Volumes/projects/ERDT/Effort/mvpa';
sub_dir     = dir(fullfile(exp_dir, 'Sub*'));

load(fullfile(exp_dir, 'nr_record.mat'));
subnum  = size(sub_dir,1);
n_con   = 1;

for i = 1:subnum
    sid         = sub_dir(i).name;
    sid         = str2double(sid(end-2:end));
    sub_fold    = fullfile(exp_dir, sub_dir(i).name);
    % initialize weight vector and batch structure
    w_vec_comb  = [];
    matlabbatch = {};

    load([exp_dir, '/spm_model/erdt_model4.mat']);

    fimg1   = spm_select('ExtFPListRec', fullfile(sub_fold,'fun1'), '^wr.*\.nii$', Inf);

    rpfiles = fullfile(sub_fold,'rp/*.txt');
    rpinfo  = dir(rpfiles);
    rp1path = fullfile(sub_fold,'rp', rpinfo(1).name);        
    % regressors file path
    reg1path    = [sub_fold '/beh/' model_i '_1run.mat'];


    nr_ind  = nr_record(i,2);
    if (nr_ind == 1) 
        % 12+2 events: (cue_sv_high, cue_sv_low)*6 choice, missing 
        n_reg   = (14+6);
        w_vec   = zeros(n_con,n_reg);
    elseif (nr_ind == 0) 
        % 12+1 events: (cue_sv_high, cue_sv_low)*6 choice
        n_reg   = (13+6);
        w_vec   = zeros(n_con,n_reg);
    end
    w_vec(1,[1,3,5,7,9,11])     = 1;
    w_vec(1,[2,4,6,8,10,12])    = -1;
    w_vec_comb  = w_vec;
    
    
    matlabbatch{1}.spm.stats.fmri_spec.dir = {[sub_fold '/results/' model_i]};
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).scans = cellstr(fimg1);
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).multi = {reg1path};
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).multi_reg = {rp1path};
    % add contrast info, same for all subjects
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.name='cue_high_low_sv';
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights= w_vec_comb(1,:);
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep='none';
    
    % save batch file for each sub for checking
    save([sub_fold '/' model_i '_' int2str(sid) '.mat'],'matlabbatch');
    % run spm
    spm_jobman('run', matlabbatch);       
    cd(exp_dir);
end
