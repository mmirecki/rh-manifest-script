# rh-manifest-script

The script will produce a new rh-manifest file for a distgit repo
and push a patch with the new file.

Run the script as:
  ./rh-backvendor-script.sh [distgit branch]

for example:
  ./rh-backvendor-script.sh origin/cnv-2.0-rhel-8

The script will use the projects file to find projects for which to update the rh-manifest file.
The file should look like:
```  
  <distgit project name> <upstream repo>
  ....
```
For example:
```
bridge-marker                    github.com/kubevirt/bridge-marker
kubemacpool                      github.com/K8sNetworkPlumbingWG/kubemacpool
```

The upstream repo is needed by the retrodep tool.

