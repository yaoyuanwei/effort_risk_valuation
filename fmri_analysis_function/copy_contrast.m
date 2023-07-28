function [source_file, dest_file] = copy_contrast(task_name, anal_fold, sub_fold, cons_copy, si)% Copy contrast images: July 23, 2023, by Yuanwei Yao%% This function is used to copy contrast images from multiple subjects to a single folder for % subsequent analyses%% Input:%   task_name:  Name of the task for analysis, e.g., 'ddt'%   anal_fold:  Name of the main fMRI analysis folder%   sub_fold:   Name of the subject folder%   cons_copy:  Name of the contrast images(s) that we want to copy%   si:         Subject numeric id (e.g., 20)%% Output:%   source_file:    Original contrast image(s) that we want to copy%   dest_file:      Renamed contrast image(s) that we want to copy to a specific folder    % Model name    model_i     = [task_name, '_model_sv'];        % Folder that contains contrast image(s)    cons_dir        = fullfile(sub_fold, result_dir, model_i);            % Specify the original and modified names of the image(s)    for cons = 1:length(cons_copy)                % Use spm_select to get the full path of the contrast image        source_file     = spm_select('FPList', sub_path, cons_copy{cons});        % Use fileparts to get the name and and file type (e.g., nii) of the smoothed file        [~, name, ext]  = fileparts(cons_copy{cons});        % Specify the modified name of the image: e.g., con_0001_Sub102.nii        dest_file_name  = sprintf('%s_%s%s',name, ['Sub', int2str(si)], ext);        % Name for each contrast        con_name        = sprintf('con_000%d',cons);        % Create a contrast folder for each contrast image        dest_dir        = fullfile(anal_fold, 'stats', model_i, con_name);        if ~exist(dest_dir,'dir')            mkdir(dest_dir);        end        % Full path of the renamed image        dest_file       = fullfile(dest_dir, dest_file_name);        % Copy the original contrast to the corresponding folder and change the contrast name        copyfile(source_file, dest_file);    endend