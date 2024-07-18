# Mediaflux manual installation
Notes from first attempt at manual mediaflux installation by Francis Kayiwa, Robert-Anthony Lee-Faison, and Bess Sadler

### 1. Add the box to active directory
Ask Francis or Alicia how to do this. 
We had to re-name the machines to mflux-staging and mflux-ci to make the names short enough to fit into active directory (string length limit)

Note that our systems occasionally lose their bind to AD, and this is a known issue. Francis is working on a solution. The workaround right now is to go to AD, delete the object, re-add it, and re-run the ansible playbook.

### 2. We re-created the boxes to run on rocky linux
We have systemd files from research computing that configure mflux on Red Hat Enterprise. We believe that building this on rocky linux 9 should give us the ability to use these files.
Note that when we re-build these boxes we need to keep the mac address the same, otherwise the license keys won't work.

-- end of first meeting --


### 3. Francis registered a lib-mflux service acccount
This will be used to bind Mediaflux servers to active directory. 

Server names:
* mflux-staging
* mflux-ci

### 4. Install Java
Per notes from Robert Knight, Mediaflux production is running Java 1.8.0.412.b08, release 2.el8.  

`sudo dnf install java-1.8.0-openjdk`
