
# SWM Capacity

Auslastung der Stadtwerke München Bäder, Saunen und Eislaufbahn automatisiert abrufen und in eine PostgreSQL Datenbank schreiben

## Installation

Das Ruby Script swmcapacity.rb kann entweder direkt ausgeführt werden oder in einem Container. Dafür gibt es zwei Installationsbeispiele. Eine PostgreSQL DB wird in beiden Fällen benötigt.

### PostgreSQL Datenbank vorbereiten (Debian)

```
sudo apt install postgresql postgresql-client

sudo -iu postgres

createuser --pwprompt swmcapacity    #from regular shell
createdb -O swmcapacity swmcapacity
```


### Debian bullseye

```
sudo apt install ruby ruby-json ruby-nokogiri ruby-pg

sudo useradd -r -s/bin/bash -m swmcapacity

sudo -iu swmcapacity

git clone https://github.com/SlashDashAndCash/swmcapacity.git
cd swmcapacity

ruby swmcapacity.rb

# Zeitgesteuert ausführen
sudo loginctl enable-linger swmcapacity
mkdir -p ~/.config/systemd/user
cp swmcapacity.service ~/.config/systemd/user/
cp swmcapacity.timer ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl enable --user swmcapacity.timer
systemctl start --user swmcapacity.timer
```


### Podman Container

```
sudo useradd -r -s/bin/bash -m swmcapacity

# Anmelden als User swmcapacity (sudo -iu swmcapacity funktioniert nicht)

git clone https://github.com/SlashDashAndCash/swmcapacity.git
cd swmcapacity

podman build -t swmcapacity:latest .
podman run -v /var/run/postgresql:/var/run/postgresql -it --rm --name swmcapacity swmcapacity:latest

# Zeitgesteuert ausführen
sudo loginctl enable-linger swmcapacity
mkdir -p ~/.config/systemd/user
cp container-swmcapacity.service ~/.config/systemd/user/
cp container-swmcapacity.timer ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl enable --user container-swmcapacity.timer
systemctl start --user container-swmcapacity.timer
```

# To-Do's

- Unterscheidung zwischen Bädern, Saunen und anderen organisationUnits abrufen und in die vordefinierte Spalte kind_of schreiben.

