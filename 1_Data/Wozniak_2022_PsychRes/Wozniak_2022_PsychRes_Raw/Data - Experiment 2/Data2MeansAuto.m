function [outcome]=Data2Means(data,textdata)

% Extracts means and error rates from the SelfPriorExp results
%  fprintf(datafilepointer,'%i %i %s %i %s %i %s %i %i %i\n', ...
%   textdata(1) > subNo, ...
%   textdata(2) > hand, ...
%   textdata(3) > phaselabel, ...
%   textdata(4) > trial, ...
%   textdata(5) > resp, ...                 >>> keypress "z" or "m"
%   textdata(6) > objnumber(trial), ...     >>> Type of pairing: {1,2,3} =
%          congruent; {4,5,6,7,8,9} = incongruent
%   textdata(7) > char(objname(trial)), ... >>> np.: 'shape1.jpg'
%   textdata(8) > permutation               >>> Permutation: {1,2,3,4,5,6}
%   textdata(9) > version                   >>> 1 = You, 2 = I
%   textdata(10,11,12) > labels{i}          >>> Labels for: Triangle, Square, Circle
%   textdata(13) > friend                   >>> name of a friend
%   data(1) > objtype(trial), ...           >>> congruent (1) or incongruent (2)
%   data(2) > ac, ...                       >>> accuracy
%   data(3) > rt);                          >>> Reaction Time

% Set to 1 if you want to use MAD procedure to exclude slowest reaction
% times. If set to 0 then trials with RTs lower than "highestRT", as defined 
% below, will be excluded 
MAD = 1;

% Set highest acceptable RT
highestRT = 1200;
lowestRT = 200;

if MAD == 1
    % Prepare the MAD highestRT
    std_RT = std(data(data(:,2)==1,3));
    mean_RT = mean(data(data(:,2)==1,3));
    median_RT = median(data(data(:,2)==1,3));
    mad_RT = mad(data(data(:,2)==1,3),1);
    % Calculate the highestRT: highestRT = 1500;
    highestRT = median_RT + 3 * mad_RT
end

n = length(data);
rt = zeros(1,9);
counter = zeros(1,9);
excludedtrials = zeros(1,9);
errors = zeros(1,9);
N=zeros(1,9);

permutation = eval(textdata{1,8});


% THE COUNTER

for i=1:n
    a=size(textdata{i,6});
    if a(1,2)==1
    for j=1:9
        if eval(textdata{i,6})==j
            N(1,j) = N(1,j) + 1;
            if (data(i,2)==1 && data(i,3)<highestRT && data(i,3)>lowestRT)
                counter(1,j) = counter(1,j) + 1;
                rt(1,j) = rt(1,j) + data(i,3);
            else
                excludedtrials(1,j) = excludedtrials(1,j) + 1;
            end
            if data(i,2)==0
                errors(1,j) = errors(1,j) + 1;
            end
        end
    end
    end
end
    

% ORDERING ACCORDING TO PERMUTATIONS

switch permutation
    case 1
        sequence=[1,2,3,4,5,6,7,8,9;];
    case 2
        sequence=[1,3,2,7,9,8,4,6,5;];
    case 3
        sequence=[2,1,3,8,7,9,5,4,6;];
    case 4
        sequence=[2,3,1,5,6,4,8,9,7;];
    case 5
        sequence=[3,1,2,6,4,5,9,7,8;];
    case 6
        sequence=[3,2,1,9,5,7,6,5,4;];
    otherwise
        error('Wrong number for permutation');
end


errorcount = errors./N;
excludedtrials = excludedtrials./N;
outcome = [[rt./counter]', errorcount', excludedtrials']';

outcometemp=outcome;
for i=1:9
    outcometemp(:,sequence(i))= outcome(:,i);
end

% OUTCOME

outcome = outcometemp;
