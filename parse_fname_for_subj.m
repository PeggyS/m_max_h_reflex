function subject = parse_fname_for_subj(fname)
tmp = regexp(fname, '(?<subject>s\d{4}\w{4})', 'names');
if ~isempty(tmp)
	if length(tmp) > 1
		error('found more than 1 possible subject in the path/filename')
	end
	subject = tmp.subject;
else
	subject = input('Specify subject to look up L-R -> inv-uninv [s2799tdvg]: ','s');
	if isempty(subject)
		subject = 's2799tdvg';
	end
	tmp = regexp(subject, '(?<subject>s\d{4}\w{4})', 'names');
	if isempty(tmp)
		error('invalid subject entered')
	end
end
return
