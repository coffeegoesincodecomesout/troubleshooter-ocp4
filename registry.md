# registry


## list all images

> oc get pods -A -o jsonpath="{..image}" | tr -s '[[:space:]]' '\n' | sort | uniq