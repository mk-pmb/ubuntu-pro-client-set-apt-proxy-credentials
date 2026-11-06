
<!--#echo json="package.json" key="name" underline="=" -->
ubuntu-pro-client-set-apt-proxy-credentials
===========================================
<!--/#echo -->

<!--#echo json="package.json" key="description" -->
Configure apt to make the Ubuntu Pro client work behind a proxy.
<!--/#echo -->


Problem
-------

On Ubuntu focal, the Ubuntu Pro client (version 38ubuntu0~20.04)
fails to enable any Pro feature when you're behind an HTTP CONNECT proxy.

Reason: The `/usr/lib/apt/apt-helper download-file` command that it uses
determines the network protocol by whatever it connects to.
And the connection to the proxy is via unencrypted HTTP.

It does not understand that there will be a CONNECT tunnel inside that
HTTP connection, and an HTTPS connection inside that tunnel, and that the
actual login credentials will be sent only inside HTTPS.

Without that knowledge, it just sees that the HTTP connection is insecure,
and will not send credentials unless you explicitly tell it to do so:

```text
$ gethostip -d esm.ubuntu.com
185.125.190.75

$ sudo /usr/lib/apt/apt-helper download-file \
  https://esm.ubuntu.com/apps/ubuntu/pool/ /tmp/pool-test
Err:1 https://esm.ubuntu.com/apps/ubuntu/pool/
  401  Unauthorized [IP: 185.125.190.75 443]
W: https://esm.ubuntu.com/apps/ubuntu/pool/:
  /etc/apt/auth.conf.d/00ubuntu-pro-auth-override-esm-apps: Credentials for
  esm.ubuntu.com/apps/ubuntu/ match, but the protocol is not encrypted.
  Annotate with http:// to use.
E: Failed to fetch https://esm.ubuntu.com/apps/ubuntu/pool/  401  Unauthorized [IP: 185.125.190.75 443]
E: Download Failed
```

The Ubuntu Pro client creates (or overwrites) its temporary credentials file
when it starts, and deletes it right after, so patching that file won't help.



Workaround
----------

We can provide apt with a custom credentials file that has higher priority
than the temporary one.
This repo provides [a bash script](apt-pro-setauth.sh)
to create and update such a credentials file as
`/etc/apt/auth.conf.d/00ubuntu-pro-auth-override`.



Prerequisites
-------------

You need `jq` and `wdiff` installed.
Ubuntu has apt packages with those exact names.



Usage
-----

```text
$ sudo ./apt-pro-setauth.sh
$ sudo pro enable esm-apps # should now work
```



Security
--------

The diff report censors the tokens, but the file of course has them.
Don't share it. Delete it when you no longer need it.



Known issues
------------

* You may need to re-run the script whenever the Ubuntu Pro client
  rotates its tokens.
* Needs more/better tests and docs.





<!--#toc stop="scan" -->

&nbsp;


License
-------
<!--#echo json="package.json" key="license" -->
ISC
<!--/#echo -->
