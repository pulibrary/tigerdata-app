# How Chuck creates a project in aterm
This is a written summary of Chuck's video, which is available here: https://drive.google.com/file/d/1fYGNkVM9J94J1jUmZ7p0MZEUX2meLZav/view

## Steps
### 1. Create a namespace for the project
Within the tiger data namespace, create a namespace for this project:
```
asset.namespace.create :namespace /princeton/tigerdataNS/SIMONSOBSNS :store dell-ps-q
```

Questions: 
1. How do we know what store to give it?
2. Chuck copies the namespace id that mediaflux creates. Do we need to store that somewhere?

### 2. Create the collection for the project
```
ccd tigerdata # navigate to the tigerdata collection
asset.create :name SIMONSOBS \
  :namespace princeton/tigerdataNS/SIMONSOBSNS \
  :collection \
    -unique-name-index true \
    -cascade-contained-asset-index true \
    -contained-asset-index true \
    true \
 :owner < :domain princeton :user jdunkley > \
 :member-acl < \
  :actor -type user princeton:jdunkley \
  :access < \
    :asset ACCESS \
    :asset CREATE \
    :asset MODIFY \
    :asset DESTROY \
    :collection ACCESS \
    :collection EXECUTE \
    :collection CREATE \
    :collection MODIFY \
    :collection DESTROY \
    :asset-content ACCESS \
    :asset-content MODIFY \
    :asset-content EXECUTE \

    >>
```

Questions:
1. The rest of the above script is not visible on the video. Can we get the rest of it?
2. Chuck is recording the collection asset id into his spreadsheet. Do we need to record that anywhere? 
3. In Chuck's workflow, the "requested quota" and "allocated quota" are the same. But we want those to be two separate fields, right? Because we might now allocate everything they're requesting right away. 
4. Some projects (e.g., the Simons Observatory) have an ongoing request for storage that seems unending. Is that use case captured by our current data model of a single "requested quota" and "currently allocated" quota? 
5. In the video Chuck says "there is no DOI yet." When does that get created? When should it be created in our workflow? 
6. NOTE: The "owner" of the collection must be specified or it will default to root. This should be the data sponsor.
7. TICKET NEEDED: The example email from the Simons Observatory, there are multiple people named as Data Managers. However, our current UI only allows for one Data Manager. 