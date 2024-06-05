<p align="center">
    <img src="images/Klar Parat.jpg" alt="Logo" width="120" height="120">
  </p>

<h3 align="center">From Panic to Plan: Agent-Based Evacuation Simulations</h3>

<p align="center">
  Emilie Munch Andreasen (<strong><a href="https://github.com/EmilieAndreasen">@EmilieAndreasen</a></strong>),
  Katrine Munkholm (<strong><a href="https://github.com/katrinemunkholm">@KatrineMunkholm</a></strong>), and
    Sabrina Zaki Hansen (<strong><a href="https://github.com/sabszh">@Sabszh</a></strong>)
</p>

<p align="center">
  Spatial Analytics | Cultural Data Science <br>
  Aarhus University (June 2024) 
</p>

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>

<hr>

This repository contains all the necessary components to run an Agent-Based Model (ABM) for evacuation scenarios in Aarhus and plot traffic . Key elements include:  
- NetLogo Code/Model: The core ABM evacuation model developed in NetLogo.  
- Data (Shapefiles): Geographic data used within the NetLogo model, processed and formatted as shapefiles.  
- Python Preprocessing Scripts: Scripts for preprocessing raw data to generate the required shapefiles for the NetLogo model.  
- Traffic Analysis and Plotting Scripts: Python scripts for analyzing and plotting traffic data in Aarhus, providing insights into traffic patterns and evacuation dynamics.  


To reproduce the code, please refer to the section [*Technical Pipeline*](https://github.com/MinaAlmasi/aarhus-rentmapper/tree/main#technical-pipeline). For any further information regarding the project or its reproducibility, contact the authors (see [*Authors*](https://github.com/MinaAlmasi/aarhus-rentmapper#authors)).

<br>

## Project Structure 
The repository is structured as such:
| <div style="width:120px"></div>| Description |
|---------|:-----------|
| ```app```  | Folder with all relevant scripts to build and deploy the ```Aarhus RentMapper``` tool (see [app/README.md](https://github.com/MinaAlmasi/aarhus-rentmapper/blob/main/app/README.md))          |
| ```data``` | Folder with scraped rental data, the geodata and the merged datafile ```complete_data.csv``` with rental data containing geospatial information (see [data/README.md](https://github.com/MinaAlmasi/aarhus-rentmapper/blob/main/data/README.md)).      |
| ```results``` | Folder with aggregated results. |
| ```plots```| Folder with plots used in the paper.
| ```src```  | Folder with scripts used for cleaning scraped data, combining rental data with geodata, performing data analysis and plotting (see [src/README.md](https://github.com/MinaAlmasi/aarhus-rentmapper/blob/main/src/README.md)).       |
| ```run.sh```    | Run entire analysis pipeline (except for cartograms)       |
| ```setup.sh```  | Run to install create Python virtual environment ```env``` and install necessary packages within it |

<br>

## Technical Pipeline
The code was mainly developed in ```Python``` (3.9.13) on a Macbook Pro ‘13 (2020, 2 GHz Intel i5, 16GB of ram). Whether it will work on Windows cannot be guaranteed. Python's [venv](https://docs.python.org/3/library/venv.html) needs to be installed for the setup to work.

### Setup 
Firstly, this repository must be cloned to your device as such:
```
git clone https://github.com/MinaAlmasi/aarhus-rentmapper.git
```

To be able to reproduce the code, type the following in the terminal: 
```
bash setup.sh
```
The script creates a new virtual environment (```env```) and installs the necessary packages within it.


### Running the Analysis Pipeline
To run the entire analysis pipeline, which laid the foundation for deploying the tool, type in your ```bash/zsh``` terminal while being located in the main repository folder (```cd aarhus-rentmapper```):
```
bash run.sh
```

#### Running the R-script
As no Python packages supported plotting cartograms easily, this plot was created in ```R``` (4.2.3). To run this seperate analysis, ensure that you have [R](https://cran.r-project.org/src/base/R-4/) and [RScript](https://www.rdocumentation.org/packages/utils/versions/3.6.2/topics/Rscript) installed. Type in your terminal while being located in the main repository folder (```cd aarhus-rentmapper```):
```
RScript src/plot_cartogram.R
```

### Deploying Aarhus RentMapper Locally 
For testing and development purposes, the ```Aarhus RentMapper``` tool can be deployed locally by typing:
```
streamlit run app/app.py
```
Note that you need:
1. To activate the virtual environment first (```source env/bin/activate``` in the terminal)
2. To ensure that you are located in the main folder (```cd aarhus-rentmapper```)

<br>

## Authors 
This code repository was a joint effort by Anton Drasbæk Sciønning ([@drasbaek](https://github.com/drasbaek)) and Mina Almasi ([@MinaAlmasi](https://github.com/MinaAlmasi)). 

### Contact us
For any questions regarding the reproducibility or project in general, you can contact us:
<ul style="list-style-type: none;">
  <li><a href="mailto:drasbaek@post.au.dk">drasbaek@post.au.dk</a>
(Anton)</li>
    <li><a href="mailto: mina.almasi@post.au.dk"> mina.almasi@post.au.dk</a>
(Mina)</li>
</ul>
