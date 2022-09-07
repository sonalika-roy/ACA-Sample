docker pull sonalikaroy/containerapps:blue5

# change your registry name
docker tag sonalikaroy/containerapps:blue5 acalevelupdemoacr.azurecr.io/samples/blue5
docker push acalevelupdemoacr.azurecr.io/samples/blue5


docker pull sonalikaroy/containerapps:green
# change your registry name
docker tag sonalikaroy/containerapps:green acalevelupdemoacr.azurecr.io/samples/green
docker push acalevelupdemoacr.azurecr.io/samples/green

