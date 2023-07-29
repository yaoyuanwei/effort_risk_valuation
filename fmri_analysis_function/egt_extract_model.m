function [onsets, names, durations, nr_ind] = egt_extract_model(task_name, anal_fold, sub_data, run_n, sub_sv, si)
% EGT_EXTRACT_MODEL: Extract events and timing information for effort-based gambling
% July 23, 2023, by Yuanwei Yao
% 
%
% Input:
%   task_name:  Name of the task for analysis, e.g., 'ddt'
%   anal_fold:  Name of the main fMRI analysis folder
%   sub_fold:   Name of the subject folder
%   run_n:      Number of runs
%   sub_sv:     Subjective values for each subject
%   si:         Subject numeric id (e.g., 20)
%
% Output:
%   onsets:     Onset for each event in the model
%   names:      Name for each event in the model
%   duractions: Duration for each event in the model
%   nr_ind:     No-response matrix, the first 5 columes are no-response index for each run, and the
%               last is the subject id (e.g., nr_ind = [1,0,1,0,1,20])

    % Mat file name
    matfile     = [task_name, '_model_sv'];

    % Add sub_id to the no-response recording matrix
    nr_ind      = zeros(1,run_n+1);

    % Last column for sub-id
    nr_ind(1,run_n+1) = si;

    % Index for no-response trials
    nan_ind     = (sub_data.response == 0)|isnan(sub_data.response);
    
    % Divide subjective values based on the median
    sv_md       = median(sub_sv);
    sv_high     = (sub_sv >= sv_md);
    sv_low      = (sub_sv < sv_md);
    
    % Cue onset
    cue_ons     = sub_data.StrTime;

    % Trial duration
    trial_dur   = sub_data.dur;

    % Trial RT
    trial_rt    = sub_data.RT;
    
    % Generate events and timing info for each run
    for ri = 1:run_n
            
        % Trial index within a specific run    
        trial_ri    = (sub_data.run == ri);

        % Any trials without response in this run?
        nan_ri      = trial_ri & nan_ind;

        % Valid trial index
        valid_ri    = trial_ri & ~(nan_ind);

        % High and low sv trials index for each run
        sv_hri      = sv_high & valid_ri;
        sv_lri      = sv_low & valid_ri;
        
        % Initialize names, onsets, durations for each run
        names       = {};
        onsets      = {};
        durations   = {};
        
        % Cue onset
        cue_ons_ri  = cue_ons(valid_ri);

        % Onset for high and low sv cues
        svh_ons_ri  = cue_ons(sv_hri);
        svl_ons_ri  = cue_ons(sv_lri);
            
        %% Build spm.mat
        % No-response trials (if any) were included as a regressor of no interest
        if max(nan_ri) > 0

            % Onset and durection of the no-response trials
            nr_ons_ri   = cue_ons(nan_ri);
            nr_dur_ri   = trial_dur(nan_ri);

            % High sv, low sv, and no-response trials were included in the model
            onsets      = {svh_ons_ri, svl_ons_ri, nr_ons_ri};
            names       = {'sv_high', 'sv_low', 'missing'};
            durations   = {0 0 nr_dur_ri};
            nr_ind(1,ri)  = 1;
        
        % only 2 regressors if all trials were selected
        else

            % High and low sv were included as two regressors of interest
            onsets      = {svh_ons_ri, svl_ons_ri};
            names       = {'sv_high', 'sv_low'};
            durations   = {0 0};
        end
        
        % Specify subject id
        sub_id      = sprintf('sub-%d', si);

        % Create a heb folder to store the generated mat file
        aim_fold    = fullfile(anal_fold, sub_id, 'beh');
        if ~isfolder(aim_fold)
            mkdir(aim_fold);
        end
        
        % Save names, onsets, durations as a mat file for checking
        save([aim_fold '/' matfile '_r' num2str(ri) '.mat'], 'names', 'onsets', 'durations');
    end
end