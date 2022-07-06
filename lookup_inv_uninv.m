function inv_or_uninv = lookup_inv_uninv(subject, side)
inv_side = find_subject_involved_side(subject);
if strcmp(side, inv_side)
	inv_or_uninv = 'inv';
else
	inv_or_uninv = 'uninv';
end
return
