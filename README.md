<p align="center">
    <img src="images/Klar_Parat.png" alt="Logo" width="400" height="400">
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

This repository contains all the necessary components to run the Agent-Based Model (ABM) for evacuation in Aarhus along with  visualising traffic and movement data in Aarhus, the results of which are used to inform the [mock-up](https://www.figma.com/design/ZzUPYJiE9yhHM93OycdNY5/Spatial-Analytics%3A-Exam-application-design?node-id=0-1) of the “klar | parat” app.  

<p align="center">
    <img src="images/ABM_to_APP.png" alt="Logo">
  </p>


Key elements in this repository include:  
- **NetLogo Code/Model:** The core ABM evacuation model developed in NetLogo 6.4.0.  
- **Data (Shapefiles, CSVs):** Geographic data used within the NetLogo model, processed and formatted as shapefiles, and CSV files with traffic data.  
- **Python Preprocessing Scripts:** Script for preprocessing the initial raw data to generate the required shelter shapefile for the NetLogo model.  
- **Traffic Analysis and Plotting Scripts:** Python scripts for plotting traffic and evacuation shelter data in Aarhus, providing visual insights into traffic patterns near shelters.  

To re-run any of the above, please refer to the different relevant sub-sections under [*Steps for Re-running*](https://github.com/EmilieAndreasen/cds-spatial-exam#technical-pipeline). For further information regarding the project or its reproducibility, contact the authors (see [*Authors*](https://github.com/EmilieAndreasen/cds-spatial-exam#authors)).
<br>

## Project Structure 
The repository is structured as such:
| <div style="width:120px"></div>| Description |
|---------|:-----------|
| ```data``` | Folder with original un-processed raw data (see [data/README.md](https://github.com/EmilieAndreasen/cds-spatial-exam/main/data/README.md)).      |
| ```images```  | Folder with logo image and plots used in the paper. |
| ```netlogo```  | Folder with all relevant data and NetLogo model (see [netlogo/README.md](https://github.com/EmilieAndreasen/cds-spatial-exam/main/main/netlogo/README.md))          |
| ```scripts```  | Folder with Python scripts and notebook used for preprocessing data and plotting (see [script/README.md](https://github.com/EmilieAndreasen/cds-spatial-exam/main/script/README.md)).       |
| ```setup.sh```  | Run to create Python virtual environment ```env``` and install necessary requirements |

<br>

## Steps for Re-running
### Getting Started 
**1. Clone/Download and Prepare the Repository:**  
If the attachment has not already been cloned or downloaded and unzipped, then start by cloning or downloading the zip file and unzip it in your desired location. 

### Instructions (NetLogo Model)
**2. Prerequisites**
Ensure you have NetLogo 6.4.0 installed to run the model. Attempting to open or run the model with another version can result in functionalities being lost.  

**3. Setup and Run Model**
Below are the steps to follow for running the model to simulate evacuation in part of Aarhus.  
- 


### Instructions (Python Script)
**2. Set Up the Virtual Environment:**  
Execute the following command in your terminal to set up the Python virtual environment and install the needed dependencies.
```
bash setup.sh 
```

**3. Activate the Virtual Environment and Run the Code:** 
Activate the virtual environment and run the Script as needed. 
```
source env/bin/activate
python script
```
Open the python script in the scripts folder to preprocess the original raw shelters23.geojson data.


### Instructions (Python Notebook)
**2. Set Up the Virtual Environment:**  
Execute the following command in your terminal to set up the Python virtual environment and install the needed dependencies.
```
bash setup.sh 
```

**3. Activate the Virtual Environment and Run the Code:** 
Activate the virtual environment and run the Jupyter Notebook as needed. 
```
source env/bin/activate
jupyter notebook
```
Open the notebook file in the scripts folder to preprocess data and generate plot.


<br>

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE.md) file for details.

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
