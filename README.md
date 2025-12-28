# YourHealthFirstApp

## Branch 01 - Initial Folders and Angular Initialization Setup

### Branch Name: 01-Branch-Initial-Folders-Angular-SetUp
### Branch Purpose: Initial Folders and Angular Initialization Setup

```shell

git clone https://github.com/javakishore-veleti/YourHealthFirstApp

cd YourHealthFirstApp

##### STEP 01 START - Create folders for Python Flask and also Angular UI code #####

### Macbook USERS ONLY COMMANDS START
mkdir -p python_flask_back_office
mkdir -p angular_front_end

mkdir -p .github
mkdir -p .github/workflows
### Macbook USERS ONLY COMMANDS END

### WINDOWS USERS ONLY COMMANDS START
if not exist python_flask_back_office mkdir python_flask_back_office
if not exist angular_front_end        mkdir angular_front_end

if not exist .github                  mkdir .github
if not exist .github/workflows        mkdir .github/workflows
### WINDOWS USERS ONLY COMMANDS END

##### STEP 01 END #####

##### STEP 02 START - Initiate Angular Project Code #####

cd angular_front_end

ng new healthcare_plans_ui --routing --style=scss --ssr=false

# ? Do you want to create a 'zoneless' application without zone.js (Developer Preview)? (y/N) N
# ✔ Packages installed successfully.

cd healthcare_plans_ui

npm install bootstrap

npm start

### Open your browser and access http://localhost:4200/

##### STEP 02 END - Initiate Angular Project Code #####

```