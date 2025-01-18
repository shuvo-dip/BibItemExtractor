%%%%------------------------------------------------------------------------
%  Author :  Subhadip Biswas
%            Research Associate
%            Department of Chemistry
%            Iowa State University
%            Email: subhadip@iastate.edu
%%%%------------------------------------------------------------------------

function processCitationsAndGenerateBibitems(inputTextFile, bibFile)
    % Input and output files
    outputBibItems = 'bibitems.txt';
    missingInfoFile = 'missing_info.txt';
    
    % Read the input text file
    fid = fopen(inputTextFile, 'r');
    if fid == -1
        error('Cannot open the input text file');
    end
    textLines = textscan(fid, '%s', 'Delimiter', '\n', 'Whitespace', '');
    fclose(fid);
    textLines = textLines{1};
    
    % Regular expressions
    citePattern = '\\cite\s*{([^}]*)}'; % Match \cite{} and extract contents
    commentPattern = '^\s*%[^\\%]';    % Match lines starting with % but not containing \%
    
    % Initialize storage for unique bibitem IDs
    uniqueBibIDs = {};
    
    % Process each line
    for i = 1:length(textLines)
        line = strtrim(textLines{i});
        
        % Skip comment lines starting with % (not \%)
        if ~isempty(regexp(line, commentPattern, 'once'))
            continue;
        end
        
        % Extract \cite{} contents
        citations = regexp(line, citePattern, 'tokens');
        for j = 1:length(citations)
            ids = strsplit(citations{j}{1}, ','); % Split IDs by comma
            ids = strtrim(ids); % Remove leading/trailing spaces
            for k = 1:length(ids)
                if ~ismember(ids{k}, uniqueBibIDs)
                    uniqueBibIDs{end+1} = ids{k}; %#ok<AGROW> Add to list
                end
            end
        end
    end
    
    % Call generateBibitems with uniqueBibIDs
    generateBibitemsFromList(uniqueBibIDs, bibFile, outputBibItems, missingInfoFile);
    
    fprintf('Bibitems written to %s\n', outputBibItems);
    fprintf('Missing info list written to %s\n', missingInfoFile);
end

function generateBibitemsFromList(uniqueBibIDs, bibFile, outputBibItems, missingInfoFile)
    % Open the .bib file
    fid = fopen(bibFile, 'r');
    if fid == -1
        error('Cannot open the .bib file');
    end
    
    % Read all lines from the .bib file
    bibData = textscan(fid, '%s', 'Delimiter', '\n', 'Whitespace', '');
    fclose(fid);
    bibLines = bibData{1};
    
    % Prepare output files
    bibItems = fopen(outputBibItems, 'w');
    missingInfo = fopen(missingInfoFile, 'w');
    
    % Regular expressions
    entryStart = '^@\w+\{([^,]+),'; % Match entry start and extract ID
    fieldPattern = '^\s*(\w+)\s*=\s*[{"'']?(.*?)[}"'']?,?$'; % Match fields (quoted/unquoted)
    
    % Initialize a map for bib entries
    entries = containers.Map();
    currentEntry = struct();
    currentID = '';
    
    % Parse the .bib file
    for i = 1:length(bibLines)
        line = strtrim(bibLines{i});
        
        % Detect entry start
        match = regexp(line, entryStart, 'tokens', 'once');
        if ~isempty(match)
            % Save the previous entry
            if ~isempty(currentID) && ~isempty(fieldnames(currentEntry))
                entries(currentID) = currentEntry;
            end
            
            % Start new entry
            currentID = match{1};
            currentEntry = struct('id', currentID);
        elseif ~isempty(line)
            % Match fields
            tokens = regexp(line, fieldPattern, 'tokens', 'once');
            if ~isempty(tokens)
                fieldName = lower(tokens{1});
                currentEntry.(fieldName) = tokens{2};
            end
        end
    end
    % Save the last entry
    if ~isempty(currentID) && ~isempty(fieldnames(currentEntry))
        entries(currentID) = currentEntry;
    end
    
    % Generate bibitems for uniqueBibIDs
    for i = 1:length(uniqueBibIDs)
        bibID = uniqueBibIDs{i};
        if isKey(entries, bibID)
            writeBibitem(bibItems, missingInfo, entries(bibID));
        else
            fprintf(missingInfo, 'BibItem ID: %s - Not found in .bib file\n', bibID);
        end
    end
    
    % Close output files
    fclose(bibItems);
    fclose(missingInfo);
end

function writeBibitem(bibItems, missingInfo, entry)
    % Required fields
    requiredFields = {'title', 'author', 'journal', 'volume', 'number', 'pages', 'year', 'doi'};
    missingFields = {};

    % Extract fields
    authors = getField(entry, 'author', '');
    title = getField(entry, 'title', '');
    journal = getField(entry, 'journal', '');
    volume = getField(entry, 'volume', '');
    number = getField(entry, 'number', '');
    pages = getField(entry, 'pages', '');
    year = getField(entry, 'year', '');
    doi = getField(entry, 'doi', '');
    
    % Check for missing fields
    for i = 1:length(requiredFields)
        field = requiredFields{i};
        if ~isfield(entry, field) || isempty(entry.(field))
            missingFields{end+1} = field; %#ok<AGROW>
        end
    end
    
    % Log missing fields
    if ~isempty(missingFields)
        fprintf(missingInfo, 'BibItem ID: %s - Missing Fields: %s\n', ...
            entry.id, strjoin(missingFields, ', '));
    end
    
    % Format details
    details = '';
    if ~isempty(volume)
        details = [details, sprintf('\\textbf{%s', volume)];
        if ~isempty(number)
            details = [details, sprintf('(%s)', number)];
        end
        details = [details, '}'];
    end
    if ~isempty(pages)
        details = [details, sprintf(', %s', pages)];
    end
    if ~isempty(year)
        details = [details, sprintf('(%s)', year)];
    end
    
    % Generate bibitem
    if ~isempty(journal)
        bibitem = sprintf('\\bibitem{%s} %s, %s, \\textsl{%s}, \\href{%s}{%s}.\n', ...
            entry.id, authors, title, journal, doi, details);
    else
        bibitem = sprintf('\\bibitem{%s} %s, %s, \\href{%s}{%s}.\n', ...
            entry.id, authors, title, doi, details);
    end
    
    % Write bibitem to file
    fprintf(bibItems, '%s', bibitem);
end

function value = getField(entry, field, defaultValue)
    % Fetch field value or use default
    if isfield(entry, field)
        value = entry.(field);
    else
        value = defaultValue;
    end
end
