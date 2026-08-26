function results = Massive_D2M(experimentname)

% Creates two matrices with Reaction Times and Errors given a Data2MeansAuto function 

% name_rt = 'Test_000x_RT';
% name_err = 'Test_000x_Err';

% Write the name of the experiment:
% experimentname = 'SelfPriorExp_';
experimentnamesize = size(experimentname,2);

list_of_files = ls;
m = size(list_of_files,1);
counter = 0;
participantslist = 0;

for i=1:m
    if strfind(list_of_files(i,:),experimentname) == 1
        if list_of_files(i,experimentnamesize+5:experimentnamesize+8) == '.dat'
            counter = counter + 1;
            participantslist(counter) = str2num(list_of_files(i,experimentnamesize+1:experimentnamesize+4));
        end
    end
end


n = size(participantslist,2);

% BEGIN CALCULATING THE MEANS AND ERROR RATES
        
output_rt = zeros(n,9);
output_err = zeros(n,9);
output_exclude = zeros(n,9);


for i=1:n
    filename = [experimentname, num2str(participantslist(i)),'.dat'];
    temp = importdata(filename);
    data = temp.data;
    textdata=temp.textdata;
    ans = Data2MeansAuto(data,textdata);
    output_rt(i,:) = ans(1,:);
    output_err(i,:) = ans(2,:);
    output_exclude(i,:) = ans(3,:);
end
    
results.rt = output_rt;
results.errorrate = output_err;
results.exclusionrate = output_exclude;
results.person = participantslist';

results;