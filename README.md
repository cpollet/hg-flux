# hg-flux

Create a playground repo with
```
hg init

touch default
hg add default
hg commit -m"touch default"

hg branch stable
touch stable
hg add stable
hg commit -m"touch stable"

hg flux-open F1
touch F1
hg add F1
hg commit -m"touch F1"

hg flux-open F2
touch F2
hg add F2
hg commit -m"touch F2"

hg up default
```