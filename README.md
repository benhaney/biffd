# Biffd

Biffd listens for incoming emails and runs configured commands based on the emails' contents.

## Description

Biffd is a small perl script that implements a mock SMTP server and intends to be run inetd-style, typically using systemd socket-activation.

With the provided unit files, systemd listens on port 25 and spawns a short-lived instance of biffd for each incoming SMTP connection, then connects the network socket to biffd's stdio. Biffd accepts the email, unpacks any resources (body text, attachments, etc) into a sandboxed temporary directory, then runs any relevant tasks from its config file based on configured matching rules.
For example, biffd might be configured to watch for emails sent to a specific known email address and save any attached jpeg images.

## Dependencies

The `Email::MIME` perl packages is required, and can be installed via `cpan install Email::MIME`

## Getting Started

By default, biffd is expected to be installed to /opt/biffd/, but can be installed anywhere so long as you adjust the relevant paths.
Install the provided systemd unit files and adjust them to handle your install location, security preferences, and any directories your tasks need to access (by default, the unit files are very locked down and do not allow access to most of the system).

Working from within this cloned repo, the following commands will install biffd, but feel free to change them to better match your preferences.

```shell
mkdir /opt/biffd
cp biffd.pl /opt/biffd/
cp dist/biffd.example.conf /opt/biffd/biffd.conf
cp dist/systemd/* /etc/system/systemd/
systemctl daemon-reload
systemctl enable --now biffd.socket
```

## Why?

I originally made biffd to supply the posting backend for a small personal microblogging service that uses email subjects to submit posts.
To create a post, you send an email to a randomly generated email address with your post text in the subject line. Biffd matches the email based on the recipient address and writes the email subject (and image attachments) into the service's post-storage for later display.
