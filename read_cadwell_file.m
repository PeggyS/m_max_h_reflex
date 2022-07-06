function info = read_cadwell_file(filename)
%READ_CADWELL_FILE - read data in from a cadwell ascii/csv file
%
% input
%	filename - name of file to read
%
% output
%	data structure with the fields:
%		filename
%		subject 
%		session - 
%		side - left or right
%		muscle - ta or gastroc
%		date - test date
%		samp_freq - sampling freq of data
%		n_samples - number of data points in a trace (it's always 640)
%		stim_ampl - vector of stimulus amplitudes for each trace
%		stim_pw - vector of stimulus pulse width for each trace
%		data - matrix of data; 1 column for each stimulus trace

% Author: Peggy Skelly
% 2019-11-05: create 


if ~exist(filename, 'file')
	error('%s does not exist', filename);
end

% open the file
fid = fopen(filename, 'r');
info.filename = filename;
txt = 'init';

while ischar(txt) % txt will change to -1 when end of file is reached
	% read in 1 line
	txt = fgetl(fid);
	if ischar(txt)
		split_str = split(txt, ',');
		% look for keywords: Test Item, Patient Name, Test Date, Trace Label,
		% ms/Sample, Trace Data (µv)
		switch split_str{1}
			case 'Test Item'
				[info.side, info.muscle, info.h_or_m] = parse_item(split_str{2});
			case 'Patient Name'
				[info.subject, info.session] = parse_name(split_str{2});
			case 'Test Date'
				info.date = split_str{2};
			case 'Trace Label'
				[info.stim_ampl, info.stim_pw] = parse_stim(split_str(2:end));
			case 'ms/Sample'
				info.samp_freq = 1 / (str2double(split_str{2})/1000);
			case 'Samples'
				info.n_samples = str2double(split_str{2});
			case 'Trace Data (µV)'
				info.data = read_data(split_str(2:end), info.n_samples, fid);
		end
	end
end
	
% close the file
fclose(fid);
return

% -----------------------------------------------
function [side, muscle, h_or_m] = parse_item(txt)
txt = lower(txt);
side = '';

if contains(txt, 'left')
	side = 'left';
elseif contains(txt, 'right')
	side = 'right';
end

if contains(txt, 'ta')
	muscle = 'ta';
	h_or_m = 'm';
elseif contains(txt, 'gastroc')
	muscle = 'gastroc';
	h_or_m = 'm';
elseif contains(txt, 'increasing')
	muscle = 'flexors';
	h_or_m = 'm';
elseif contains(txt, 'decreasing')
	muscle = 'flexors';
	h_or_m = 'h';
else
	muscle = 'extensors';
	h_or_m = 'm';
end

return

% -------------------------------------------------
function [subject, session] = parse_name(txt)
subject = '';
session = '';

txt = lower(txt);
words = split(txt);

% look for session in 1st word
tmp = regexp(words{1}, '\w*', 'match');
if ~isempty(tmp)
	session = tmp{1};
end

% and subject in 2nd word
tmp = regexp(words{2}, '\w*', 'match');
if ~isempty(tmp)
	subject = tmp{1};
end
return

% -------------------------------------------------
function [stim_ampl, stim_pw] = parse_stim(str_array)

if contains(str_array, 'µs')
	str_pat = '.*: (?<ampl>\d.*) mA : (?<pw>\d.*) µs';
else
	str_pat = '.*: (?<ampl>\d.*) mA';
end
info_struct = cellfun(@(x)regexp(x, str_pat, 'names'), str_array, 'UniformOutput', false);
if isempty(info_struct{1})
	% trace labels may be reversed
	str_pat = '.*: (?<pw>\d.*) µs : (?<ampl>\d.*) mA';
	info_struct = cellfun(@(x)regexp(x, str_pat, 'names'), str_array, 'UniformOutput', false);
end

if isempty(info_struct{1}) % still no stim info from info_struct
	error('Not able to parse trace label to get stim ampl & pw from the data trace label')
end
	
ampl_cell = cellfun(@(x)str2double(x.ampl), info_struct, 'UniformOutput', false);
stim_ampl = cell2mat(ampl_cell)';

if isfield(info_struct{1}, 'pw')
	% replace '1 k' with '1000'
	pw_cell = cellfun(@(x)strrep(x.pw, '1 k', '1000'), info_struct, 'Uniformoutput', false);
% 	pw_cell = cellfun(@(x)str2double(x.pw), info_struct, 'UniformOutput', false);
% 	stim_pw = cell2mat(pw_cell)';
	stim_pw = str2double(pw_cell)';
else
	stim_pw = [];
end

return

% -------------------------------------------------
function data = read_data(str_array, n_samples, fid)

data = nan(n_samples, length(str_array));
data(1,:) = arrayfun(@str2double, str_array)';

% continue reading the data in the file
for row_cnt = 2:n_samples
	% read in next line
	txt = fgetl(fid);
	split_str = split(txt, ',');
	tmp = arrayfun(@str2double, split_str)';
	data(row_cnt, :) = tmp(2:end);
end
return