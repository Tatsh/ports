# My MacPorts source

## How to use

1. Clone this repo to somewhere permanent.
2. In a terminal, go to the directory where you cloned this repository, and run `portindex`.
3. Edit `/opt/local/etc/macports/sources.conf` to contain the path where you cloned this repository before the line with `[default]`. Example:

   ```plain
   file:///Users/tatsh/tatsh-ports
   rsync://rsync.macports.org/macports/release/tarballs/ports.tar [default]
   ```

   Note the line is a `file://` URL and must be a complete path.
4. Now installing a port from this source should work. Try running `port search battery-stat` and you should see a result.
