% Function to run multivariate decoding and then smooth the decoding maps
% Modified based on the TDT template
% TDT toolbox is required
% Author: Yuanwei Yao
% Date: July 23, 2023

function [source_file, dest_file] = run_decoding(task_name, anal_fold, sub_fold, labelname1, labelname2, si)
    
    %% Decoding analysis
    clear cfg
    clear results

    % model name
    model_i     = [task_name, '_model_sv'];

	% Set defaults
	cfg = decoding_defaults;

	% Set the analysis that should be performed (default is 'searchlight')
	cfg.analysis = 'searchlight'; % standard alternatives: 'wholebrain', 'ROI' (pass ROIs in cfg.files.mask, see below)
	cfg.searchlight.radius = 3; % use searchlight of radius 3 (by default in voxels), see more details below

	% Set the output directory where data will be saved, e.g. 'c:\exp\results\buttonpress'
	output_dir      = fullfile(sub_fold, 'results', [model_i '_decode']);
    cfg.results.dir = output_dir;
    if ~isfolder(output_dir)
        mkdir(output_dir);
    end

	% Set the filepath where your SPM.mat and all related betas are, e.g. 'c:\exp\glm\model_button'
	beta_loc = fullfile(sub_fold, 'results', model_i);

	% Set the filename of your brain mask (or your ROI masks as cell matrix) 
	cfg.files.mask = fullfile(beta_loc, 'mask.nii');

	labelvalue1 = 1; % value for labelname1
	labelvalue2 = -1; % value for labelname2

	% Enable scaling min0max1 (otherwise libsvm can get VERY slow)
	% if you dont need model parameters, and if you use libsvm, use:
	cfg.scale.method = 'min0max1';
	cfg.scale.estimation = 'all'; % scaling across all data is equivalent to no scaling (i.e. will yield the same results), it only changes the data range which allows libsvm to compute faster



	%% Decide whether you want to see the searchlight/ROI/... during decoding
    cfg.plot_selected_voxels = 0;
    cfg.plot_design = 0;

	% The following function extracts all beta names and corresponding run
	% numbers from the SPM.mat
	regressor_names = design_from_spm(beta_loc);

	% Extract all information for the cfg.files structure (labels will be [1 -1] if not changed above)
	cfg = decoding_describe_data(cfg,{labelname1 labelname2},[labelvalue1 labelvalue2],regressor_names,beta_loc);
    cfg.files.chunk = repmat((1:6)',2,1);

	% This creates the leave-one-run-out cross validation design:
	cfg.design = make_design_cv(cfg); 

	% Run decoding
	results = decoding(cfg);

	%% Smoothing: 6mm
	matlabbatch = {};
	load([anal_fold, '/spm_model/spm_smooth6.mat']);
	% select decoding maps
	decode_maps  = {'res_accuracy_minus_chance.nii'};
	us_img   = spm_select('FPListRec', output_dir, decode_maps);
	matlabbatch{1, 1}.spm.spatial.smooth.data = cellstr(us_img);
	spm_jobman('run', matlabbatch);

	%% Copy decoding maps
	dest_dir   	= fullfile(anal_fold, 'stats', [model_i, '_decode'], 'smoothed');
	if ~exist(dest_dir,'dir')
	    mkdir(dest_dir);
	end

	sm_maps  		= {'sres_accuracy_minus_chance.nii'};
	source_file     = spm_select('FPList', output_dir, sm_maps{1});
    [~,name,ext]    = fileparts(sm_maps{1});
    dest_file_name  = sprintf('%s_%s%s', name, ['Sub', int2str(si)], ext); % sres_AUC_minus_chance_Sub19.nii
    dest_file       = fullfile(dest_dir, dest_file_name);


end