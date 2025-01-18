# BibItemExtractor

A MATLAB script to process LaTeX documents, extract unique citation keys from `\cite{}` entries, and generate corresponding `bibitems` from a `.bib` file.

## Features
- Extract unique citation IDs from LaTeX text containing `\cite{}`.
- Identify and log missing fields like `volume`, `number`, or `doi`.
- Generate formatted `bibitems` for citations in `bibitems.txt`.
- Log unresolved or missing bibitem data in `missing_info.txt`.

## Requirements
- MATLAB R2018b or later.
- Input files:
  - A `.bib` file with BibTeX entries.
  - A text file containing LaTeX citations.

## Usage
1. Place your `.bib` file and text file in the same directory as the script.
2. Run the MATLAB script:
   ```matlab
   processCitationsAndGenerateBibitems('input.txt', 'references.bib');
