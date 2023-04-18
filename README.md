# md_api_client_sh
Command line client for [md_api_server](https://github.com/ZaubererMD/md_api_server) written in bash.

I developed this simple script to log measurements of sensors attached to a Raspberry Pi on my server.

## Dependencies
Install all dependencies:
```
sudo apt install sha256sum jq curl awk sed tr cut
```
Most of these will already be present on a normal linux installation.

## Setup
Setup the script by changing the URL and port at the top of the script to point to your instance of [md_api_server](https://github.com/ZaubererMD/md_api_server)
```sh
# replace with url and port of your own md_api_server instance
API_URL="http://localhost:3000"
```

## Usage
The script takes parameters in the form `-<KEY> <VALUE>`. A `method` parameter is always required.

For example, to call the `session/request_login_token` method run:
```sh
mdapi.sh -method session/request_login_token
```

Since the response of [md_api_server](https://github.com/ZaubererMD/md_api_server) is always JSON, you can parse it `jq`.

### Login
To simplify the login-procedure, this script comes with two additional routines.

If you want to login with a username and password run the script as follows:
```sh
mdapi.sh login <USERNAME> <PASSWORD>
```
The script will create a password-hash internally and call itself with the second additional routine: login_hashed.

The login_hashed routine is used by the login routine, but it can also be used if you want to pass in hashed passwords (recommended). It is called as follows:
```sh
mdapi.sh login_hashed <USERNAME> <PASWORD_HASH>
```
The script will then request a login-token via `session/request_login_token` and perform a call to `session/login` afterwards.

At the end, bot of the routines will output the response of the `session/login` call. Usually you will want to call another method with your newly acquired session, so you should extract the session-token for further communication with the API. This can be done using `jq` as follows:
```sh
mdapi.sh login_hashed <USERNAME> <PASSWORD_HASH> | jq -r '.data.session.token'
```

## TODO
- Add help option (-h)
- Add option to pass server URL and port 
