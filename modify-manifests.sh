#!/bin/bash

# Add namespace to all resources and rename frontend-external service
sed -e '/^apiVersion:/i\
---' \
    -e '/^metadata:/a\
  namespace: online-shop' \
    -e 's/name: frontend-external/name: online-shop-frontend/' \
    online-shop-manifests.yaml > online-shop-namespaced.yaml

# Remove the first --- that was added before the first apiVersion
sed -i '1d' online-shop-namespaced.yaml

echo "Modified manifests created as online-shop-namespaced.yaml"
