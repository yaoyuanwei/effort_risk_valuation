clear;
clc;

%% excluded runs due to excessive head motions:
%run1: 35, 52
%run4: 57

exp_dir     = '/Volumes/projects/ERGT/EGT/univariate';
model_i     = 'egt_model4sv';

load(fullfile(exp_dir, 'nr_record.mat'));
subnum  = size(nr_record,1);
subi    = unique(nr_record(:,6));
runnum  = 5;
n_con   = 1; % contrast number: sv
% subjects with 4 runs
no_r1   = [35, 52];
no_r4   = 57;
no_rall = [35, 52, 57];

for i = 1:subnum
    sid         = subi(i);
    sub_fold    = fullfile(exp_dir, ['sub-', num2str(sid)]);
    % initialize weight vector and batch structure
    w_vec_comb  = [];
    matlabbatch = {};

    % all runs intact
    if ~ismember(sid, no_rall)
        run_n   = runnum;
        load(fullfile(exp_dir, 'spm_model', 'egt_model1.mat'));
        
        fimg1   = spm_select('ExtFPListRec', fullfile(sub_fold,'fun1'), '^swr.*\.nii$', Inf);
        fimg2   = spm_select('ExtFPListRec', fullfile(sub_fold,'fun2'), '^swr.*\.nii$', Inf);
        fimg3   = spm_select('ExtFPListRec', fullfile(sub_fold,'fun3'), '^swr.*\.nii$', Inf);
        fimg4   = spm_select('ExtFPListRec', fullfile(sub_fold,'fun4'), '^swr.*\.nii$', Inf);
        fimg5   = spm_select('ExtFPListRec', fullfile(sub_fold,'fun5'), '^swr.*\.nii$', Inf);
        
        rpfiles = fullfile(sub_fold, 'rp', '*.txt');
        rpinfo  = dir(rpfiles);
        % NOTE: the rp for run1 is always at last
        rp1path = fullfile(sub_fold,'rp', rpinfo(5).name);
        rp2path = fullfile(sub_fold,'rp', rpinfo(1).name);
        rp3path = fullfile(sub_fold,'rp', rpinfo(2).name);
        rp4path = fullfile(sub_fold,'rp', rpinfo(3).name);
        rp5path = fullfile(sub_fold,'rp', rpinfo(4).name);
        
        % regressors file path
        reg1path    = [sub_fold '/beh/' model_i '_r1.mat'];
        reg2path    = [sub_fold '/beh/' model_i '_r2.mat'];
        reg3path    = [sub_fold '/beh/' model_i '_r3.mat'];
        reg4path    = [sub_fold '/beh/' model_i '_r4.mat'];
        reg5path    = [sub_fold '/beh/' model_i '_r5.mat'];
        
        matlabbatch{1}.spm.stats.fmri_spec.dir = {[sub_fold '/results/' model_i]};
        matlabbatch{1}.spm.stats.fmri_spec.sess(1).scans = cellstr(fimg1);
        matlabbatch{1}.spm.stats.fmri_spec.sess(1).multi = {reg1path};
        matlabbatch{1}.spm.stats.fmri_spec.sess(1).multi_reg = {rp1path};
        matlabbatch{1}.spm.stats.fmri_spec.sess(2).scans = cellstr(fimg2);
        matlabbatch{1}.spm.stats.fmri_spec.sess(2).multi = {reg2path};
        matlabbatch{1}.spm.stats.fmri_spec.sess(2).multi_reg = {rp2path};
        matlabbatch{1}.spm.stats.fmri_spec.sess(3).scans = cellstr(fimg3);
        matlabbatch{1}.spm.stats.fmri_spec.sess(3).multi = {reg3path};
        matlabbatch{1}.spm.stats.fmri_spec.sess(3).multi_reg = {rp3path};
        matlabbatch{1}.spm.stats.fmri_spec.sess(4).scans = cellstr(fimg4);
        matlabbatch{1}.spm.stats.fmri_spec.sess(4).multi = {reg4path};
        matlabbatch{1}.spm.stats.fmri_spec.sess(4).multi_reg = {rp4path};
        matlabbatch{1}.spm.stats.fmri_spec.sess(5).scans = cellstr(fimg5);
        matlabbatch{1}.spm.stats.fmri_spec.sess(5).multi = {reg5path};
        matlabbatch{1}.spm.stats.fmri_spec.sess(5).multi_reg = {rp5path};
        
        for ri = 1:run_n
            nr_ind  = nr_record(i,ri);
            if (nr_ind == 1) 
                % 3 events: sv_high, sv_low, missing
                n_reg   = (3*2+6);
                w_vec   = zeros(n_con,n_reg);
            elseif (nr_ind == 0) 
                % 2 events: sv_high, sv_low
                n_reg   = (2*2+6);
                w_vec   = zeros(n_con,n_reg);
            end
            w_vec(1,1)  = 1/run_n;
            w_vec(1,3)  = -1/run_n;
            w_vec_comb  = [w_vec_comb, w_vec];
        end
    
    % sub with 4 runs
    else
        run_n   = runnum-1;       
        nr_ind2 = zeros(1,run_n);
        load(fullfile(exp_dir, 'spm_model', 'egt_model1_4r.mat'));      
        
        % no run1
        if ismember(sid, no_r1)       
            fimg1   = spm_select('ExtFPListRec', fullfile(sub_fold,'fun2'), '^swr.*\.nii$', Inf);
            fimg2   = spm_select('ExtFPListRec', fullfile(sub_fold,'fun3'), '^swr.*\.nii$', Inf);
            fimg3   = spm_select('ExtFPListRec', fullfile(sub_fold,'fun4'), '^swr.*\.nii$', Inf);
            fimg4   = spm_select('ExtFPListRec', fullfile(sub_fold,'fun5'), '^swr.*\.nii$', Inf);

            rpfiles = fullfile(sub_fold, 'rp', '*.txt');
            rpinfo  = dir(rpfiles);
            rp1path = fullfile(sub_fold,'rp', rpinfo(1).name);
            rp2path = fullfile(sub_fold,'rp', rpinfo(2).name);
            rp3path = fullfile(sub_fold,'rp', rpinfo(3).name);
            rp4path = fullfile(sub_fold,'rp', rpinfo(4).name);

            % regressors file path
            reg1path    = [sub_fold '/beh/' model_i '_r2.mat'];
            reg2path    = [sub_fold '/beh/' model_i '_r3.mat'];
            reg3path    = [sub_fold '/beh/' model_i '_r4.mat'];
            reg4path    = [sub_fold '/beh/' model_i '_r5.mat'];
            % missing trial index
            nr_ind2(1,:)    =  nr_record(i,(2:5));            
        
    
        % no run4
        elseif ismember(sid, no_r4)
            fimg1   = spm_select('ExtFPListRec', fullfile(sub_fold,'fun1'), '^swr.*\.nii$', Inf);
            fimg2   = spm_select('ExtFPListRec', fullfile(sub_fold,'fun2'), '^swr.*\.nii$', Inf);
            fimg3   = spm_select('ExtFPListRec', fullfile(sub_fold,'fun3'), '^swr.*\.nii$', Inf);
            fimg4   = spm_select('ExtFPListRec', fullfile(sub_fold,'fun5'), '^swr.*\.nii$', Inf);

            rpfiles = fullfile(sub_fold,'rp', '*.txt');
            rpinfo  = dir(rpfiles);
            % NOTE: the rp for run1 is always at last
            rp1path = fullfile(sub_fold,'rp', rpinfo(5).name);
            rp2path = fullfile(sub_fold,'rp', rpinfo(1).name);
            rp3path = fullfile(sub_fold,'rp', rpinfo(2).name);
            rp4path = fullfile(sub_fold,'rp', rpinfo(4).name);

            % regressors file path
            reg1path    = [sub_fold '/beh/' model_i '_r1.mat'];
            reg2path    = [sub_fold '/beh/' model_i '_r2.mat'];
            reg3path    = [sub_fold '/beh/' model_i '_r3.mat'];
            reg4path    = [sub_fold '/beh/' model_i '_r5.mat'];
            % missing trial index
            nr_ind2(1,:)    =  nr_record(i,[1,2,3,5]);
        end
        
        matlabbatch{1}.spm.stats.fmri_spec.dir = {[sub_fold '/results/' model_i]};
        matlabbatch{1}.spm.stats.fmri_spec.sess(1).scans = cellstr(fimg1);
        matlabbatch{1}.spm.stats.fmri_spec.sess(1).multi = {reg1path};
        matlabbatch{1}.spm.stats.fmri_spec.sess(1).multi_reg = {rp1path};
        matlabbatch{1}.spm.stats.fmri_spec.sess(2).scans = cellstr(fimg2);
        matlabbatch{1}.spm.stats.fmri_spec.sess(2).multi = {reg2path};
        matlabbatch{1}.spm.stats.fmri_spec.sess(2).multi_reg = {rp2path};
        matlabbatch{1}.spm.stats.fmri_spec.sess(3).scans = cellstr(fimg3);
        matlabbatch{1}.spm.stats.fmri_spec.sess(3).multi = {reg3path};
        matlabbatch{1}.spm.stats.fmri_spec.sess(3).multi_reg = {rp3path};
        matlabbatch{1}.spm.stats.fmri_spec.sess(4).scans = cellstr(fimg4);
        matlabbatch{1}.spm.stats.fmri_spec.sess(4).multi = {reg4path};
        matlabbatch{1}.spm.stats.fmri_spec.sess(4).multi_reg = {rp4path};
        
        % weight vector
        for ri = 1:run_n
            nr_ind  = nr_ind2(1,ri);
            if (nr_ind == 1) 
                % 3 events: sv_high, sv_low, missing
                n_reg   = (3*2+6);
                w_vec   = zeros(n_con,n_reg);
            elseif (nr_ind == 0) 
                % 2 events: sv_high, sv_low
                n_reg   = (2*2+6);
                w_vec   = zeros(n_con,n_reg);
            end
            w_vec(1,1)  = 1/run_n;
            w_vec(1,3)  = -1/run_n;
            w_vec_comb  = [w_vec_comb, w_vec];
        end
        
    end % end subid judgment loop
    
    % add contrast info, same for all subjects
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.name='high_low_sv';
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights= w_vec_comb(1,:);
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep='none';
    
    % save batch file for each sub for checking
    save([sub_fold '/' model_i '_sub-' int2str(sid) '.mat'],'matlabbatch');
    % run spm
    spm_jobman('run', matlabbatch);       
    cd(exp_dir);
end
