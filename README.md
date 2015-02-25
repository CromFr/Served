# Served

A web server for sharing files easily through HTTP


## Docker

#### Building image

```bash
docker build --tag=crom/served .
```

#### Start Served
```bash
# The path where to search served configuration file (`served.conf`)
SERVED_CFG=/etc/served

docker run \
    -v $SERVED_CFG:/etc/served \
    -v /srv/ftp:/srv/ftp \
    -p 8080:80 \
    crom/served
```


## Local build

You will need to install `dub` and `dmd`:

```bash
dub build --compiler=dmd
```


## Usage

```bash
served [opt] cfg|dir
  cfg  JSON file containing the served configuration
  dir  Directory to serve, using the default configuration
  opt  Optionnal arguments (not implemented)
       --port=PORT  Listen on given port
```