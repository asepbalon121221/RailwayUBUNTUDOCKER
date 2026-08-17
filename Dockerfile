# XD VPS — Ubuntu 24.04 SSH + 9router
# Dev: KurrXd

FROM ubuntu:24.04

RUN userdel -r ubuntu 2>/dev/null || true

RUN sed -i 's/^Components: .*/Components: main restricted universe/' /etc/apt/sources.list.d/ubuntu.sources 2>/dev/null || true

RUN apt-get update \
    && apt-get install -y \
        ca-certificates gnupg apt-transport-https software-properties-common \
        openssh-server \
        curl wget \
        iproute2 iputils-ping net-tools dnsutils traceroute whois telnet nmap \
        vim nano micro \
        htop btop ncdu neofetch \
        tmux screen less tree bat ripgrep fd-find jq zsh \
        unzip zip tar gzip bzip2 xz-utils p7zip-full \
        git build-essential cmake pkg-config autoconf automake libtool gcc g++ \
        python3 python3-pip python3-venv python3-dev \
        rsync sqlite3 \
        locales ncurses-term language-pack-en language-pack-id \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && mkdir -p /run/sshd \
    && chmod 755 /run/sshd \
    && ssh-keygen -A \
    && echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config \
    && echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

RUN locale-gen en_US.UTF-8 id_ID.UTF-8

COPY xd-welcome.sh /etc/profile.d/xd-welcome.sh

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV TERM=xterm-256color

# Node.js current LTS + npm usable as root
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/bin/python3 /usr/local/bin/python \
    && ln -sf /usr/bin/pip3 /usr/local/bin/pip \
    && npm config set fund false \
    && npm config set audit false \
    && npm config set update-notifier false \
    && npm install -g npm@latest \
    && npm config set ignore-scripts false \
    && corepack enable \
    && npm install -g --allow-scripts=9router 9router

COPY static/favicon.svg static/favicon.ico /usr/local/share/xd/
RUN python3 -c "\
from pathlib import Path; import shutil, subprocess;\
root = Path(subprocess.check_output(['npm','root','-g'], text=True).strip()) / '9router';\
svg, ico = Path('/usr/local/share/xd/favicon.svg'), Path('/usr/local/share/xd/favicon.ico');\
n = 0;\
for p in root.rglob('*'):\
    if 'node_modules' in p.parts: continue;\
    if p.is_dir() and p.name == 'public':\
        shutil.copyfile(svg, p/'favicon.svg'); shutil.copyfile(ico, p/'favicon.ico'); n += 1;\
        icons = p/'icons';\
        if icons.is_dir():\
            shutil.copyfile(svg, icons/'icon-192.svg'); shutil.copyfile(svg, icons/'icon-512.svg');\
    elif p.is_file() and p.name == 'favicon.ico':\
        shutil.copyfile(ico, p); n += 1;\
    elif p.is_file() and p.name in ('favicon.svg','icon-192.svg','icon-512.svg'):\
        shutil.copyfile(svg, p); n += 1;\
print('xd favicon patched', n)\
"

COPY ssh-user-config.sh /usr/local/bin/ssh-user-config.sh
COPY usage /usr/local/bin/usage
COPY src-sync.sh /usr/local/bin/src-sync
COPY config.json /etc/xd/config.json
RUN sed -i 's/\r$//' /usr/local/bin/ssh-user-config.sh /usr/local/bin/usage /usr/local/bin/src-sync /etc/profile.d/xd-welcome.sh /etc/xd/config.json \
    && chmod +x /usr/local/bin/ssh-user-config.sh /usr/local/bin/usage /usr/local/bin/src-sync /etc/profile.d/xd-welcome.sh \
    && mkdir -p /root/src

EXPOSE 22 20128

CMD ["/usr/local/bin/ssh-user-config.sh"]
