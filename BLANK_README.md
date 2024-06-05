<p align="center">
    <img src="images/Klar Parat.jpg" alt="Logo" width="120" height="120">
  </p>

<h3 align="center">From Panic to Plan: Agent-Based Evacuation Simulations</h3>

<p align="center">
  Emilie Munch Andreasen (<strong><a href="https://github.com/EmilieAndreasen">@EmilieAndreasen</a></strong>),
  Katrine Munkholm Hygebjerg-Hansen (<strong><a href="https://github.com/katrinemunkholm">@KatrineMunkholm</a></strong>), and
    Sabrina Schroll Zaki Hansen (<strong><a href="https://github.com/sabszh">@Sabszh</a></strong>)
</p>

<p align="center">
  Spatial Analytics | Cultural Data Science <br>
  Aarhus University (June 2024) 
</p>

<hr>

This repository contains all the necessary components to run the Agent-Based Model (ABM) for evacuation in Aarhus along with  visualising traffic and movement data in Aarhus, the results of which are used to inform the [mock-up](https://www.figma.com/design/ZzUPYJiE9yhHM93OycdNY5/Spatial-Analytics%3A-Exam-application-design?node-id=0-1) of the “klar | parat” app. Key elements in the repo include:  
- **NetLogo Code/Model:** The core ABM evacuation model developed in NetLogo 6.4.0.  
- **Data (Shapefiles, CSVs):** Geographic data used within the NetLogo model, processed and formatted as shapefiles, and CSV files with traffic data.  
- **Python Preprocessing Scripts:** Scripts for preprocessing the initial raw data to generate the required shapefiles for the NetLogo model.  
- **Traffic Analysis and Plotting Scripts:** Python scripts for plotting traffic and evacuation shelter data in Aarhus, providing visual insights into traffic patterns and potential evacuation dynamics near shelters.  

To re-run any of the above, please refer to the different relevant sub-sections under [*Steps for Re-running*](https://github.com/EmilieAndreasen/cds-spatial-exam#technical-pipeline). For further information regarding the project or its reproducibility, contact the authors (see [*Authors*](https://github.com/EmilieAndreasen/cds-spatial-exam#authors)).
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
This code repository was made as a joint effort by Emilie Munch Andreasen ([@EmilieAndreasen](https://github.com/EmilieAndreasen)), Katrine Munkholm Hygebjerg-Hansen ([@KatrineMunkhholm](https://github.com/katrinemunkholm)), and Sabrina Schroll Zaki Hansen ([@Sabszh](https://github.com/sabszh)). 

### Contact us
For any questions regarding the reproducibility or project in general, you can contact us:
<ul style="list-style-type: none;">
  <li><a href="mailto:202106384@post.au.dk">EmilieAndreasen@post.au.dk</a>
(Emilie)</li>
    <li><a href="mailto:202106444@post.au.dk"> KatrineMunkgolm@post.au.dk</a>
(Katrine)</li>
    <li><a href="mailto:202105174@post.au.dk"> SabrinaZakiHansen@post.au.dk</a>
(Sabrina)</li>
</ul>
